import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/strings.dart';
import '../../models/order_model.dart';
import '../../models/service_model.dart';
import '../../providers/order_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/api_service.dart';

class WorkerStatsScreen extends StatefulWidget {
  final String workerId;
  final String name;

  const WorkerStatsScreen({
    super.key,
    required this.workerId,
    required this.name,
  });

  @override
  State<WorkerStatsScreen> createState() => _WorkerStatsScreenState();
}

class _WorkerStatsScreenState extends State<WorkerStatsScreen> {
  final Map<String, List<OrderItemModel>> _items = {};
  bool _loading = true;
  double _salaryPercent = 20;
  List<({DateTime date, double percent})> _salaryHistory = [];

  OrderProvider? _orderProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAll());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.read<OrderProvider>();
    if (_orderProvider != provider) {
      _orderProvider?.removeListener(_onOrdersChanged);
      _orderProvider = provider;
      _orderProvider!.addListener(_onOrdersChanged);
    }
  }

  @override
  void dispose() {
    _orderProvider?.removeListener(_onOrdersChanged);
    super.dispose();
  }

  void _onOrdersChanged() {
    // Orders o'zgarganda items qayta yuklanadi
    _loadItems(context.read<ApiService>());
  }

  Future<void> _loadAll() async {
    final api = context.read<ApiService>();
    await Future.wait([
      _loadItems(api),
      _loadSalaryPercent(api),
      _loadSalaryHistory(api),
    ]);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadItems(ApiService api) async {
    try {
      final result = await api.getWorkerOrderItems(widget.workerId);
      _items.clear();
      for (final entry in result.entries) {
        _items[entry.key] = entry.value
            .map((e) => OrderItemModel.fromMap(e as Map<String, dynamic>))
            .toList();
      }
      if (mounted) setState(() {});
    } catch (_) {}
  }

  Future<void> _loadSalaryPercent(ApiService api) async {
    try {
      final settings = await api.getSettings();
      final v = settings['worker_salary_percent'];
      if (v != null) _salaryPercent = (v as num).toDouble();
    } catch (_) {}
  }

  Future<void> _loadSalaryHistory(ApiService api) async {
    try {
      final rows = await api.getSalaryPercentHistory();
      _salaryHistory = rows
          .map(
            (r) => (
              date: DateTime.parse(r['effective_from'] as String),
              percent: (r['percent'] as num).toDouble(),
            ),
          )
          .toList();
    } catch (_) {}
  }

  // Berilgan kun uchun aktiv foizni qaytaradi
  double _percentForDay(DateTime day) {
    if (_salaryHistory.isEmpty) return _salaryPercent;
    // Eng oxirgi effective_from <= day bo'lgan qatorni topamiz
    double result = _salaryHistory.first.percent;
    for (final h in _salaryHistory) {
      if (!h.date.isAfter(day)) result = h.percent;
    }
    return result;
  }

  Future<void> _editSalaryPercent() async {
    final controller = TextEditingController(
      text: _salaryPercent.toStringAsFixed(0),
    );
    final s = S(context.read<ThemeProvider>().language);
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.salaryPercent),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            suffixText: '%',
            hintText: '20',
            border: const OutlineInputBorder(),
            labelText: s.salaryPercent,
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () {
              final v = double.tryParse(controller.text.trim());
              if (v != null && v >= 0 && v <= 100) Navigator.pop(ctx, v);
            },
            child: Text(s.save),
          ),
        ],
      ),
    );
    if (result != null && mounted) {
      setState(() => _salaryPercent = result);
      try {
        final api = context.read<ApiService>();
        await api.updateWorkerSalaryPercent(result);
        await _loadSalaryHistory(api);
        if (mounted) setState(() {});
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;

    final s = S(context.watch<ThemeProvider>().language);
    // Orders'ni provider'dan olish (til o'zgarganda yangilanadi)
    final orders = context.watch<OrderProvider>().ordersForWorker(
      widget.workerId,
    );

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterdayDate = today.subtract(const Duration(days: 1));

    String dayLabel(DateTime d) {
      if (d == today) return s.todayClean;
      if (d == yesterdayDate) return s.yesterday;
      return '${d.day} ${s.monthsShort[d.month]}, ${d.year}';
    }

    final Map<DateTime, List<OrderModel>> byDay = {};
    for (final o in orders) {
      // Ishchining kunlik ishi worker'ga tayinlangan kuni bo'yicha hisoblanadi.
      // Agar tayinlangan sana bo'lmasa, yuvish boshlangan yoki yaratilgan kun.
      final ref =
          (o.assignedWorkerAt ??
                  o.washingStartedAt ??
                  o.washedAt ??
                  o.createdAt)
              .toLocal();
      final d = DateTime(ref.year, ref.month, ref.day);
      byDay.putIfAbsent(d, () => []).add(o);
    }
    byDay.putIfAbsent(today, () => []);
    final days = byDay.keys.toList()..sort((a, b) => b.compareTo(a));

    Map<String, _ServiceAgg> calcAgg(List<OrderModel> list) {
      final agg = <String, _ServiceAgg>{};
      for (final o in list) {
        for (final item in (_items[o.id] ?? [])) {
          if (item.quantity <= 0) continue;
          final double qty;
          if (item.area != null) {
            qty = double.parse(item.area!.toStringAsFixed(2));
          } else if (item.unitType == UnitType.piece) {
            qty = item.quantity.roundToDouble();
          } else {
            qty = item.quantity;
          }
          agg.update(
            item.serviceName,
            (a) => _ServiceAgg(
              name: a.name,
              unitType: a.unitType,
              qty: a.qty + qty,
            ),
            ifAbsent: () => _ServiceAgg(
              name: item.serviceName,
              unitType: item.unitType,
              qty: qty,
            ),
          );
        }
      }
      return agg;
    }

    double calcRevenue(List<OrderModel> list) {
      double total = 0;
      for (final o in list) {
        for (final item in (_items[o.id] ?? [])) {
          final double qty;
          if (item.unitType == UnitType.piece) {
            qty = item.quantity.roundToDouble();
          } else {
            final raw = item.area ?? item.quantity;
            qty = double.parse(raw.toStringAsFixed(1));
          }
          total += qty * item.unitPrice;
        }
      }
      return total;
    }

    final initials = widget.name
        .trim()
        .split(' ')
        .take(2)
        .map((p) => p.isNotEmpty ? p[0].toUpperCase() : '')
        .join();

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : const Color(0xFFF0F4FF),
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.cardLight,
        foregroundColor: isDark ? Colors.white : const Color(0xFF0A1628),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1976D2), Color(0xFF1565C0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${orders.length} ${s.orderCountSuffix}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFF6BAEFF) : AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: s.salaryPercent,
            icon: const Icon(Icons.tune_rounded, size: 22),
            onPressed: _editSalaryPercent,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : orders.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 64,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    s.noOrdersYet,
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                ...days.map((day) {
                  final dayOrders = byDay[day]!;
                  return _DayCard(
                    isDark: isDark,
                    label: dayLabel(day),
                    isToday: day == today,
                    orderCount: dayOrders.length,
                    agg: calcAgg(dayOrders),
                    dailyRevenue: calcRevenue(dayOrders),
                    salaryPercent: _percentForDay(day),
                    orders: dayOrders,
                    items: _items,
                  );
                }),
              ],
            ),
    );
  }
}

