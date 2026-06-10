import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../l10n/strings.dart';
import '../../models/order_model.dart';
import '../../providers/theme_provider.dart';
import '../../providers/order_provider.dart';
import '../../services/api_service.dart';
import '../admin/order_detail_screen.dart';
import 'driver_settlements_screen.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});
  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  double _salaryPercent = 20;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
    _loadSalaryPercent();
  }

  Future<void> _loadSalaryPercent() async {
    try {
      final settings = await context.read<ApiService>().getSettings();
      final v = settings['worker_salary_percent'];
      if (v != null && mounted) setState(() => _salaryPercent = (v as num).toDouble());
    } catch (_) {}
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S(context.watch<ThemeProvider>().language);
    return Scaffold(
      appBar: AppBar(
        title: Text(s.financeReport),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.local_shipping_outlined),
            tooltip: s.driverSettlements,
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const DriverSettlementsScreen(),
            )),
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          tabs: [
            Tab(text: s.yearlyTab),
            Tab(text: s.monthlyTab),
            Tab(text: s.dailyTab),
            const Tab(text: 'Qarzlar'),
          ],
        ),
      ),
      body: Consumer<OrderProvider>(
        builder: (context, provider, _) => RefreshIndicator(
          onRefresh: () => provider.loadOrders(),
          child: TabBarView(
            controller: _tab,
            children: [
              _YearlyReport(provider: provider, salaryPercent: _salaryPercent),
              _MonthlyReport(provider: provider, salaryPercent: _salaryPercent),
              _DailyReport(provider: provider, salaryPercent: _salaryPercent),
              _DebtorsReport(provider: provider),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Yillik ───────────────────────────────────────────────────────────────────

class _YearlyReport extends StatefulWidget {
  final OrderProvider provider;
  final double salaryPercent;
  const _YearlyReport({required this.provider, required this.salaryPercent});
  @override
  State<_YearlyReport> createState() => _YearlyReportState();
}

class _YearlyReportState extends State<_YearlyReport> {
  int _year = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    final s = S(context.watch<ThemeProvider>().language);
    final fmt = NumberFormat('#,###');
    final orders = widget.provider.ordersForYear(_year);
    final paid = orders.where((o) => o.paymentStatus == PaymentStatus.tolangan);
    final unpaid = orders.where((o) => o.paymentStatus == PaymentStatus.tolanmagan || o.paymentStatus == PaymentStatus.qarz);
    final income = paid.fold(0.0, (sum, o) => sum + o.effectivePrice);
    final pending = unpaid.fold(0.0, (sum, o) => sum + o.effectivePrice);

    // Har oy uchun statistika
    final monthStats = List.generate(12, (i) {
      final m = i + 1;
      final mo = widget.provider.ordersForMonth(_year, m);
      final mi = widget.provider.incomeForMonth(_year, m);
      return (month: m, count: mo.length, income: mi);
    });

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Yil tanlagich
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => setState(() => _year--),
          ),
          Text('$_year',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _year >= DateTime.now().year
                ? null
                : () => setState(() => _year++),
          ),
        ]),
        const SizedBox(height: 8),

        // Yillik summary
        _SummaryGrid(
          s: s, fmt: fmt,
          orderCount: orders.length,
          paidCount: paid.length,
          income: income,
          pending: pending,
          expense: income * widget.salaryPercent / 100,
          salaryPercent: widget.salaryPercent,
        ),
        const SizedBox(height: 20),

        if (orders.isEmpty)
          Center(child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(s.noDataForYear)))
        else ...[
          // Oylar bo'yicha jadval
          Text(s.monthBreakdown,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ...monthStats
              .where((m) => m.count > 0)
              .map((m) => _MonthRow(
                    month: m.month,
                    year: _year,
                    count: m.count,
                    income: m.income,
                    fmt: fmt,
                  )),
        ],
      ],
    );
  }
}

class _MonthRow extends StatelessWidget {
  final int month, year, count;
  final double income;
  final NumberFormat fmt;
  const _MonthRow({
    required this.month, required this.year,
    required this.count, required this.income, required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = S(context.watch<ThemeProvider>().language);
    final monthName = s.monthsFull[month];
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text('$month',
              style: TextStyle(fontWeight: FontWeight.bold,
                  color: cs.primary, fontSize: 16)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(monthName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          Text('$count ta buyurtma',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        ])),
        Text("${fmt.format(income)} ${s.sum}",
            style: TextStyle(fontWeight: FontWeight.bold,
                color: Colors.green.shade700, fontSize: 14)),
      ]),
    );
  }
}

