// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../l10n/strings.dart';
import '../../models/service_model.dart';
import '../../providers/theme_provider.dart';
import '../../services/api_service.dart';
import '../../utils/latin_to_cyrillic.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});
  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  List<ServiceModel> _services = [];
  bool _loading = true;
  final _fmt = NumberFormat('#,###');

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await context.read<ApiService>().getServices();
      _services = data.map((e) => ServiceModel.fromMap(e)).toList();
    } catch (e) {
      _snack('Xatolik: $e', error: true);
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final s = S(context.watch<ThemeProvider>().language);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.servicesTitle),
        centerTitle: true,
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(14),
                children: [
                  // ─── Info ───────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(children: [
                      Icon(Icons.info_outline, size: 16, color: cs.onPrimaryContainer),
                      const SizedBox(width: 8),
                      Expanded(child: Text(
                        s.itemsInfo,
                        style: TextStyle(fontSize: 12, color: cs.onPrimaryContainer),
                      )),
                    ]),
                  ),

                  // ─── Services list ───────────────────────────────────
                  ..._services.map((s) => _ServiceCard(
                    service: s,
                    fmt: _fmt,
                    onEdit: () => _showDialog(service: s),
                    onToggle: () => _toggle(s),
                  )),
                  const SizedBox(height: 80),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showDialog(),
        icon: const Icon(Icons.add),
        label: Text(s.addService),
      ),
    );
  }

  Future<void> _showDialog({ServiceModel? service}) async {
    final s = S(context.read<ThemeProvider>().language);
    final isCyr = context.read<ThemeProvider>().language == AppLanguage.uzCyrillic;
    final nameCtrl = TextEditingController(text: service?.name ?? '');
    final priceCtrl = TextEditingController(
        text: service != null ? service.pricePerUnit.toStringAsFixed(0) : '');
    final discMinCtrl = TextEditingController(
        text: service != null && service.discountMinQty > 0
            ? service.discountMinQty.toStringAsFixed(0) : '');
    final discAmtCtrl = TextEditingController(
        text: service != null && service.discountAmount > 0
            ? service.discountAmount.toStringAsFixed(1) : '');
    String unitType = service?.unitType.apiValue ?? 'sqm';
    bool discEnabled = service?.discountEnabled ?? false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 28,
          ),
          child: Column(mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch, children: [

            // Header
            Text(service == null ? s.newService : s.editService,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // Nom
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: s.serviceName,
                hintText: s.serviceNameHint,
                prefixIcon: const Icon(Icons.category_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
              ),
              textCapitalization: TextCapitalization.words,
              onChanged: isCyr
                  ? (val) {
                      final converted = latinToCyrillic(val);
                      if (converted != val) {
                        nameCtrl.value = TextEditingValue(
                          text: converted,
                          selection: TextSelection.collapsed(
                              offset: converted.length),
                        );
                      }
                    }
                  : null,
            ),
            const SizedBox(height: 12),

            // O'lchov turi
            Text(s.unitType, style: const TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'sqm',
                    icon: const Icon(Icons.square_foot, size: 16),
                    label: Text(s.sqmUnit)),
                ButtonSegment(value: 'meter',
                    icon: const Icon(Icons.straighten, size: 16),
                    label: Text(s.meterUnit)),
                ButtonSegment(value: 'piece',
                    icon: const Icon(Icons.numbers, size: 16),
                    label: Text(s.pieceUnit)),
              ],
              selected: {unitType},
              onSelectionChanged: (v) => setLocal(() => unitType = v.first),
            ),
            const SizedBox(height: 12),

            // Narx
            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: unitType == 'sqm' ? s.pricePerSqmUnit
                    : unitType == 'meter' ? s.pricePerMeter : s.pricePerPiece,
                prefixIcon: const Icon(Icons.payments_outlined),
                suffixText: unitType == 'sqm' ? s.sqmSuffix
                    : unitType == 'meter' ? s.meterSuffix : s.pieceSuffix,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
              ),
            ),
            const SizedBox(height: 20),

            // ── Skidka bo'limi ─────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: discEnabled
                    ? Colors.orange.withValues(alpha: 0.07)
                    : Theme.of(ctx).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: discEnabled
                      ? Colors.orange.shade300
                      : Theme.of(ctx).colorScheme.outlineVariant,
                ),
              ),
              child: Column(children: [
                // Toggle
                SwitchListTile(
                  value: discEnabled,
                  onChanged: (v) => setLocal(() => discEnabled = v),
                  title: Row(children: [
                    Icon(Icons.discount_outlined,
                        size: 18,
                        color: discEnabled
                            ? Colors.orange.shade700
                            : Theme.of(ctx).colorScheme.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Text(s.discountSettings,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: discEnabled
                                ? Colors.orange.shade700
                                : Theme.of(ctx).colorScheme.onSurfaceVariant)),
                  ]),
                  activeThumbColor: Colors.white,
                  activeTrackColor: Colors.orange.shade500,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),

                // Skidka maydonlari
                if (discEnabled) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: Column(children: [
                      // Izoh
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(children: [
                          Icon(Icons.info_outline,
                              size: 13, color: Colors.orange.shade700),
                          const SizedBox(width: 6),
                          Expanded(child: Text(
                            _discountHint(unitType, s),
                            style: TextStyle(
                                fontSize: 11, color: Colors.orange.shade800),
                          )),
                        ]),
                      ),
                      const SizedBox(height: 10),

                      Row(children: [
                        // Minimal miqdor
                        Expanded(child: TextField(
                          controller: discMinCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: InputDecoration(
                            labelText: s.discountMinSqm,
                            suffixText: _unitSuffix(unitType),
                            prefixIcon: const Icon(
                                Icons.production_quantity_limits, size: 18),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                            filled: true,
                            contentPadding: const EdgeInsets.all(10),
                          ),
                        )),
                        const SizedBox(width: 8),
                        // Skidka foizi
                        Expanded(child: TextField(
                          controller: discAmtCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Har birida skidka',
                            suffixText: '%',
                            prefixIcon: const Icon(
                                Icons.percent, size: 18),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                            filled: true,
                            contentPadding: const EdgeInsets.all(10),
                          ),
                        )),
                      ]),
                    ]),
                  ),
                ],
              ]),
            ),
            const SizedBox(height: 20),

            FilledButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final price = double.tryParse(priceCtrl.text.trim());
                if (name.isEmpty || price == null || price <= 0) {
                  _snack(s.enterValidData, error: true);
                  return;
                }
                final discMin = double.tryParse(
                    discMinCtrl.text.replaceAll(',', '.')) ?? 0;
                final discAmt = double.tryParse(
                    discAmtCtrl.text.replaceAll(',', '.')) ?? 0;
                Navigator.pop(ctx);
                try {
                  final api = context.read<ApiService>();
                  if (service == null) {
                    await api.createService(name, unitType, price,
                      discountEnabled: discEnabled,
                      discountMinQty: discMin,
                      discountAmount: discAmt,
                    );
                  } else {
                    await api.updateService(service.id, {
                      'name': name,
                      'unit_type': unitType,
                      'price_per_unit': price,
                      'discount_enabled': discEnabled,
                      'discount_min_qty': discMin,
                      'discount_amount': discAmt,
                    });
                  }
                  _snack(service == null ? s.serviceAdded : s.serviceUpdated);
                  _load();
                } catch (e) {
                  _snack('Xatolik: $e', error: true);
                }
              },
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(service == null ? s.add : s.save,
                  style: const TextStyle(fontSize: 15)),
            ),
          ]),
        ),
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      discMinCtrl.dispose();
      discAmtCtrl.dispose();
    });
  }

  String _discountHint(String unitType, S s) {
    switch (unitType) {
      case 'sqm':   return s.discountHintSqm;
      case 'meter': return s.discountHintMeter;
      default:      return s.discountHintPiece;
    }
  }

  String _unitSuffix(String unitType) {
    switch (unitType) {
      case 'sqm':   return 'm²';
      case 'meter': return 'm';
      default:      return 'ta';
    }
  }

  Future<void> _toggle(ServiceModel s) async {
    try {
      await context.read<ApiService>().updateService(s.id, {'is_active': !s.isActive});
      _load();
    } catch (e) {
      _snack('Xatolik: $e', error: true);
    }
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


class _ServiceCard extends StatelessWidget {
  final ServiceModel service;
  final NumberFormat fmt;
  final VoidCallback onEdit, onToggle;
  const _ServiceCard({required this.service, required this.fmt,
      required this.onEdit, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isActive = service.isActive;

    final hasDiscount = service.discountEnabled && service.discountMinQty > 0;
    final s = S(context.read<ThemeProvider>().language);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasDiscount
              ? Colors.orange.shade400
              : isActive ? cs.outlineVariant : Colors.grey.shade300,
          width: hasDiscount ? 1.5 : 1,
        ),
        color: hasDiscount
            ? Colors.orange.withValues(alpha: 0.04)
            : cs.surface,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(children: [
          // Icon
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: hasDiscount
                  ? Colors.orange.withValues(alpha: 0.15)
                  : isActive ? cs.primaryContainer : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              service.unitType == UnitType.sqm
                  ? Icons.square_foot
                  : service.unitType == UnitType.meter
                      ? Icons.straighten
                      : Icons.inventory_2_outlined,
              color: hasDiscount
                  ? Colors.orange.shade700
                  : isActive ? cs.primary : Colors.grey,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nom + unit badge
              Row(children: [
                Expanded(child: Text(
                  service.name,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: isActive ? null : Colors.grey),
                )),
                _UnitBadge(service.unitType),
              ]),
              const SizedBox(height: 3),

              // Narx
              Text(
                "${fmt.format(service.pricePerUnit)} ${s.currency}/${service.unitType.label}",
                style: TextStyle(
                    color: isActive ? cs.primary : Colors.grey,
                    fontWeight: FontWeight.w600,
                    fontSize: 13),
              ),
              const SizedBox(height: 6),

              // Skidka qatori — doim ko'rinadi
              if (hasDiscount)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade600,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.discount,
                        size: 11, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      'Har ${fmt.format(service.discountMinQty)} ${_unitLabel(service.unitType)} → ${service.discountAmount.toStringAsFixed(1)}% skidka',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ]),
                )
              else
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.discount_outlined,
                      size: 12, color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                  const SizedBox(width: 4),
                  Text(
                    s.discountSettings,
                    style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                  ),
                ]),
            ],
          )),
          const SizedBox(width: 8),

          // Actions
          Column(mainAxisSize: MainAxisSize.min, children: [
            GestureDetector(
              onTap: onEdit,
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.edit_outlined, size: 17, color: cs.onSurfaceVariant),
              ),
            ),
            const SizedBox(height: 6),
            Switch(
              value: isActive,
              onChanged: (_) => onToggle(),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ]),
        ]),
      ),
    );
  }

  String _unitLabel(UnitType t) {
    switch (t) {
      case UnitType.sqm:    return 'm²';
      case UnitType.meter:  return 'm';
      case UnitType.piece:  return 'ta';
    }
  }

}


class _UnitBadge extends StatelessWidget {
  final UnitType unitType;
  const _UnitBadge(this.unitType);

  @override
  Widget build(BuildContext context) {
    final Color color;
    switch (unitType) {
      case UnitType.sqm: color = Colors.blue; break;
      case UnitType.meter: color = Colors.teal; break;
      case UnitType.piece: color = Colors.purple; break;
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
          fontSize: 11, fontWeight: FontWeight.bold, color: color,
        ),
      ),
    );
  }
}