// ─── Model ────────────────────────────────────────────────────────────────

class _ServiceAgg {
  final String name;
  final UnitType unitType;
  final double qty;
  const _ServiceAgg({
    required this.name,
    required this.unitType,
    required this.qty,
  });

  String unitLabel(S s) {
    switch (unitType) {
      case UnitType.sqm:
        return s.sqm;
      case UnitType.meter:
        return s.meter;
      case UnitType.piece:
        return s.pieces2;
    }
  }

  String get qtyText => unitType == UnitType.piece
      ? qty.round().toString()
      : qty.toStringAsFixed(1);
}

String _fmtSom(double v, S s) {
  final intPart = v.truncate();
  final formatted = intPart.toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+$)'),
    (m) => '${m[1]} ',
  );
  return "$formatted ${s.sum}";
}

// ─── Kunlik karta ─────────────────────────────────────────────────────────

class _DayCard extends StatelessWidget {
  final bool isDark, isToday;
  final String label;
  final int orderCount;
  final Map<String, _ServiceAgg> agg;
  final double dailyRevenue;
  final double salaryPercent;
  final List<OrderModel> orders;
  final Map<String, List<OrderItemModel>> items;

  const _DayCard({
    required this.isDark,
    required this.isToday,
    required this.label,
    required this.orderCount,
    required this.agg,
    required this.dailyRevenue,
    required this.salaryPercent,
    required this.orders,
    required this.items,
  });

