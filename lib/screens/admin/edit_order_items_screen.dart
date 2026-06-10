// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../l10n/strings.dart';
import '../../models/order_model.dart';
import '../../models/service_model.dart';
import '../../providers/order_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/api_service.dart';
import '../../utils/order_number.dart';

class EditOrderItemsScreen extends StatefulWidget {
  final OrderModel order;
  const EditOrderItemsScreen({super.key, required this.order});

  @override
  State<EditOrderItemsScreen> createState() => _EditOrderItemsScreenState();
}

class _EditOrderItemsScreenState extends State<EditOrderItemsScreen> {
  List<ServiceModel> _services = [];
  final Map<String, _ServiceEntry> _entries = {};
  bool _loading = true;
  bool _saving = false;
  final _fmt = NumberFormat('#,###');

  // Discount
  bool _discountEnabled = false;
  double _discountMinSqm = 0;
  double _discountAmt = 0;
  double _discountPct = 0;
  double _discountStepSqm = 10;

  @override
  void initState() {
    super.initState();
    _loadServices();
    _loadDiscountSettings();
  }

  Future<void> _loadDiscountSettings() async {
    try {
      final settings = await context.read<ApiService>().getSettings();
      if (mounted) {
        setState(() {
          _discountEnabled =
              settings['discount_enabled'] == 1 || settings['discount_enabled'] == '1';
          _discountMinSqm = ((settings['discount_min_sqm'] ?? 0) as num).toDouble();
          _discountAmt = ((settings['discount_amount'] ?? 0) as num).toDouble();
          _discountPct = ((settings['discount_percentage'] ?? 0) as num).toDouble();
          _discountStepSqm = ((settings['discount_step_sqm'] ?? 10) as num).toDouble();
        });
      }
    } catch (_) {}
  }

