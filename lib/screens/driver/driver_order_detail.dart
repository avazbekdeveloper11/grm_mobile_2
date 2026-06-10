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
import '../../utils/latin_to_cyrillic.dart';
import '../../utils/map_utils.dart';
import '../../widgets/resolved_address_text.dart';
import '../../utils/phone_utils.dart';
import '../../widgets/call_button.dart';
import '../../widgets/status_badge.dart';
import 'pickup_items_screen.dart';

class DriverOrderDetail extends StatefulWidget {
  final OrderModel order;
  const DriverOrderDetail({super.key, required this.order});

  @override
  State<DriverOrderDetail> createState() => _DriverOrderDetailState();
}

class _DriverOrderDetailState extends State<DriverOrderDetail> {
  List<OrderItemModel> _items = [];
  bool _loadingItems = false;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() => _loadingItems = true);
    try {
      final data = await context.read<ApiService>().getOrderItems(widget.order.id);
      if (mounted) {
        setState(() => _items = data.map((e) => OrderItemModel.fromMap(e)).toList());
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingItems = false);
  }

  @override
  Widget build(BuildContext context) {
    final liveOrder = context.watch<OrderProvider>()
        .orders.firstWhere((o) => o.id == widget.order.id, orElse: () => widget.order);
    return _DetailBody(order: liveOrder, items: _items, loadingItems: _loadingItems,
        onReload: _loadItems);
  }
}

class _DetailBody extends StatelessWidget {
  final OrderModel order;
  final List<OrderItemModel> items;
  final bool loadingItems;
  final VoidCallback onReload;

  const _DetailBody({required this.order, required this.items,
      required this.loadingItems, required this.onReload});

  Widget? _addressValue(OrderModel order) {
    final coords = (order.pickupLat != null && order.pickupLng != null)
        ? (lat: order.pickupLat!, lng: order.pickupLng!)
        : coordsFromAddress(order.address);
    if (coords == null) return null;
    return ResolvedAddressText(lat: coords.lat, lng: coords.lng, fallback: order.address);
  }

