import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../l10n/strings.dart';
import '../../providers/theme_provider.dart';
import '../../services/api_service.dart';

class DriverCollectionsScreen extends StatefulWidget {
  const DriverCollectionsScreen({super.key});

  @override
  State<DriverCollectionsScreen> createState() => _DriverCollectionsScreenState();
}

class _DriverCollectionsScreenState extends State<DriverCollectionsScreen> {
  DateTime _date = DateTime.now();
  bool _loading = false;
  List<_DriverRow> _drivers = [];
  List<_UncollectedRow> _uncollected = [];
  double _totalToday = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final api = context.read<ApiService>();
      final dateStr = DateFormat('yyyy-MM-dd').format(_date);
      final data = await api.getDriverCollections(date: dateStr);

      final drivers = (data['drivers'] as List).map((d) => _DriverRow(
        id: d['id'].toString(),
        name: d['name'] ?? '',
        orderCount: d['order_count'] as int? ?? 0,
        totalCollected: (d['total_collected'] as num?)?.toDouble() ?? 0,
        collectedSum: (d['collected_sum'] as num?)?.toDouble() ?? 0,
        advanceSum: (d['advance_sum'] as num?)?.toDouble() ?? 0,
      )).toList();

      final uncollected = (data['uncollected'] as List).map((u) => _UncollectedRow(
        driverName: u['driver_name'] ?? '',
        customerName: u['customer_name'] ?? '',
        totalPrice: (u['total_price'] as num?)?.toDouble() ?? 0,
        orderId: u['id'].toString(),
      )).toList();

      setState(() {
        _drivers = drivers;
        _uncollected = uncollected;
        _totalToday = drivers.fold(0.0, (s, d) => s + d.totalCollected);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Xatolik: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _date = picked);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S(context.read<ThemeProvider>().language);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final fmt = NumberFormat('#,###');
    final dateFmt = DateFormat('dd MMMM yyyy');
    final isToday = DateFormat('yyyy-MM-dd').format(_date) ==
        DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Text(s.driversReportTitle),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(14),
                children: [

                  // ─── Sana tanlash ────────────────────────────────────
                  GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(children: [
                        Icon(Icons.calendar_today, color: cs.onPrimaryContainer, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            isToday ? "${s.todayPrefix}${dateFmt.format(_date)}" : dateFmt.format(_date),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: cs.onPrimaryContainer,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        Icon(Icons.arrow_drop_down, color: cs.onPrimaryContainer),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ─── Kunlik jami ─────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green.shade600, Colors.green.shade400],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(children: [
                      const Icon(Icons.account_balance_wallet, color: Colors.white, size: 28),
                      const SizedBox(width: 14),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(s.dailyTotalIncome,
                            style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        Text("${fmt.format(_totalToday)} ${s.sum}",
                            style: const TextStyle(
                                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
                      ]),
                    ]),
                  ),
                  const SizedBox(height: 16),

                  // ─── Haydovchilar ────────────────────────────────────
                  _SectionTitle("Haydovchilar yig'imi", Icons.local_shipping_outlined),
                  const SizedBox(height: 8),

                  ..._drivers.map((d) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: d.orderCount > 0
                            ? Colors.green.withValues(alpha: 0.4)
                            : cs.outlineVariant,
                      ),
                    ),
                    child: Row(children: [
                      CircleAvatar(
                        backgroundColor: d.orderCount > 0
                            ? Colors.green
                            : cs.surfaceContainerHighest,
                        child: Text(d.name[0],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: d.orderCount > 0 ? Colors.white : cs.onSurfaceVariant,
                            )),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(d.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        Text(d.orderCount > 0
                            ? "${d.orderCount} ta buyurtmadan to'lov"
                            : s.noPaymentToday,
                            style: TextStyle(
                                fontSize: 12,
                                color: d.orderCount > 0
                                    ? Colors.green.shade700
                                    : cs.onSurfaceVariant)),
                        if (d.advanceSum > 0)
                          Text("${s.advanceColon}${fmt.format(d.advanceSum)} ${s.sum}",
                              style: TextStyle(fontSize: 11, color: Colors.orange.shade700)),
                      ])),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text(
                          d.orderCount > 0
                              ? "${fmt.format(d.totalCollected)} ${s.sum}"
                              : "0 ${s.sum}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: d.orderCount > 0 ? Colors.green.shade700 : cs.onSurfaceVariant,
                          ),
                        ),
                        if (d.orderCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            margin: const EdgeInsets.only(top: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(s.collectedMark,
                                style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.bold)),
                          ),
                      ]),
                    ]),
                  )),

                  // ─── To'lanmagan buyurtmalar ─────────────────────────
                  if (_uncollected.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _SectionTitle(
                        "To'lanmagan buyurtmalar (${_uncollected.length} ta)",
                        Icons.warning_amber_outlined,
                        color: Colors.orange),
                    const SizedBox(height: 8),

                    ..._uncollected.map((u) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.withValues(alpha: 0.35)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.money_off, color: Colors.orange, size: 20),
                        const SizedBox(width: 10),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(u.customerName,
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text(u.driverName,
                              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                        ])),
                        Text(
                          u.totalPrice > 0 ? "${fmt.format(u.totalPrice)} ${s.sum}" : '—',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.orange),
                        ),
                      ]),
                    )),
                  ] else ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(width: 10),
                        Text(s.allOrdersPaid,
                            style: const TextStyle(
                                color: Colors.green, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ],

                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color? color;
  const _SectionTitle(this.text, this.icon, {this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return Row(children: [
      Icon(icon, size: 16, color: c),
      const SizedBox(width: 6),
      Text(text, style: TextStyle(
          fontWeight: FontWeight.bold, color: c, fontSize: 14)),
    ]);
  }
}

class _DriverRow {
  final String id, name;
  final int orderCount;
  final double totalCollected;
  final double collectedSum;
  final double advanceSum;
  const _DriverRow({required this.id, required this.name,
      required this.orderCount, required this.totalCollected,
      required this.collectedSum, required this.advanceSum});
}

class _UncollectedRow {
  final String driverName, customerName, orderId;
  final double totalPrice;
  const _UncollectedRow({required this.driverName, required this.customerName,
      required this.totalPrice, required this.orderId});
}
