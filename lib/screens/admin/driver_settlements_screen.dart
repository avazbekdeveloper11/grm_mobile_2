// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../l10n/strings.dart';
import '../../providers/theme_provider.dart';
import '../../services/api_service.dart';

class DriverSettlementsScreen extends StatefulWidget {
  const DriverSettlementsScreen({super.key});

  @override
  State<DriverSettlementsScreen> createState() =>
      _DriverSettlementsScreenState();
}

class _DriverSettlementsScreenState extends State<DriverSettlementsScreen> {
  bool _loading = true;
  List<_DriverBalance> _balances = [];
  final _fmt = NumberFormat('#,###');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final api = context.read<ApiService>();
      final data = await api.getDriverBalances();
      _balances = (data).map((d) => _DriverBalance.fromMap(d)).toList();
    } catch (e) {
      _snack('Xatolik: $e', error: true);
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final s = S(context.watch<ThemeProvider>().language);
    final totalBalance =
        _balances.fold(0.0, (s, d) => s + d.balance);
    final totalCollected =
        _balances.fold(0.0, (s, d) => s + d.totalCollected);
    final debtors = _balances.where((d) => d.balance > 0).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.driverSettlements),
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
                  // ─── Umumiy ko'rsatkich ──────────────────────────────
                  Row(children: [
                    Expanded(
                      child: _SummaryCard(
                        label: s.totalCollected,
                        value: '${_fmt.format(totalCollected)} so\'m',
                        icon: Icons.account_balance_wallet_outlined,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SummaryCard(
                        label: s.leftAtDriver,
                        value: '${_fmt.format(totalBalance)} so\'m',
                        icon: Icons.money_off_outlined,
                        color: totalBalance > 0 ? Colors.orange : Colors.green,
                      ),
                    ),
                  ]),

                  if (debtors > 0) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.orange.withValues(alpha: 0.4)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: Colors.orange, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          '$debtors ${s.hasMoney}',
                          style: const TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.w600),
                        ),
                      ]),
                    ),
                  ],

                  const SizedBox(height: 14),
                  const _SectionLabel('Haydovchilar'),
                  const SizedBox(height: 8),

                  // ─── Haydovchi kartalar ──────────────────────────────
                  ..._balances.map((d) => _DriverCard(
                        driver: d,
                        fmt: _fmt,
                        onSettle: () => _showSettleDialog(d),
                        onHistory: () => _openHistory(d),
                      )),

                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Future<void> _showSettleDialog(_DriverBalance driver) async {
    final s = S(context.read<ThemeProvider>().language);
    if (driver.balance <= 0) {
      _snack('${driver.name}${s.noDebt}', error: false);
      return;
    }

    final amountCtrl =
        TextEditingController(text: driver.balance.toStringAsFixed(0));
    final noteCtrl = TextEditingController();

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // Header
          Row(children: [
            CircleAvatar(
              backgroundColor: Colors.green,
              child: Text(driver.name[0],
                  style: const TextStyle(color: Colors.white,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(driver.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text('${s.remainingColon} ${_fmt.format(driver.balance)} so\'m',
                  style: const TextStyle(color: Colors.orange, fontSize: 13)),
            ])),
          ]),
          const SizedBox(height: 20),

          // Amount
          TextFormField(
            controller: amountCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: s.receivedAmount,
              prefixIcon: const Icon(Icons.payments_outlined),
              suffixText: 'so\'m',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
            ),
          ),
          const SizedBox(height: 12),

          // Note
          TextFormField(
            controller: noteCtrl,
            decoration: InputDecoration(
              labelText: '${s.notes} (${s.optional})',
              prefixIcon: const Icon(Icons.notes_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
            ),
          ),
          const SizedBox(height: 20),

          FilledButton.icon(
            icon: const Icon(Icons.check),
            label: Text(s.confirmReceived),
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.green,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(s.cancel)),
        ]),
      ),
    );

    if (confirmed == true && mounted) {
      final amount = double.tryParse(amountCtrl.text.trim());
      if (amount == null || amount <= 0) {
        _snack('Summa kiriting', error: true);
        return;
      }
      try {
        final api = context.read<ApiService>();
        await api.addSettlement(driver.id, amount,
            note: noteCtrl.text.trim());
        _snack('✓ ${_fmt.format(amount)} so\'m qabul qilindi');
        _load();
      } catch (e) {
        _snack('Xatolik: $e', error: true);
      }
    }
  }

  void _openHistory(_DriverBalance driver) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => DriverHistoryScreen(
          driverId: driver.id, driverName: driver.name),
    ));
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? Colors.red : Colors.green,
      behavior: SnackBarBehavior.floating,
    ));
  }
}