  Future<void> _loadServices() async {
    setState(() => _loading = true);
    try {
      final api = context.read<ApiService>();
      final data = await api.getServices();
      _services = data
          .map((e) => ServiceModel.fromMap(e))
          .where((s) => s.isActive)
          .toList();

      // Pre-fill from existing order items
      try {
        final rawItems = await api.getOrderItems(widget.order.id);
        final items = rawItems.map((e) => OrderItemModel.fromMap(e)).toList();
        final Map<String, List<OrderItemModel>> grouped = {};
        for (final oi in items) {
          grouped.putIfAbsent(oi.serviceId, () => []).add(oi);
        }
        grouped.forEach((svcId, ois) {
          final svc = _services.firstWhere(
            (s) => s.id == svcId,
            orElse: () => _services.first,
          );
          final entry = _entries.putIfAbsent(
            svcId,
            () => _ServiceEntry(svc.unitType),
          );
          entry.enabled = true;
          if (svc.unitType == UnitType.sqm) {
            entry.pieces.clear();
            for (final oi in ois) {
              final p = _PieceMeasure();
              p.widthCtrl.text = oi.width?.toString() ?? '';
              p.heightCtrl.text = oi.height?.toString() ?? '';
              entry.pieces.add(p);
            }
            entry.countCtrl.text = ois.length.toString();
          } else {
            final total = ois.fold(0.0, (s, oi) => s + oi.quantity);
            entry.countCtrl.text = total.toInt().toString();
            if (svc.unitType == UnitType.meter && ois.isNotEmpty) {
              final notes = ois.first.notes ?? '';
              final match = RegExp(r'^(\d+)(ta|та)$').firstMatch(notes);
              if (match != null) entry.itemCountCtrl.text = match.group(1)!;
            }
          }
        });
      } catch (_) {}
    } catch (e) {
      if (mounted) _snack('Xatolik: $e', error: true);
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    for (final e in _entries.values) {
      e.dispose();
    }
    super.dispose();
  }

  _ServiceEntry _entry(ServiceModel s) =>
      _entries.putIfAbsent(s.id, () => _ServiceEntry(s.unitType));

  double get _totalSqm {
    double t = 0;
    for (final s in _services) {
      if (s.unitType != UnitType.sqm) continue;
      final e = _entries[s.id];
      if (e == null || !e.enabled) continue;
      t += e.pieces.fold(0.0, (sum, p) => sum + (p.area ?? 0));
    }
    return t;
  }

  double get _rawTotal {
    double t = 0;
    for (final s in _services) {
      final e = _entries[s.id];
      if (e == null || !e.enabled) continue;
      t += e.calcTotal(s.pricePerUnit);
    }
    return t;
  }

  double get _globalDiscount {
    if (!_discountEnabled || _discountMinSqm <= 0) return 0;
    if (_totalSqm < _discountMinSqm) return 0;
    if (_discountPct > 0 && _discountStepSqm > 0) {
      final steps = ((_totalSqm - _discountMinSqm) / _discountStepSqm).floor();
      final pct = (_discountPct * (1 << steps)).clamp(0.0, 100.0);
      return _rawTotal * pct / 100;
    }
    return _discountAmt;
  }

  double get _globalDiscountPct {
    if (!_discountEnabled || _discountMinSqm <= 0 || _discountPct <= 0) return 0;
    if (_totalSqm < _discountMinSqm) return 0;
    final steps = ((_totalSqm - _discountMinSqm) / _discountStepSqm).floor();
    return (_discountPct * (1 << steps)).clamp(0.0, 100.0);
  }

  double get _serviceDiscount {
    double t = 0;
    for (final svc in _services) {
      if (!svc.discountEnabled || svc.discountMinQty <= 0) continue;
      final e = _entries[svc.id];
      if (e == null || !e.enabled || !e.isValid) continue;
      final qty = e.qty(svc.unitType);
      if (qty >= svc.discountMinQty) {
        t += e.calcTotal(svc.pricePerUnit) * svc.discountAmount / 100;
      }
    }
    return t;
  }

  double get _discount => _globalDiscount + _serviceDiscount;
  double get _totalPrice => (_rawTotal - _discount).clamp(0, double.infinity);
  int get _filledCount =>
      _entries.values.where((e) => e.enabled && e.isValid).length;

  Future<void> _save() async {
    final s = S(context.read<ThemeProvider>().language);

    final validServices = _services.where((svc) {
      final e = _entries[svc.id];
      return e != null && e.enabled && e.isValid;
    }).toList();

    if (validServices.isEmpty) {
      _snack(s.atLeastOne, error: true);
      return;
    }

    setState(() => _saving = true);
    try {
      final api = context.read<ApiService>();
      final List<Map<String, dynamic>> items = [];

      for (final svc in validServices) {
        final e = _entries[svc.id]!;
        if (svc.unitType == UnitType.sqm) {
          for (final p in e.pieces) {
            if (!p.isValid) continue;
            items.add({
              'service_id': int.parse(svc.id),
              'width': double.parse(p.widthCtrl.text.replaceAll(',', '.')),
              'height': double.parse(p.heightCtrl.text.replaceAll(',', '.')),
            });
          }
        } else if (svc.unitType == UnitType.meter) {
          final pieceCount = int.tryParse(e.itemCountCtrl.text.trim()) ?? 0;
          items.add({
            'service_id': int.parse(svc.id),
            'quantity': double.parse(e.countCtrl.text.replaceAll(',', '.')),
            if (pieceCount > 0) 'notes': '${pieceCount}ta',
          });
        } else {
          items.add({
            'service_id': int.parse(svc.id),
            'quantity': int.parse(e.countCtrl.text.trim()),
          });
        }
      }

      await api.saveOrderItems(widget.order.id, items);

      // Status o'zgarganligi uchun orders ro'yxatini yangilash
      if (mounted) {
        await context.read<OrderProvider>().loadOrders();
      }

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${s.savedWithSum}${_fmt.format(_totalPrice)} so\'m'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) _snack('Xatolik: $e', error: true);
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final s = S(context.watch<ThemeProvider>().language);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalPrice = _totalPrice;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: cs.surfaceContainerLowest,
        title: Column(
          children: [
            const Text(
              'Buyurtma mahsulotlari',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              orderNumber(widget.order.id),
              style: TextStyle(
                fontSize: 12,
                color: cs.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
              itemCount: _services.length,
              itemBuilder: (ctx, i) {
                final svc = _services[i];
                final e = _entry(svc);
                return _ServiceCard(
                  service: svc,
                  entry: e,
                  fmt: _fmt,
                  isDark: isDark,
                  onChanged: () => setState(() {}),
                );
              },
            ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
          decoration: BoxDecoration(
            color: isDark ? cs.surfaceContainerHigh : Colors.white,
            border: Border(top: BorderSide(color: cs.outlineVariant)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (totalPrice > 0 || _rawTotal > 0) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade600, Colors.green.shade400],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$_filledCount ${s.serviceCountSuffix}',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 11),
                          ),
                          if (_discount > 0) ...[
                            Text(
                              '${s.subtotal}: ${_fmt.format(_rawTotal)} ${s.currency}',
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  decoration: TextDecoration.lineThrough,
                                  decorationColor: Colors.white70),
                            ),
                            Text(
                              _globalDiscountPct > 0
                                  ? '${s.discountApplied}: ${_globalDiscountPct.toStringAsFixed(0)}% (-${_fmt.format(_discount)} ${s.currency})'
                                  : '${s.discountApplied}: -${_fmt.format(_discount)} ${s.currency}',
                              style: const TextStyle(
                                  color: Colors.yellowAccent, fontSize: 12),
                            ),
                          ],
                          Text(
                            '${_fmt.format(totalPrice)} ${s.currency}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ],
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'Saqlash',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ─── Service card ──────────────────────────────────────────────────────────────

class _ServiceCard extends StatelessWidget {
  final ServiceModel service;
  final _ServiceEntry entry;
  final NumberFormat fmt;
  final bool isDark;
  final VoidCallback onChanged;

  const _ServiceCard({
    required this.service,
    required this.entry,
    required this.fmt,
    required this.isDark,
    required this.onChanged,
  });

  String _unitSuffix(UnitType t) {
    switch (t) {
      case UnitType.sqm:
        return 'm²';
      case UnitType.meter:
        return 'm';
      case UnitType.piece:
        return 'ta';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = S(context.watch<ThemeProvider>().language);
    final isSqm = service.unitType == UnitType.sqm;
    final isMeter = service.unitType == UnitType.meter;
    final valid = entry.enabled && entry.isValid;
    final currentQty = valid ? entry.qty(service.unitType) : 0.0;

    final hasDisc = service.discountEnabled && service.discountMinQty > 0;
    final discQualifies = hasDisc && currentQty >= service.discountMinQty;
    final discNearby = hasDisc && !discQualifies && currentQty > 0;
    final rawTotal = entry.enabled ? entry.calcTotal(service.pricePerUnit) : 0.0;
    final discAmt = discQualifies ? rawTotal * service.discountAmount / 100 : 0.0;
    final total = (rawTotal - discAmt).clamp(0.0, double.infinity);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: valid
            ? Colors.green.withValues(alpha: isDark ? 0.1 : 0.05)
            : (isDark ? cs.surfaceContainerHigh : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: valid
              ? Colors.green.withValues(alpha: 0.4)
              : cs.outlineVariant,
          width: valid ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Checkbox(
                  value: entry.enabled,
                  onChanged: (v) {
                    entry.enabled = v ?? false;
                    onChanged();
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  activeColor: cs.primary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        "${fmt.format(service.pricePerUnit)} ${s.sum}/${service.unitType.label}",
                        style: TextStyle(
                            fontSize: 12, color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                if (valid)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _UnitChip(service.unitType),
                      const SizedBox(height: 4),
                      if (discQualifies) ...[
                        Text(
                          "${fmt.format(rawTotal)} ${s.sum}",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.red,
                            decoration: TextDecoration.lineThrough,
                            decorationColor: Colors.red,
                          ),
                        ),
                        Text(
                          "${fmt.format(total)} ${s.sum}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ] else
                        Text(
                          "${fmt.format(total)} ${s.sum}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
              ],
            ),

            // Per-service discount banner
            if (hasDisc && entry.enabled) ...[
              const SizedBox(height: 8),
              if (discQualifies)
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade300),
                  ),
                  child: Row(children: [
                    const Icon(Icons.discount, size: 14, color: Colors.orange),
                    const SizedBox(width: 6),
                    Text(
                      'Skidka: -${service.discountAmount.toStringAsFixed(0)}% (-${fmt.format(discAmt)} so\'m)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade800,
                      ),
                    ),
                  ]),
                )
              else if (discNearby)
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: cs.outlineVariant),
                  ),
                  child: Row(children: [
                    Icon(Icons.discount_outlined,
                        size: 13, color: cs.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '≥ ${fmt.format(service.discountMinQty)} ${_unitSuffix(service.unitType)} bo\'lsa ${service.discountAmount.toStringAsFixed(0)}% skidka',
                        style: TextStyle(
                            fontSize: 11, color: cs.onSurfaceVariant),
                      ),
                    ),
                  ]),
                ),
            ],

            // Input section
            if (entry.enabled) ...[
              const SizedBox(height: 10),
              if (isSqm)
                _SqmInput(
                    entry: entry,
                    cs: cs,
                    isDark: isDark,
                    fmt: fmt,
                    onChanged: onChanged)
              else if (isMeter)
                _MeterInput(entry: entry, isDark: isDark, onChanged: onChanged)
              else
                _PieceInput(
                    entry: entry, cs: cs, isDark: isDark, onChanged: onChanged),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── sqm input ────────────────────────────────────────────────────────────────

class _SqmInput extends StatelessWidget {
  final _ServiceEntry entry;
  final ColorScheme cs;
  final bool isDark;
  final NumberFormat fmt;
  final VoidCallback onChanged;

  const _SqmInput({
    required this.entry,
    required this.cs,
    required this.isDark,
    required this.fmt,
    required this.onChanged,
  });

  void _updateCount(String val, VoidCallback refresh) {
    final n = int.tryParse(val.trim());
    if (n == null || n <= 0) {
      refresh();
      return;
    }
    final current = entry.pieces.length;
    if (n > current) {
      for (int i = current; i < n; i++) {
        entry.pieces.add(_PieceMeasure());
      }
    } else if (n < current) {
      for (int i = current; i > n; i--) {
        entry.pieces.removeLast().dispose();
      }
    }
    refresh();
  }

  @override
  Widget build(BuildContext context) {
    final s = S(context.watch<ThemeProvider>().language);
    final totalArea = entry.pieces.fold(0.0, (sum, p) => sum + (p.area ?? 0));
    final validPieces = entry.pieces.where((p) => p.isValid).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 130,
              child: _NumField(
                ctrl: entry.countCtrl,
                label: s.countLabel,
                suffix: 'ta',
                isDark: isDark,
                isInt: true,
                onChanged: (v) => _updateCount(v, onChanged),
              ),
            ),
            if (validPieces > 0) ...[
              const SizedBox(width: 12),
              Text(
                '${s.totalAreaLabel}${totalArea.toStringAsFixed(2)} m²',
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
        if (entry.pieces.isNotEmpty) ...[
          const SizedBox(height: 10),
          ...entry.pieces.asMap().entries.map((e) {
            return _PieceRow(
              index: e.key,
              piece: e.value,
              isDark: isDark,
              cs: cs,
              onChanged: onChanged,
            );
          }),
        ],
      ],
    );
  }
}

class _PieceRow extends StatelessWidget {
  final int index;
  final _PieceMeasure piece;
  final bool isDark;
  final ColorScheme cs;
  final VoidCallback onChanged;

  const _PieceRow({
    required this.index,
    required this.piece,
    required this.isDark,
    required this.cs,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final s = S(context.watch<ThemeProvider>().language);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: piece.isValid
            ? Colors.blue.withValues(alpha: isDark ? 0.1 : 0.06)
            : cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: piece.isValid
              ? Colors.blue.withValues(alpha: 0.3)
              : cs.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Text(
              '${index + 1}',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: cs.primary),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _NumField(
              ctrl: piece.widthCtrl,
              label: s.widthLabel,
              suffix: 'm',
              isDark: isDark,
              onChanged: (_) => onChanged(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text('×',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: cs.outline)),
          ),
          Expanded(
            child: _NumField(
              ctrl: piece.heightCtrl,
              label: s.heightLabel,
              suffix: 'm',
              isDark: isDark,
              onChanged: (_) => onChanged(),
            ),
          ),
          if (piece.isValid) ...[
            const SizedBox(width: 8),
            Text(
              '${piece.area!.toStringAsFixed(2)}m²',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── meter input ──────────────────────────────────────────────────────────────

class _MeterInput extends StatelessWidget {
  final _ServiceEntry entry;
  final bool isDark;
  final VoidCallback onChanged;

  const _MeterInput({
    required this.entry,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final s = S(context.watch<ThemeProvider>().language);
    final cs = Theme.of(context).colorScheme;
    final count = int.tryParse(entry.itemCountCtrl.text.trim()) ?? 0;
    final meters =
        double.tryParse(entry.countCtrl.text.replaceAll(',', '.').trim());
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: _NumField(
            ctrl: entry.itemCountCtrl,
            label: s.howManyCarpets,
            suffix: 'ta',
            isDark: isDark,
            isInt: true,
            onChanged: (_) => onChanged(),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 130,
          child: _NumField(
            ctrl: entry.countCtrl,
            label: s.lengthLabel,
            suffix: 'm',
            isDark: isDark,
            onChanged: (_) => onChanged(),
          ),
        ),
        if (count > 0 && meters != null && meters > 0) ...[
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$count ta · ${meters}m',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: cs.primary),
            ),
          ),
        ],
      ],
    );
  }
}

// ─── piece input ──────────────────────────────────────────────────────────────

class _PieceInput extends StatelessWidget {
  final _ServiceEntry entry;
  final ColorScheme cs;
  final bool isDark;
  final VoidCallback onChanged;

  const _PieceInput({
    required this.entry,
    required this.cs,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final s = S(context.watch<ThemeProvider>().language);
    return SizedBox(
      width: 130,
      child: _NumField(
        ctrl: entry.countCtrl,
        label: s.countLabel,
        suffix: 'ta',
        isDark: isDark,
        isInt: true,
        onChanged: (_) => onChanged(),
      ),
    );
  }
}

// ─── shared number field ──────────────────────────────────────────────────────

class _NumField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label, suffix;
  final bool isDark, isInt;
  final void Function(String) onChanged;

  const _NumField({
    required this.ctrl,
    required this.label,
    required this.suffix,
    required this.isDark,
    required this.onChanged,
    this.isInt = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TextField(
      controller: ctrl,
      keyboardType: isInt
          ? TextInputType.number
          : const TextInputType.numberWithOptions(decimal: true),
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        filled: true,
        fillColor: isDark ? cs.surfaceContainerHighest : const Color(0xFFF5F7FA),
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: cs.primary, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      ),
      onChanged: onChanged,
    );
  }
}

// ─── Unit chip ────────────────────────────────────────────────────────────────

class _UnitChip extends StatelessWidget {
  final UnitType unitType;
  const _UnitChip(this.unitType);

  @override
  Widget build(BuildContext context) {
    final Color color;
    switch (unitType) {
      case UnitType.sqm:
        color = Colors.blue;
        break;
      case UnitType.meter:
        color = Colors.teal;
        break;
      case UnitType.piece:
        color = Colors.purple;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        unitType.label,
        style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}

// ─── Data models ──────────────────────────────────────────────────────────────

class _PieceMeasure {
  final TextEditingController widthCtrl = TextEditingController();
  final TextEditingController heightCtrl = TextEditingController();

  double? _parse(String v) {
    final x = double.tryParse(v.replaceAll(',', '.').trim());
    return (x != null && x > 0) ? x : null;
  }

  bool get isValid =>
      _parse(widthCtrl.text) != null && _parse(heightCtrl.text) != null;

  double? get area {
    final w = _parse(widthCtrl.text);
    final h = _parse(heightCtrl.text);
    if (w == null || h == null) return null;
    return w * h;
  }

  void dispose() {
    widthCtrl.dispose();
    heightCtrl.dispose();
  }
}

class _ServiceEntry {
  final UnitType unitType;
  bool enabled = false;
  final TextEditingController countCtrl = TextEditingController();
  final TextEditingController sizeCtrl = TextEditingController();
  final TextEditingController itemCountCtrl = TextEditingController();
  final List<_PieceMeasure> pieces = [];

  _ServiceEntry(this.unitType);

  double? _parseDecimal(String v) {
    final x = double.tryParse(v.replaceAll(',', '.').trim());
    return (x != null && x > 0) ? x : null;
  }

  bool get isValid {
    if (!enabled) return false;
    switch (unitType) {
      case UnitType.sqm:
        return pieces.isNotEmpty && pieces.any((p) => p.isValid);
      case UnitType.meter:
        return _parseDecimal(countCtrl.text) != null &&
            (_parseDecimal(countCtrl.text) ?? 0) > 0;
      case UnitType.piece:
        final n = int.tryParse(countCtrl.text.trim()) ?? 0;
        return n > 0;
    }
  }

  double qty(UnitType t) {
    switch (t) {
      case UnitType.sqm:
        return pieces.fold(0.0, (s, p) => s + (p.area ?? 0));
      case UnitType.meter:
        return _parseDecimal(countCtrl.text) ?? 0;
      case UnitType.piece:
        return (int.tryParse(countCtrl.text.trim()) ?? 0).toDouble();
    }
  }

  double calcTotal(double pricePerUnit) {
    if (!isValid) return 0;
    return qty(unitType) * pricePerUnit;
  }

  void dispose() {
    countCtrl.dispose();
    sizeCtrl.dispose();
    itemCountCtrl.dispose();
    for (final p in pieces) {
      p.dispose();
    }
  }
}