// ─── Oylik ────────────────────────────────────────────────────────────────────

class _MonthlyReport extends StatefulWidget {
  final OrderProvider provider;
  final double salaryPercent;
  const _MonthlyReport({required this.provider, required this.salaryPercent});
  @override
  State<_MonthlyReport> createState() => _MonthlyReportState();
}

class _MonthlyReportState extends State<_MonthlyReport> {
  DateTime _month = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final s = S(context.watch<ThemeProvider>().language);
    final orders = widget.provider.ordersForMonth(_month.year, _month.month);
    final paid = orders.where((o) => o.paymentStatus == PaymentStatus.tolangan);
    final unpaid = orders.where((o) => o.paymentStatus == PaymentStatus.tolanmagan || o.paymentStatus == PaymentStatus.qarz);
    final income = paid.fold(0.0, (sum, o) => sum + o.effectivePrice);
    final pending = unpaid.fold(0.0, (sum, o) => sum + o.effectivePrice);
    final fmt = NumberFormat('#,###');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Oy tanlagich
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => setState(() =>
                _month = DateTime(_month.year, _month.month - 1)),
          ),
          Text(
            '${s.monthsFull[_month.month]} ${_month.year}',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _month.year == DateTime.now().year &&
                    _month.month == DateTime.now().month
                ? null
                : () => setState(() =>
                    _month = DateTime(_month.year, _month.month + 1)),
          ),
        ]),
        const SizedBox(height: 8),
        _SummaryGrid(
          s: s, fmt: fmt,
          orderCount: orders.length,
          paidCount: paid.length,
          income: income,
          pending: pending,
          expense: income * widget.salaryPercent / 100,
          salaryPercent: widget.salaryPercent,
        ),
        const SizedBox(height: 16),
        Text(s.orderList,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (orders.isEmpty)
          Center(child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(s.noDataForMonth)))
        else
          ...orders.map((o) => _FinanceOrderTile(order: o)),
      ],
    );
  }
}

// ─── Kunlik ───────────────────────────────────────────────────────────────────

class _DailyReport extends StatefulWidget {
  final OrderProvider provider;
  final double salaryPercent;
  const _DailyReport({required this.provider, required this.salaryPercent});
  @override
  State<_DailyReport> createState() => _DailyReportState();
}

class _DailyReportState extends State<_DailyReport> {
  DateTime _day = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final s = S(context.watch<ThemeProvider>().language);
    final orders = widget.provider.ordersForDay(_day);
    final income = widget.provider.incomeForDay(_day);
    final fmt = NumberFormat('#,###');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Kun tanlagich
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => setState(
                () => _day = _day.subtract(const Duration(days: 1))),
          ),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _day,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (picked != null) setState(() => _day = picked);
            },
            child: Text(
              DateFormat('dd MMMM yyyy').format(_day),
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _day.day == DateTime.now().day &&
                    _day.month == DateTime.now().month &&
                    _day.year == DateTime.now().year
                ? null
                : () => setState(
                    () => _day = _day.add(const Duration(days: 1))),
          ),
        ]),
        const SizedBox(height: 8),
        _SummaryGrid(
          s: s, fmt: fmt,
          orderCount: orders.length,
          paidCount: orders.where((o) => o.paymentStatus == PaymentStatus.tolangan).length,
          income: income,
          pending: orders.where((o) => o.paymentStatus != PaymentStatus.tolangan).fold(0.0, (sum, o) => sum + o.effectivePrice),
          expense: income * widget.salaryPercent / 100,
          salaryPercent: widget.salaryPercent,
        ),
        const SizedBox(height: 16),
        Text(s.todayOrders,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (orders.isEmpty)
          Center(child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(s.noDataForDay)))
        else
          ...orders.map((o) => _FinanceOrderTile(order: o)),
      ],
    );
  }
}

// ─── Summary grid ─────────────────────────────────────────────────────────────

class _SummaryGrid extends StatelessWidget {
  final S s;
  final NumberFormat fmt;
  final int orderCount, paidCount;
  final double income, pending, expense, salaryPercent;