// ─── Driver card ───────────────────────────────────────────────────────────────

class _DriverCard extends StatelessWidget {
  final _DriverBalance driver;
  final NumberFormat fmt;
  final VoidCallback onSettle;
  final VoidCallback onHistory;

  const _DriverCard({
    required this.driver,
    required this.fmt,
    required this.onSettle,
    required this.onHistory,
  });

  @override
  Widget build(BuildContext context) {
    final s = S(context.watch<ThemeProvider>().language);
    final hasDebt = driver.balance > 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: hasDebt
              ? Colors.orange.withValues(alpha: 0.5)
              : Colors.green.withValues(alpha: 0.3),
          width: hasDebt ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header
          Row(children: [
            CircleAvatar(
              backgroundColor:
                  hasDebt ? Colors.orange : Colors.green,
              child: Text(driver.name[0],
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(driver.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15)),
            ),
            // Debt badge
            if (hasDebt)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.5)),
                ),
                child: Text(s.debtor,
                    style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
              )
            else
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(s.settled,
                    style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
              ),
          ]),

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // 3 ko'rsatkich
          Row(children: [
            _Stat(
              label: s.totalCollected,
              value: '${fmt.format(driver.totalCollected)} so\'m',
              color: Colors.blue,
            ),
            const SizedBox(width: 8),
            _Stat(
              label: s.topshirildi,
              value: '${fmt.format(driver.totalSettled)} so\'m',
              color: Colors.green,
            ),
            const SizedBox(width: 8),
            _Stat(
              label: s.leftDebt,
              value: '${fmt.format(driver.balance)} so\'m',
              color: hasDebt ? Colors.orange : Colors.grey,
              bold: hasDebt,
            ),
          ]),

          if (driver.lastSettlement != null) ...[
            const SizedBox(height: 8),
            Text(
              'Oxirgi topshirish: ${_formatDate(driver.lastSettlement!)}',
              style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],

          const SizedBox(height: 12),

          // Buttons
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.history, size: 16),
                label: Text(s.history),
                onPressed: onHistory,
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  minimumSize: const Size(0, 40),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                icon: const Icon(Icons.payments, size: 16),
                label: Text(s.iReceived),
                onPressed: hasDebt ? onSettle : null,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  minimumSize: const Size(0, 40),
                ),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      return DateFormat('dd.MM.yyyy HH:mm').format(DateTime.parse(iso).toLocal());
    } catch (_) {
      return iso;
    }
  }
}

class _Stat extends StatelessWidget {
  final String label, value;
  final Color color;
  final bool bold;
  const _Stat({required this.label, required this.value,
      required this.color, this.bold = false});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: bold ? FontWeight.bold : FontWeight.w600,
                    color: color)),
          ),
        ]),
      );
}

// ─── History screen ────────────────────────────────────────────────────────────

class DriverHistoryScreen extends StatefulWidget {
  final String driverId, driverName;
  const DriverHistoryScreen(
      {super.key, required this.driverId, required this.driverName});

  @override
  State<DriverHistoryScreen> createState() => _DriverHistoryScreenState();
}