  Widget? _mapButton(BuildContext context, OrderModel order) {
    double? lat = order.pickupLat;
    double? lng = order.pickupLng;
    if (lat == null || lng == null) {
      final coords = coordsFromAddress(order.address);
      if (coords == null) return null;
      lat = coords.lat;
      lng = coords.lng;
    }
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => openInMaps(lat!, lng!),
      child: Icon(Icons.map_outlined, size: 16, color: cs.primary),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fmt = NumberFormat('#,###');
    final dateFmt = DateFormat('dd.MM.yyyy');
    final isPickup = order.status == OrderStatus.yangi || order.status == OrderStatus.qabulQilindi;
    final isTayyor = order.status == OrderStatus.tayyor;
    final advance = order.advancePayment;
    final remaining = (order.effectivePrice - advance).clamp(0.0, double.infinity);

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: cs.surfaceContainerLowest,
        title: Column(children: [
          Text(order.customerName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text(orderNumber(order.id),
              style: TextStyle(fontSize: 12, color: cs.primary, fontWeight: FontWeight.bold)),
        ]),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async => onReload(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          children: [

            // ─── Status ────────────────────────────────────────────────────
            Builder(builder: (context) {
              final s = S(context.read<ThemeProvider>().language);
              return Card(child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(children: [
                  StatusBadge(status: order.status),
                  const Spacer(),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(dateFmt.format(isPickup ? order.pickupDate : order.deliveryDate),
                        style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                    Text(isPickup ? s.pickupLabel : s.deliveryTypeLabel,
                        style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                  ]),
                ]),
              ));
            }),
            const SizedBox(height: 10),

            // ─── Mijoz ─────────────────────────────────────────────────────
            Builder(builder: (context) {
              final s = S(context.read<ThemeProvider>().language);
              return _InfoCard(title: s.mijoz, icon: Icons.person_outline, children: [
                _Row(s.ismLabel, order.customerName),
                _Row(s.phone, formatPhone(order.phone),
                    trailing: CallButton(phone: order.phone, mini: true)),
                _Row(s.address, order.address,
                    trailing: _mapButton(context, order),
                    valueWidget: _addressValue(order)),
              ]);
            }),
            const SizedBox(height: 10),

            // ─── Xizmatlar ─────────────────────────────────────────────────
            if (items.isNotEmpty || loadingItems)
              _ItemsCard(items: items, loading: loadingItems, fmt: fmt),
            if (items.isEmpty && !loadingItems && order.carpetCount > 0)
              Builder(builder: (context) {
                final s = S(context.read<ThemeProvider>().language);
                return _InfoCard(title: s.xizmatlar, icon: Icons.inventory_2_outlined, children: [
                  _Row(s.carpetCount, '${order.carpetCount} ${s.pieces}'),
                  if (order.notes != null && order.notes!.isNotEmpty)
                    _Row(s.notes, order.notes!),
                ]);
              }),
            const SizedBox(height: 10),

            // ─── To'lov ma'lumotlari ───────────────────────────────────────
            Builder(builder: (context) {
              final s = S(context.read<ThemeProvider>().language);
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Icon(Icons.account_balance_wallet_outlined, size: 18, color: cs.primary),
                      const SizedBox(width: 8),
                      Text(s.paymentInfo,
                          style: TextStyle(fontWeight: FontWeight.bold,
                              color: cs.primary, fontSize: 14)),
                    ]),
                    const Divider(height: 20),

                    if (order.effectivePrice > 0) ...[
                      _PayRow(s.totalPriceLabel, "${fmt.format(order.effectivePrice)} ${s.currency}",
                          color: cs.onSurface, bold: true),
                      const SizedBox(height: 6),
                    ],
                    if (advance > 0) ...[
                      _PayRow(s.advanceTaken, "${fmt.format(advance)} ${s.currency}",
                          color: Colors.green.shade700),
                      const SizedBox(height: 6),
                      _PayRow(s.remainingSum, "${fmt.format(remaining)} ${s.currency}",
                          color: remaining > 0 ? Colors.red.shade700 : Colors.green.shade700,
                          bold: true),
                      const SizedBox(height: 14),
                    ],

                    if (order.paymentStatus == PaymentStatus.tolangan)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
                        ),
                        child: Row(children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 20),
                          const SizedBox(width: 8),
                          Text(s.fullyPaid,
                              style: TextStyle(color: Colors.green.shade700,
                                  fontWeight: FontWeight.bold, fontSize: 15)),
                        ]),
                      )
                    else if (order.paymentStatus == PaymentStatus.qarz)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
                        ),
                        child: Row(children: [
                          const Icon(Icons.credit_card_off, color: Colors.orange, size: 20),
                          const SizedBox(width: 8),
                          Text(s.deliveredAsDebtLabel,
                              style: TextStyle(color: Colors.orange.shade800,
                                  fontWeight: FontWeight.bold, fontSize: 15)),
                        ]),
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: Text(advance > 0 ? s.editAdvance : s.enterAdvance),
                          onPressed: () => _showAdvancePayment(context, advance),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.orange.shade600,
                            minimumSize: const Size(0, 48),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                  ]),
                ),
              );
            }),
            const SizedBox(height: 10),

            // ─── Harakatlar ────────────────────────────────────────────────
            _ActionButtons(order: order, isPickup: isPickup, isTayyor: isTayyor,
                onReload: onReload),
          ],
        ),
      ),
    );
  }

  Future<void> _showAdvancePayment(BuildContext context, double current) async {
    final s = S(context.read<ThemeProvider>().language);
    final initialText = current > 0
        ? ThousandsSeparatorInputFormatter().formatEditUpdate(
            const TextEditingValue(text: ''),
            TextEditingValue(text: current.toInt().toString()),
          ).text
        : '';
    final ctrl = TextEditingController(text: initialText);
    final fmt = NumberFormat('#,###');

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24,
            MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Icon(Icons.account_balance_wallet, size: 40, color: Colors.orange),
          const SizedBox(height: 12),
          Text(s.advancePayment,
              style: Theme.of(ctx).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
          const SizedBox(height: 6),
          if (order.effectivePrice > 0)
            Text("${s.totalPriceLabel}: ${fmt.format(order.effectivePrice)} ${s.currency}",
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(ctx).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 20),
          TextField(
            controller: ctrl,
            autofocus: true,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            inputFormatters: [ThousandsSeparatorInputFormatter()],
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              labelText: s.receivedAmount,
              suffixText: s.currency,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.orange, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.orange.shade600,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () async {
              final amount = double.tryParse(
                  ctrl.text.replaceAll(',', '.').replaceAll(' ', '').trim()) ?? 0;
              Navigator.pop(ctx);
              try {
                await context.read<OrderProvider>()
                    .saveAdvancePayment(order.id, amount);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(amount > 0
                        ? "✓ ${s.advancePayment}: ${NumberFormat('#,###').format(amount)} ${s.currency}"
                        : "✓ ${s.advancePayment} ${s.deleteOrder.toLowerCase()}"),
                    backgroundColor: Colors.orange.shade700,
                    behavior: SnackBarBehavior.floating,
                  ));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('${s.error}: $e'), backgroundColor: Colors.red));
                }
              }
            },
            child: Text(s.save,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.cancel),
          ),
        ]),
      ),
    );
  }
}