  void _showOrdersDialog(BuildContext context) {
    final lang = context.read<ThemeProvider>().language;
    final s = S(lang);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    // Jami m² hisoblash
    double totalSqm = 0;
    for (final o in orders) {
      for (final it in (items[o.id] ?? [])) {
        if (it.unitType == UnitType.sqm && it.area != null) {
          totalSqm += it.area!;
        }
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollCtrl) => Container(
          decoration: BoxDecoration(
            color: isDarkMode ? AppColors.cardDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.grey.shade700
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Container(
                margin: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isToday
                        ? [
                            AppColors.primary,
                            AppColors.primary.withValues(alpha: 0.8),
                          ]
                        : [
                            cs.primaryContainer,
                            cs.primaryContainer.withValues(alpha: 0.7),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: (isToday ? AppColors.primary : cs.primaryContainer)
                          .withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.calendar_today_rounded,
                        color: isToday ? Colors.white : cs.onPrimaryContainer,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                              color: isToday
                                  ? Colors.white
                                  : cs.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$orderCount ${s.orderCountSuffix}',
                            style: TextStyle(
                              fontSize: 13,
                              color:
                                  (isToday
                                          ? Colors.white
                                          : cs.onPrimaryContainer)
                                      .withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (totalSqm > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${totalSqm.toStringAsFixed(1)} m²',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: isToday
                                ? Colors.white
                                : cs.onPrimaryContainer,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Orders list
              Expanded(
                child: orders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 56,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              s.noOrdersYet,
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        controller: scrollCtrl,
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        itemCount: orders.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final o = orders[i];
                          final orderItems = items[o.id] ?? [];
                          final sqm = orderItems
                              .where((it) => it.unitType == UnitType.sqm)
                              .fold(0.0, (sum, it) => sum + (it.area ?? 0));

                          return Container(
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? AppColors.surfaceDark
                                  : const Color(0xFFF8FAFF),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isDarkMode
                                    ? AppColors.borderDark
                                    : const Color(0xFFE8EEF8),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Order number badge
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.blue.shade400,
                                          Colors.blue.shade600,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${o.id}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Order details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          o.customerName,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                            color: isDarkMode
                                                ? Colors.white
                                                : const Color(0xFF0A1628),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        if (orderItems.isEmpty)
                                          Text(
                                            s.noData,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey.shade500,
                                            ),
                                          )
                                        else
                                          Wrap(
                                            spacing: 6,
                                            runSpacing: 6,
                                            children: orderItems.map((it) {
                                              final val =
                                                  it.area?.toStringAsFixed(1) ??
                                                  it.quantity.toString();
                                              final unit =
                                                  it.unitType == UnitType.sqm
                                                  ? 'm²'
                                                  : it.unitType ==
                                                        UnitType.meter
                                                  ? 'm'
                                                  : s.pieces2;
                                              return Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: isDarkMode
                                                      ? Colors.blue.shade900
                                                            .withValues(
                                                              alpha: 0.3,
                                                            )
                                                      : Colors.blue.shade50,
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  '${it.serviceName}: $val $unit',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: isDarkMode
                                                        ? Colors.blue.shade200
                                                        : Colors.blue.shade700,
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                      ],
                                    ),
                                  ),
                                  // SQM badge
                                  if (sqm > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.green.shade200,
                                        ),
                                      ),
                                      child: Text(
                                        '${sqm.toStringAsFixed(1)} m²',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13,
                                          color: Colors.green.shade700,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print(
      'Building card for $label with $orderCount orders and ${agg.length} services',
    );
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => _showOrdersDialog(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isToday
                ? AppColors.primary.withValues(alpha: 0.35)
                : (isDark ? AppColors.borderDark : const Color(0xFFE8EEF8)),
            width: isToday ? 1.5 : 1,
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  if (isToday)
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 7),
                      decoration: const BoxDecoration(
                        color: Color(0xFF69FF85),
                        shape: BoxShape.circle,
                      ),
                    ),
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: isToday ? AppColors.primary : cs.onSurface,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isToday
                          ? AppColors.primary.withValues(
                              alpha: isDark ? 0.25 : 0.1,
                            )
                          : (isDark
                                ? AppColors.surfaceDark
                                : const Color(0xFFF0F4FF)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$orderCount ${S(context.watch<ThemeProvider>().language).pieces}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isToday
                            ? AppColors.primary
                            : cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              // Xizmatlar
              if (agg.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: agg.values
                      .map((a) => _Chip(agg: a, onDark: false))
                      .toList(),
                ),
              ] else if (orderCount == 0) ...[
                const SizedBox(height: 8),
                Text(
                  S(context.watch<ThemeProvider>().language).noOrdersYet,
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                ),
              ] else ...[
                const SizedBox(height: 8),
                Text(
                  S(context.watch<ThemeProvider>().language).noData2,
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                ),
              ],
              if (dailyRevenue > 0) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1B2A1B)
                        : const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF2E7D32).withValues(alpha: 0.4)
                          : const Color(0xFFA5D6A7),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.payments_rounded,
                        size: 14,
                        color: isDark
                            ? const Color(0xFF66BB6A)
                            : const Color(0xFF2E7D32),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${S(context.watch<ThemeProvider>().language).workerSalary}: ',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? const Color(0xFF81C784)
                              : const Color(0xFF388E3C),
                        ),
                      ),
                      Text(
                        _fmtSom(
                          dailyRevenue * salaryPercent / 100,
                          S(context.watch<ThemeProvider>().language),
                        ),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? const Color(0xFF66BB6A)
                              : const Color(0xFF1B5E20),
                        ),
                      ),
                      Text(
                        '  (${salaryPercent.toStringAsFixed(0)}%)',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? const Color(0xFF81C784).withValues(alpha: 0.6)
                              : const Color(0xFF81C784),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Chip ─────────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final _ServiceAgg agg;
  final bool onDark;
  const _Chip({required this.agg, required this.onDark});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final str = S(context.watch<ThemeProvider>().language);

    if (onDark) {
      return Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              agg.name,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 3),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: agg.qtyText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                  TextSpan(
                    text: ' ${agg.unitLabel(str)}',
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : const Color(0xFFF4F7FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFDDE4F5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            agg.name,
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 3),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: agg.qtyText,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                TextSpan(
                  text: ' ${agg.unitLabel(str)}',
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