class _DriverHistoryScreenState extends State<DriverHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  bool _loading = true;
  List<_CollectedOrder> _collectedOrders = [];
  List<_CollectedOrder> _advanceOrders = [];
  List<_SettleRow> _settlements = [];
  double _balance = 0;
  final _fmt = NumberFormat('#,###');

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final api = context.read<ApiService>();
      final data = await api.getDriverHistory(widget.driverId);
      _collectedOrders = (data['collectedOrders'] as List)
          .map((d) => _CollectedOrder.fromMap(d))
          .toList();
      _advanceOrders = (data['advanceOrders'] as List? ?? [])
          .map((d) => _CollectedOrder.fromAdvanceMap(d))
          .toList();
      _settlements = (data['settlements'] as List)
          .map((s) => _SettleRow.fromMap(s))
          .toList();
      _balance = (data['balance'] as num).toDouble();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Xatolik: $e'), backgroundColor: Colors.red));
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final s = S(context.watch<ThemeProvider>().language);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.driverName),
        centerTitle: true,
        bottom: TabBar(
          controller: _tab,
          tabs: [
            Tab(text: s.totalCollected),
            Tab(text: s.topshirildi),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(children: [
              // Balance strip
              Container(
                margin: const EdgeInsets.all(14),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _balance > 0
                      ? Colors.orange.withValues(alpha: 0.1)
                      : Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _balance > 0
                        ? Colors.orange.withValues(alpha: 0.4)
                        : Colors.green.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(children: [
                  Icon(
                    _balance > 0 ? Icons.warning_amber_rounded : Icons.check_circle,
                    color: _balance > 0 ? Colors.orange : Colors.green,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _balance > 0
                          ? s.notSettledYet
                          : s.alreadySettled,
                      style: TextStyle(
                        color: _balance > 0 ? Colors.orange : Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '${_fmt.format(_balance)} so\'m',
                        style: TextStyle(
                          color: _balance > 0 ? Colors.orange : Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ]),
              ),

              Expanded(
                child: TabBarView(
                  controller: _tab,
                  children: [
                    // Yig'ilgan — har bir zakaz alohida
                    (_collectedOrders.isEmpty && _advanceOrders.isEmpty)
                        ? _empty(s.noMoneyYet)
                        : ListView(
                            padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
                            children: [
                              // To'liq to'langan zakazlar
                              if (_collectedOrders.isNotEmpty) ...[
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Text("To'langan zakazlar",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: cs.primary)),
                                ),
                                ..._collectedOrders.map((o) => Card(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      child: ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: Colors.blue,
                                          child: Text('#${o.id}',
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold)),
                                        ),
                                        title: Text(o.customerName,
                                            style: const TextStyle(fontWeight: FontWeight.w600)),
                                        subtitle: Text(o.dateFormatted),
                                        trailing: Text(
                                          '${_fmt.format(o.collectedAmount)} so\'m',
                                          style: const TextStyle(
                                              color: Colors.blue,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    )),
                              ],
                              // Avans to'lovlar
                              if (_advanceOrders.isNotEmpty) ...[
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Text("Avans to'lovlar",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange)),
                                ),
                                ..._advanceOrders.map((o) => Card(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      child: ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: Colors.orange,
                                          child: Text('#${o.id}',
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold)),
                                        ),
                                        title: Text(o.customerName,
                                            style: const TextStyle(fontWeight: FontWeight.w600)),
                                        subtitle: Text(o.dateFormatted),
                                        trailing: Text(
                                          '${_fmt.format(o.advancePayment)} so\'m',
                                          style: const TextStyle(
                                              color: Colors.orange,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    )),
                              ],
                            ],
                          ),

                    // Topshirilgan
                    _settlements.isEmpty
                        ? _empty(s.noSettlementsYet)
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
                            itemCount: _settlements.length,
                            itemBuilder: (_, i) {
                              final s = _settlements[i];
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 4),
                                leading: const CircleAvatar(
                                  backgroundColor: Colors.green,
                                  child: Icon(Icons.check,
                                      color: Colors.white, size: 18),
                                ),
                                title: Text(
                                  '${_fmt.format(s.amount)} so\'m',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15),
                                ),
                                subtitle: Text(
                                  '${s.dateFormatted}${s.note != null ? '  •  ${s.note}' : ''}',
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.red, size: 20),
                                  tooltip: 'O\'chirish',
                                  onPressed: () => _deleteSettle(s),
                                ),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                tileColor: cs.surface,
                              );
                            },
                          ),
                  ],
                ),
              ),
            ]),
    );
  }

  Widget _empty(String msg) => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.inbox_outlined, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(msg,
              style:
                  TextStyle(color: Colors.grey.shade500, fontSize: 15)),
        ]),
      );

  Future<void> _deleteSettle(_SettleRow sr) async {
    final s2 = S(context.read<ThemeProvider>().language);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(s2.deleteConfirm),
        content: Text(
            s2.deleteRecordMsg(_fmt.format(sr.amount))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(s2.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s2.delete),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      try {
        await context.read<ApiService>().deleteSettlement(sr.id);
        _load();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Xatolik: $e'), backgroundColor: Colors.red));
        }
      }
    }
  }
}