// ─── Items card ───────────────────────────────────────────────────────────────

class _ItemsCard extends StatelessWidget {
  final List<OrderItemModel> items;
  final bool loading;
  final NumberFormat fmt;
  const _ItemsCard({required this.items, required this.loading, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.inventory_2_outlined, size: 18, color: cs.primary),
          const SizedBox(width: 8),
          Text(S(context.read<ThemeProvider>().language).xizmatlar,
              style: TextStyle(fontWeight: FontWeight.bold,
              color: cs.primary, fontSize: 14)),
          if (loading) ...[
            const Spacer(),
            const SizedBox(width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 2)),
          ],
        ]),
        const Divider(height: 16),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                context.read<ThemeProvider>().language == AppLanguage.uzCyrillic
                    ? latinToCyrillic(item.serviceName)
                    : item.serviceName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(item.displaySize,
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
            ])),
          ]),
        )),
      ]),
    ));
  }
}

// ─── Action buttons ───────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  final OrderModel order;
  final bool isPickup;
  final bool isTayyor;
  final VoidCallback onReload;

  const _ActionButtons({required this.order, required this.isPickup,
      required this.isTayyor, required this.onReload});

  @override
  Widget build(BuildContext context) {
    final s = S(context.read<ThemeProvider>().language);

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      // O'lcham kiritish (pickup)
      if (isPickup || order.status == OrderStatus.yuvilyapti)
        FilledButton.icon(
          icon: const Icon(Icons.straighten, size: 18),
          label: Text(order.status == OrderStatus.yuvilyapti &&
              order.itemsSummary == null
              ? s.enterMeasurements : s.enterCarpetsPickup),
          onPressed: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => PickupItemsScreen(order: order)));
            onReload();
          },
          style: FilledButton.styleFrom(
            backgroundColor: order.status == OrderStatus.yuvilyapti &&
                order.itemsSummary == null
                ? Colors.orange.shade700 : Colors.blue.shade700,
            minimumSize: const Size(0, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),

      // To'lov olish (tayyor)
      if (isTayyor && order.paymentStatus == PaymentStatus.tolanmagan) ...[
        const SizedBox(height: 8),
        FilledButton.icon(
          icon: const Icon(Icons.payments, size: 18),
          label: _collectLabel(order, s),
          onPressed: () => _collectPayment(context),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.green,
            minimumSize: const Size(0, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ],
    ]);
  }

  Widget _collectLabel(OrderModel order, S s) {
    final fmt = NumberFormat('#,###');
    if (order.advancePayment > 0 && order.effectivePrice > 0) {
      final remaining = (order.effectivePrice - order.advancePayment)
          .clamp(0.0, double.infinity);
      return Text("${fmt.format(remaining)} so'm qabul qilish",
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold));
    }
    return Text(s.collectPayment,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold));
  }

  Future<void> _collectPayment(BuildContext context) async {
    final s = S(context.read<ThemeProvider>().language);
    final fmt = NumberFormat('#,###');
    final advance = order.advancePayment;
    final remaining = advance > 0 && order.effectivePrice > 0
        ? (order.effectivePrice - advance).clamp(0.0, double.infinity)
        : order.effectivePrice;
    final sumText = remaining > 0 ? "${fmt.format(remaining)} ${s.currency}" : s.noData;

    // result: 'paid' | 'debt' | null
    final result = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Icon(Icons.payments, size: 40, color: Colors.green),
          const SizedBox(height: 12),
          Text(s.paymentReceived,
              style: Theme.of(ctx).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),

          if (order.effectivePrice > 0) ...[
            _PayRow(s.totalPriceLabel, "${fmt.format(order.effectivePrice)} ${s.currency}",
                color: Colors.grey.shade700),
            if (advance > 0) ...[
              const SizedBox(height: 4),
              _PayRow(s.advanceTaken, "${fmt.format(advance)} ${s.currency}",
                  color: Colors.green.shade700),
              const Divider(height: 16),
              _PayRow(s.remainingSum, sumText,
                  color: Colors.red.shade700, bold: true, large: true),
            ],
          ],

          const SizedBox(height: 20),
          FilledButton.icon(
            icon: const Icon(Icons.check),
            label: Text("$sumText ${s.yesCollected}",
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            onPressed: () => Navigator.pop(ctx, 'paid'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.green,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.credit_card_off, color: Colors.orange),
            label: Text(s.deliverAsDebtBtn,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold,
                    color: Colors.orange)),
            onPressed: () => Navigator.pop(ctx, 'debt'),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.orange),
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: Text(s.cancel)),
        ]),
      ),
    );

    if (result != null && context.mounted) {
      try {
        if (result == 'paid') {
          await context.read<OrderProvider>().collectPayment(order.id);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text("✓ ${s.paymentReceived}"),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ));
          }
        } else if (result == 'debt') {
          await context.read<OrderProvider>().markAsDebt(order.id);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(s.deliveredAsDebtMsg),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ));
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('${s.error}: $e'), backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ));
        }
      }
    }
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  const _InfoCard({required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 18, color: cs.primary),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(fontWeight: FontWeight.bold,
              color: cs.primary, fontSize: 14)),
        ]),
        const Divider(height: 16),
        ...children,
      ]),
    ));
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final Widget? trailing;
  final Widget? valueWidget;
  const _Row(this.label, this.value, {this.trailing, this.valueWidget});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        SizedBox(width: 80,
            child: Text(label, style: TextStyle(
                fontSize: 12, color: cs.onSurfaceVariant))),
        Expanded(child: valueWidget ?? Text(value,
            style: const TextStyle(fontWeight: FontWeight.w500))),
        if (trailing != null) trailing!,
      ]),
    );
  }
}

class _PayRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool bold;
  final bool large;
  const _PayRow(this.label, this.value,
      {required this.color, this.bold = false, this.large = false});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text(label, style: TextStyle(
          fontSize: large ? 15 : 13, color: color)),
      const Spacer(),
      Text(value, style: TextStyle(
          fontSize: large ? 16 : 13, color: color,
          fontWeight: bold ? FontWeight.bold : FontWeight.w500)),
    ]);
  }
}