  const _SummaryGrid({
    required this.s,
    required this.fmt,
    required this.orderCount,
    required this.paidCount,
    required this.income,
    required this.pending,
    required this.expense,
    required this.salaryPercent,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final netProfit = income - expense;

    final items = [
      _GridItem(
        icon: Icons.receipt_long_outlined,
        color: cs.primary,
        title: s.orderCount,
        value: '$orderCount / $paidCount',
      ),
      _GridItem(
        icon: Icons.payments_outlined,
        color: Colors.green.shade600,
        title: s.totalIncome,
        value: "${fmt.format(income)} ${s.sum}",
      ),
      _GridItem(
        icon: Icons.account_balance_wallet_outlined,
        color: Colors.orange.shade700,
        title: "${s.expense} • ${salaryPercent.toStringAsFixed(0)}%",
        value: "${fmt.format(expense)} ${s.sum}",
      ),
      _GridItem(
        icon: Icons.hourglass_empty_outlined,
        color: Colors.red.shade400,
        title: s.pendingIncome,
        value: "${fmt.format(pending)} ${s.sum}",
      ),
      _GridItem(
        icon: Icons.trending_up_rounded,
        color: Colors.teal.shade600,
        title: s.netProfit,
        value: "${fmt.format(netProfit)} ${s.sum}",
      ),
    ];

    return Column(
      children: items.asMap().entries.map((e) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: _GridCard(item: e.value, highlight: e.key == items.length - 1),
      )).toList(),
    );
  }
}

class _GridItem {
  final IconData icon;
  final Color color;
  final String title, value;
  const _GridItem({required this.icon, required this.color, required this.title, required this.value});
}

class _GridCard extends StatelessWidget {
  final _GridItem item;
  final bool highlight;
  const _GridCard({required this.item, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: highlight ? item.color.withValues(alpha: 0.08) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, color: item.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.title,
                  style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(item.value,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: highlight ? 18 : 17,
                      color: highlight ? item.color : null,
                    )),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ─── Finance order tile ───────────────────────────────────────────────────────

class _FinanceOrderTile extends StatelessWidget {
  final OrderModel order;
  const _FinanceOrderTile({required this.order});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = S(context.watch<ThemeProvider>().language);
    final fmt = NumberFormat('#,###');
    final dateFmt = DateFormat('dd.MM.yyyy');
    final isPaid = order.paymentStatus == PaymentStatus.tolangan;
    final isDebt = order.paymentStatus == PaymentStatus.qarz;
    final priceColor = isPaid
        ? Colors.green.shade700
        : isDebt
            ? Colors.orange.shade700
            : cs.onSurfaceVariant;

    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                order.customerName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                order.phone,
                style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 2),
              Text(
                order.address,
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ]),
          ),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(
              "${fmt.format(order.effectivePrice)} ${s.sum}",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: priceColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              dateFmt.format(order.pickupDate),
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),
          ]),
        ]),
      ),
    );
  }
}

// ─── Qarzlar bo'limi ──────────────────────────────────────────────────────────

class _DebtorsReport extends StatelessWidget {
  final OrderProvider provider;
  const _DebtorsReport({required this.provider});

  @override
  Widget build(BuildContext context) {
    final s = S(context.watch<ThemeProvider>().language);
    final fmt = NumberFormat('#,###');
    final dateFmt = DateFormat('dd.MM.yyyy');
    final debts = provider.orders
        .where((o) => o.paymentStatus == PaymentStatus.qarz)
        .toList()
      ..sort((a, b) => b.deliveryDate.compareTo(a.deliveryDate));

    final total = debts.fold(0.0, (s, o) => s + o.effectivePrice);

    return Column(children: [
      if (debts.isNotEmpty)
        Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
          ),
          child: Row(children: [
            const Icon(Icons.credit_card_off, color: Colors.orange),
            const SizedBox(width: 10),
            Expanded(
              child: Text('Jami qarz: ${debts.length} ta buyurtma',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            Text('${fmt.format(total)} so\'m',
                style: const TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
          ]),
        ),
      Expanded(
        child: debts.isEmpty
            ? Center(
                child: Column(mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                  Icon(Icons.check_circle_outline,
                      size: 64, color: Colors.green.shade300),
                  const SizedBox(height: 12),
                  Text(s.noDebtors,
                      style: TextStyle(fontSize: 16, color: Colors.grey)),
                ]),
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                itemCount: debts.length,
                itemBuilder: (ctx, i) {
                  final order = debts[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => Navigator.of(ctx).push(MaterialPageRoute(
                        builder: (_) => OrderDetailScreen(order: order),
                      )),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        child: Row(children: [
                          Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.credit_card_off,
                                color: Colors.orange, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(order.customerName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15)),
                              const SizedBox(height: 2),
                              Text(order.phone,
                                  style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 13)),
                              Text(
                                  '${order.address}  •  ${dateFmt.format(order.deliveryDate)}',
                                  style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 12)),
                            ]),
                          ),
                          Text('${fmt.format(order.effectivePrice)} so\'m',
                              style: const TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15)),
                        ]),
                      ),
                    ),
                  );
                },
              ),
      ),
    ]);
  }
}