// ─── Helper widgets ────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _SummaryCard(
      {required this.label, required this.value,
       required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value,
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: color, fontSize: 14)),
            ),
          ]),
        ),
      );
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
          fontSize: 14));
}

// ─── Data models ───────────────────────────────────────────────────────────────

class _DriverBalance {
  final String id, name;
  final double totalCollected, totalSettled, balance;
  final int collectedCount;
  final String? lastSettlement;

  const _DriverBalance({
    required this.id, required this.name,
    required this.totalCollected, required this.totalSettled,
    required this.balance, required this.collectedCount,
    this.lastSettlement,
  });

  factory _DriverBalance.fromMap(Map m) => _DriverBalance(
    id: m['id'].toString(),
    name: m['name'] ?? '',
    totalCollected: (m['total_collected'] as num?)?.toDouble() ?? 0,
    totalSettled: (m['total_settled'] as num?)?.toDouble() ?? 0,
    balance: (m['balance'] as num?)?.toDouble() ?? 0,
    collectedCount: m['collected_count'] as int? ?? 0,
    lastSettlement: m['last_settlement'],
  );
}

class _CollectedOrder {
  final int id;
  final String customerName;
  final String? collectedAt;
  final double collectedAmount;
  final double advancePayment;

  const _CollectedOrder({
    required this.id,
    required this.customerName,
    this.collectedAt,
    required this.collectedAmount,
    required this.advancePayment,
  });

  factory _CollectedOrder.fromMap(Map m) => _CollectedOrder(
    id: m['id'] as int? ?? 0,
    customerName: m['customer_name'] ?? '',
    collectedAt: m['collected_at'],
    collectedAmount: (m['collected_amount'] as num?)?.toDouble() ?? 0,
    advancePayment: (m['advance_payment'] as num?)?.toDouble() ?? 0,
  );

  factory _CollectedOrder.fromAdvanceMap(Map m) => _CollectedOrder(
    id: m['id'] as int? ?? 0,
    customerName: m['customer_name'] ?? '',
    collectedAt: m['advance_payment_at'],
    collectedAmount: 0,
    advancePayment: (m['advance_payment'] as num?)?.toDouble() ?? 0,
  );

  String get dateFormatted {
    try {
      return DateFormat('dd.MM.yyyy HH:mm').format(DateTime.parse(collectedAt!).toLocal());
    } catch (_) {
      return collectedAt ?? '';
    }
  }
}

class _SettleRow {
  final String id;
  final double amount;
  final String? note, adminName, createdAt;

  const _SettleRow({required this.id, required this.amount,
      this.note, this.adminName, this.createdAt});

  factory _SettleRow.fromMap(Map m) => _SettleRow(
    id: m['id'].toString(),
    amount: (m['amount'] as num?)?.toDouble() ?? 0,
    note: m['note'],
    adminName: m['admin_name'],
    createdAt: m['created_at'],
  );

  String get dateFormatted {
    try {
      return DateFormat('dd.MM.yyyy HH:mm')
          .format(DateTime.parse(createdAt!).toLocal());
    } catch (_) {
      return createdAt ?? '';
    }
  }
}
