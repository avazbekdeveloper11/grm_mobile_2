import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../l10n/strings.dart';
import '../../models/carpet_model.dart';
import '../../models/order_model.dart';
import '../../models/service_model.dart';
import '../../models/user_model.dart';
import '../../providers/order_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/api_service.dart';
import '../../services/sms_service.dart';
import '../../utils/order_number.dart';
import '../../utils/latin_to_cyrillic.dart';
import '../../utils/map_utils.dart';
import '../../widgets/resolved_address_text.dart';
import '../../utils/phone_utils.dart';
import '../../widgets/call_button.dart';
import '../../widgets/select_driver_dialog.dart';
import '../../widgets/status_badge.dart';
import 'edit_order_items_screen.dart';
import 'order_form_screen.dart';

class OrderDetailScreen extends StatefulWidget {
  final OrderModel order;
  final bool readOnly;
  const OrderDetailScreen({super.key, required this.order, this.readOnly = false});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  List<CarpetModel>? _carpets;
  List<OrderItemModel> _items = [];
  List<ServiceModel> _services = [];
  Map<String, dynamic> _discountSettings = {};
  bool _loadingCarpets = false;

  @override
  void initState() {
    super.initState();
    _loadCarpets();
  }

  Future<void> _loadCarpets() async {
    setState(() => _loadingCarpets = true);
    try {
      final api = context.read<ApiService>();
      final results = await Future.wait([
        context.read<OrderProvider>().getCarpets(widget.order.id),
        api.getOrderItems(widget.order.id),
        api.getServices(),
        api.getSettings(),
      ]);
      if (mounted) {
        setState(() {
          _carpets = results[0] as List<CarpetModel>;
          _items = (results[1] as List)
              .map((e) => OrderItemModel.fromMap(e))
              .toList();
          _services = (results[2] as List)
              .map((e) => ServiceModel.fromMap(e))
              .toList();
          _discountSettings = results[3] as Map<String, dynamic>;
          _loadingCarpets = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingCarpets = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final liveOrder = context.watch<OrderProvider>().orders.firstWhere(
      (o) => o.id == widget.order.id,
      orElse: () => widget.order,
    );

    return _DetailBody(
      order: liveOrder,
      carpets: _carpets,
      items: _items,
      services: _services,
      discountSettings: _discountSettings,
      loadingCarpets: _loadingCarpets,
      onReloadCarpets: _loadCarpets,
      readOnly: widget.readOnly,
    );
  }
}

// ─── Body ──────────────────────────────────────────────────────────────────────

class _DetailBody extends StatelessWidget {
  final OrderModel order;
  final List<CarpetModel>? carpets;
  final List<OrderItemModel> items;
  final List<ServiceModel> services;
  final Map<String, dynamic> discountSettings;
  final bool loadingCarpets;
  final VoidCallback onReloadCarpets;
  final bool readOnly;

  const _DetailBody({
    required this.order,
    required this.carpets,
    required this.items,
    required this.loadingCarpets,
    required this.onReloadCarpets,
    this.services = const [],
    this.discountSettings = const {},
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final s = S(context.read<ThemeProvider>().language);
    final fmt = DateFormat('dd.MM.yyyy');
    final moneyFmt = NumberFormat('#,###');
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final up = context.read<UserProvider>();

    final worker = order.assignedWorkerId != null
        ? up.workers.firstWhere(
            (w) => w.id == order.assignedWorkerId,
            orElse: () => UserModel(
              id: '',
              login: '',
              password: '',
              name: s.unknownName,
              role: UserRole.worker,
            ),
          )
        : null;

    final driver = order.assignedDriverId != null
        ? up.drivers.firstWhere(
            (d) => d.id == order.assignedDriverId,
            orElse: () => UserModel(
              id: '',
              login: '',
              password: '',
              name: s.unknownName,
              role: UserRole.driver,
            ),
          )
        : null;

    final upakovchik = order.assignedUpakovchikId != null
        ? up.activeUpakovchilar.firstWhere(
            (u) => u.id == order.assignedUpakovchikId,
            orElse: () => UserModel(
              id: '',
              login: '',
              password: '',
              name: s.unknownName,
              role: UserRole.upakovchik,
            ),
          )
        : null;

    final isOverdue = false; // yetkazish sanasi yo'q

    // Carpet calculations
    final hasCarpets = carpets != null && carpets!.isNotEmpty;
    final totalArea = hasCarpets
        ? carpets!.fold(0.0, (s, c) => s + c.area)
        : 0.0;
    final double totalSum = order.effectivePrice > 0
        ? order.effectivePrice
        : (hasCarpets ? carpets!.fold(0.0, (s, c) => s + c.price) : 0.0);

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: cs.surfaceContainerLowest,
        title: Column(
          children: [
            Text(
              order.customerName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              orderNumber(order.id),
              style: TextStyle(
                fontSize: 12,
                color: cs.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: readOnly ? null : [
          IconButton(
            icon: const Icon(Icons.inventory_2_outlined),
            tooltip: 'Mahsulotlarni tahrirlash',
            onPressed: () async {
              final result = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => EditOrderItemsScreen(order: order),
                ),
              );
              if (result == true) onReloadCarpets();
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => OrderFormScreen(order: order)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => onReloadCarpets(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          children: [
            // ─── Status + progress ─────────────────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        StatusBadge(status: order.status),
                        Row(
                          children: [
                            PaymentBadge(status: order.paymentStatus),
                            if (isOverdue) ...[
                              const SizedBox(width: 6),
                              _Chip('Kechikdi', Colors.red),
                            ],
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _StatusStepper(current: order.status),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // ─── Gilam o'lchamlari (asosiy blok) ──────────────────────────
            // Order items (new system)
            if (items.isNotEmpty)
              _OrderItemsSection(
                items: items,
                services: services,
                discountSettings: discountSettings,
                moneyFmt: moneyFmt,
                discountAmount: order.discountAmount,
              )
            else
              _CarpetSection(
                orderId: order.id,
                carpets: carpets,
                loading: loadingCarpets,
                carpetCount: order.carpetCount,
                totalArea: totalArea,
                totalSum: totalSum,
                discountAmount: order.discountAmount,
                moneyFmt: moneyFmt,
                onReload: onReloadCarpets,
              ),
            const SizedBox(height: 10),

            // ─── Mijoz ────────────────────────────────────────────────────
            _Card(
              title: s.customer,
              icon: Icons.person_outline,
              rows: [
                _InfoRow(
                  s.name,
                  order.customerName,
                  trailing: null,
                  onCopy: () => _copy(context, order.customerName),
                ),
                _InfoRow(
                  s.phone,
                  formatPhone(order.phone),
                  trailing: CallButton(phone: order.phone, mini: true),
                  onCopy: () => _copy(context, order.phone),
                ),
                _InfoRow(
                  s.address,
                  order.address,
                  onCopy: () => _copy(context, order.address),
                  trailing: _buildMapButton(context, order),
                  valueWidget: _addressValue(order),
                ),
                if (order.fromBot)
                  _InfoRow(
                    s.orderSource,
                    s.fromBotLabel,
                    valueColor: AppColors.info,
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // ─── Sana va to'lov ───────────────────────────────────────────
            _PriceCard(
              order: order,
              totalSum: totalSum,
              moneyFmt: moneyFmt,
              fmt: fmt,
              s: s,
              readOnly: readOnly,
            ),
            const SizedBox(height: 10),

            // ─── Tayinlash ────────────────────────────────────────────────
            _Card(
              title: s.assignInfo,
              icon: Icons.assignment_ind_outlined,
              rows: [
                _InfoRow(
                  s.worker,
                  worker?.name ?? s.notAssigned,
                  valueColor: worker == null ? Colors.orange : null,
                ),
                _InfoRow(
                  s.upakovchikLabel,
                  upakovchik?.name ?? s.notAssigned,
                  valueColor: upakovchik == null ? Colors.orange : null,
                ),
                _InfoRow(
                  s.driver,
                  driver?.name ?? s.notAssigned,
                  valueColor: driver == null ? Colors.orange : null,
                ),
              ],
            ),

            if (order.notes != null && order.notes!.isNotEmpty) ...[
              const SizedBox(height: 10),
              _Card(
                title: s.notes,
                icon: Icons.notes_outlined,
                rows: [_InfoRow('', order.notes!)],
              ),
            ],

            const SizedBox(height: 16),
            _ActionButtons(
              order: order,
              readOnly: readOnly,
              onStatusChange: (msg, color) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(msg),
                      backgroundColor: color,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _copy(BuildContext context, String text) {
    final s = S(context.read<ThemeProvider>().language);
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(s.copyDone),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget? _addressValue(OrderModel order) {
    final coords = (order.pickupLat != null && order.pickupLng != null)
        ? (lat: order.pickupLat!, lng: order.pickupLng!)
        : coordsFromAddress(order.address);
    if (coords == null) return null;
    return ResolvedAddressText(
      lat: coords.lat,
      lng: coords.lng,
      fallback: order.address,
    );
  }

  Widget? _buildMapButton(BuildContext context, OrderModel order) {
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

  void _confirmDelete(BuildContext context) {
    final s = S(context.read<ThemeProvider>().language);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(s.deleteConfirm),
        content: Text("${order.customerName} ${s.deleteOrderConfirm}"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(s.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await context.read<OrderProvider>().deleteOrder(order.id);
              if (ctx.mounted) Navigator.of(ctx).pop();
              if (context.mounted) Navigator.of(context).pop();
            },
            child: Text(s.delete),
          ),
        ],
      ),
    );
  }
}

// ─── Order items section (new system) ────────────────────────────────────────

class _OrderItemsSection extends StatelessWidget {
  final List<OrderItemModel> items;
  final List<ServiceModel> services;
  final Map<String, dynamic> discountSettings;
  final NumberFormat moneyFmt;
  final double discountAmount;
  const _OrderItemsSection({
    required this.items,
    required this.moneyFmt,
    this.services = const [],
    this.discountSettings = const {},
    this.discountAmount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final s = S(context.read<ThemeProvider>().language);
    final cs = Theme.of(context).colorScheme;
    // serviceMap — tez qidirish uchun
    final serviceMap = {for (final s in services) s.id: s};

    // Global discount settings
    final globalEnabled =
        discountSettings['discount_enabled'] == true ||
        discountSettings['discount_enabled'] == 1 ||
        discountSettings['discount_enabled'] == '1';
    final globalMinSqm = ((discountSettings['discount_min_sqm'] ?? 0) as num)
        .toDouble();
    final globalPct = ((discountSettings['discount_percentage'] ?? 0) as num)
        .toDouble();

    // trueRaw — skidkasiz narx (unitPrice × miqdor)
    final trueRaw = items.fold(
      0.0,
      (sum, i) => sum + i.unitPrice * (i.area ?? i.quantity),
    );

    // Jami sqm (global skidka uchun)
    final totalSqm = items.fold(
      0.0,
      (sum, i) => i.unitType == UnitType.sqm ? sum + (i.area ?? 0) : sum,
    );

    // Xizmat bo'yicha yig'indi miqdorlar (per-service discount uchun)
    final Map<String, double> serviceQtyMap = {};
    for (final i in items) {
      serviceQtyMap[i.serviceId] =
          (serviceQtyMap[i.serviceId] ?? 0) + (i.area ?? i.quantity);
    }

    // Xizmat uchun skidka foizini qaytaradi (yig'indi miqdor bo'yicha tekshiradi)
    double serviceDiscountPct(String serviceId) {
      final totalQty = serviceQtyMap[serviceId] ?? 0;
      final svc = serviceMap[serviceId];
      if (svc != null &&
          svc.discountEnabled &&
          svc.discountMinQty > 0 &&
          svc.discountAmount > 0) {
        if (totalQty >= svc.discountMinQty) return svc.discountAmount;
      }
      return 0.0;
    }

    // Per-service skidka: xizmat bo'yicha yig'indi tekshiriladi
    double itemDiscountPct(OrderItemModel i) => serviceDiscountPct(i.serviceId);

    final perServiceDiscount = items.fold(0.0, (sum, i) {
      final pct = serviceDiscountPct(i.serviceId);
      if (pct <= 0) return sum;
      return sum + i.unitPrice * (i.area ?? i.quantity) * pct / 100;
    });

    // Global skidka: barcha sqm itemlar yig'indisi chegaradan oshsa
    final afterServiceDiscount = trueRaw - perServiceDiscount;
    final globalDiscountAmt =
        (globalEnabled &&
            globalMinSqm > 0 &&
            globalPct > 0 &&
            totalSqm >= globalMinSqm)
        ? afterServiceDiscount * globalPct / 100
        : (discountAmount > 0 ? discountAmount : 0.0);

    // finalTotal — barcha skidkalar
    final finalTotal = (trueRaw - perServiceDiscount - globalDiscountAmt).clamp(
      0.0,
      double.infinity,
    );
    // Barcha skidkalar yig'indisi
    final totalDiscount = perServiceDiscount + globalDiscountAmt;

    // Group by service name
    final Map<String, List<OrderItemModel>> grouped = {};
    for (final item in items) {
      grouped.putIfAbsent(item.serviceName, () => []).add(item);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.inventory_2_outlined, size: 18, color: cs.primary),
                const SizedBox(width: 8),
                Text(
                  S(context.read<ThemeProvider>().language).washingItems,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: cs.primary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const Divider(height: 16),

            // Summary
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Column(
                children: [
                  // Skidkasiz narx
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        totalDiscount > 0.5 ? s.subtotal : s.totalPrice,
                        style: TextStyle(
                          fontSize: 13,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          '${moneyFmt.format(trueRaw)} ${s.currency}',
                          textAlign: TextAlign.end,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: totalDiscount > 0.5
                                ? cs.onSurfaceVariant
                                : Colors.green.shade700,
                            fontWeight: totalDiscount > 0.5
                                ? FontWeight.normal
                                : FontWeight.bold,
                            decoration: totalDiscount > 0.5
                                ? TextDecoration.lineThrough
                                : null,
                            decorationColor: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (totalDiscount > 0.5) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.discount_outlined,
                              size: 14,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              s.discountApplied,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.orange,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Flexible(
                          child: Text(
                            '-${moneyFmt.format(totalDiscount)} ${s.currency}',
                            textAlign: TextAlign.end,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          s.totalPrice,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Flexible(
                          child: Text(
                            '${moneyFmt.format(finalTotal)} ${s.currency}',
                            textAlign: TextAlign.end,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Each service group
            ...grouped.entries.map((entry) {
              final grpItems = entry.value;
              final isSqm = grpItems.first.unitType == UnitType.sqm;
              final grpRaw = grpItems.fold(
                0.0,
                (sum, i) => sum + i.unitPrice * (i.area ?? i.quantity),
              );
              final grpDiscount = grpItems.fold(0.0, (sum, i) {
                final pct = itemDiscountPct(i);
                if (pct <= 0) return sum;
                return sum + i.unitPrice * (i.area ?? i.quantity) * pct / 100;
              });
              final grpTotal = grpRaw - grpDiscount;
              final totalArea = isSqm
                  ? grpItems.fold(0.0, (sum, i) => sum + (i.area ?? 0))
                  : null;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Group header: xizmat nomi + asl narx (chizilgan) yoki yakuniy
                      Row(
                        children: [
                          _unitBadge(grpItems.first.unitType),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              context.read<ThemeProvider>().language ==
                                      AppLanguage.uzCyrillic
                                  ? latinToCyrillic(entry.key)
                                  : entry.key,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          if (grpDiscount > 0.5)
                            Flexible(
                              child: Text(
                                "${moneyFmt.format(grpRaw)} ${S(context.read<ThemeProvider>().language).currency}",
                                textAlign: TextAlign.end,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: cs.onSurfaceVariant,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            )
                          else
                            Flexible(
                              child: Text(
                                "${moneyFmt.format(grpTotal)} ${S(context.read<ThemeProvider>().language).currency}",
                                textAlign: TextAlign.end,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                        ],
                      ),

                      // Skidka qatori
                      if (grpDiscount > 0.5) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.discount_outlined,
                                  size: 13,
                                  color: Colors.orange,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  S(
                                    context.read<ThemeProvider>().language,
                                  ).discountApplied,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                            Flexible(
                              child: Text(
                                '-${moneyFmt.format(grpDiscount)} ${S(context.read<ThemeProvider>().language).currency}',
                                textAlign: TextAlign.end,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              S(
                                context.read<ThemeProvider>().language,
                              ).totalPrice,
                              style: TextStyle(
                                fontSize: 12,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                            Flexible(
                              child: Text(
                                "${moneyFmt.format(grpTotal)} ${S(context.read<ThemeProvider>().language).currency}",
                                textAlign: TextAlign.end,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],

                      // sqm: show each piece
                      if (isSqm && grpItems.length > 1) ...[
                        const SizedBox(height: 8),
                        Text(
                          '${grpItems.length} ${S(context.read<ThemeProvider>().language).pieces} · ${S(context.read<ThemeProvider>().language).totalAreaLabel}${totalArea!.toStringAsFixed(2)} ${S(context.read<ThemeProvider>().language).sqMeter}',
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ...grpItems.asMap().entries.map((e) {
                          final i = e.key;
                          final it = e.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                Container(
                                  width: 22,
                                  height: 22,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: cs.primary.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '${i + 1}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: cs.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  it.displaySize,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                                const Spacer(),
                                Flexible(
                                  child: Text(
                                    "${moneyFmt.format(it.totalPrice)} ${S(context.read<ThemeProvider>().language).currency}",
                                    textAlign: TextAlign.end,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ] else if (isSqm && grpItems.length == 1) ...[
                        const SizedBox(height: 4),
                        Text(
                          grpItems.first.displaySize,
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 4),
                        Text(
                          grpItems.first.displaySize,
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

Widget _unitBadge(UnitType t) {
  final Color color;
  final String label;
  switch (t) {
    case UnitType.sqm:
      color = Colors.blue;
      label = 'm²';
      break;
    case UnitType.meter:
      color = Colors.teal;
      label = 'metr';
      break;
    case UnitType.piece:
      color = Colors.purple;
      label = 'dona';
      break;
  }
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      label,
      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
    ),
  );
}

// ─── Carpet section ────────────────────────────────────────────────────────────

class _CarpetSection extends StatelessWidget {
  final String orderId;
  final List<CarpetModel>? carpets;
  final bool loading;
  final int carpetCount;
  final double totalArea;
  final double totalSum;
  final double discountAmount;
  final NumberFormat moneyFmt;
  final VoidCallback onReload;

  const _CarpetSection({
    required this.orderId,
    required this.carpets,
    required this.loading,
    required this.carpetCount,
    required this.totalArea,
    required this.totalSum,
    required this.moneyFmt,
    required this.onReload,
    this.discountAmount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final hasCarpets = carpets != null && carpets!.isNotEmpty;
    final notMeasured = !hasCarpets && !loading;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.layers_outlined, size: 18, color: cs.primary),
                const SizedBox(width: 8),
                Text(
                  S(context.read<ThemeProvider>().language).carpet,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: cs.primary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 8),
                // Order number for driver reference
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.tag, size: 12, color: cs.onPrimaryContainer),
                      const SizedBox(width: 2),
                      Text(
                        orderNumber(orderId),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: cs.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (loading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    icon: Icon(
                      Icons.refresh,
                      size: 18,
                      color: cs.onSurfaceVariant,
                    ),
                    onPressed: onReload,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: S(context.read<ThemeProvider>().language).refresh,
                  ),
              ],
            ),
            const Divider(height: 16),

            // Not measured yet
            if (notMeasured) ...[
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.straighten,
                      color: cs.onSurfaceVariant,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      carpetCount > 0
                          ? S(
                              context.read<ThemeProvider>().language,
                            ).driverNotPickedYet
                          : S(
                              context.read<ThemeProvider>().language,
                            ).driverNotPickedYet,
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Carpet list
            if (hasCarpets) ...[
              // Summary strip
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade600, Colors.green.shade400],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    // Count
                    _SummaryItem(
                      icon: Icons.layers,
                      label: S(context.read<ThemeProvider>().language).carpet,
                      value:
                          '${carpets!.length} ${S(context.read<ThemeProvider>().language).pieces}',
                    ),
                    _Divider(),
                    // Area
                    _SummaryItem(
                      icon: Icons.square_foot,
                      label: S(
                        context.read<ThemeProvider>().language,
                      ).totalArea,
                      value:
                          '${totalArea.toStringAsFixed(2)} ${S(context.read<ThemeProvider>().language).sqMeter}',
                    ),
                    _Divider(),
                    // Sum
                    _SummaryItem(
                      icon: Icons.payments_outlined,
                      label: S(
                        context.read<ThemeProvider>().language,
                      ).totalPrice,
                      value:
                          "${moneyFmt.format(totalSum)} ${S(context.read<ThemeProvider>().language).currency}",
                    ),
                  ],
                ),
              ),
              if (discountAmount > 0) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.discount_outlined,
                        size: 16,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          S(
                            context.read<ThemeProvider>().language,
                          ).discountApplied,
                          style: const TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Flexible(
                        child: Text(
                          '-${moneyFmt.format(discountAmount)} ${S(context.read<ThemeProvider>().language).currency}',
                          textAlign: TextAlign.end,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        S(context.read<ThemeProvider>().language).totalPrice,
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          '${moneyFmt.format((totalSum - discountAmount).clamp(0, double.infinity))} ${S(context.read<ThemeProvider>().language).currency}',
                          textAlign: TextAlign.end,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),

              // Each carpet row
              ...carpets!.asMap().entries.map((e) {
                final i = e.key;
                final c = e.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      // Number
                      Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${i + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Dimensions
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  color: cs.onSurface,
                                  fontSize: 14,
                                ),
                                children: [
                                  TextSpan(
                                    text: '${c.width}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const TextSpan(text: ' m  ×  '),
                                  TextSpan(
                                    text: '${c.height}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const TextSpan(text: ' m'),
                                ],
                              ),
                            ),
                            Text(
                              '= ${c.area.toStringAsFixed(2)} m²',
                              style: TextStyle(
                                fontSize: 12,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Price
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text(
                              '${moneyFmt.format(c.price)} so\'m',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Text(
                            '${c.area.toStringAsFixed(2)} m²',
                            style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
  );
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 36,
    color: Colors.white.withValues(alpha: 0.3),
    margin: const EdgeInsets.symmetric(horizontal: 8),
  );
}

// ─── Action buttons ────────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  final OrderModel order;
  final void Function(String msg, Color color) onStatusChange;
  final bool readOnly;

  const _ActionButtons({required this.order, required this.onStatusChange, this.readOnly = false});

  @override
  Widget build(BuildContext context) {
    if (readOnly) return const SizedBox.shrink();
    final s = S(context.read<ThemeProvider>().language);
    final provider = context.read<OrderProvider>();
    final next = _next(order.status);
    final canPay =
        order.paymentStatus == PaymentStatus.tolanmagan ||
        order.paymentStatus == PaymentStatus.qarz;

    final canRevert =
        order.status == OrderStatus.yuvilyapti ||
        order.status == OrderStatus.upakovka;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Status orqaga qaytarish (yuvilyapti → qabulQilindi)
        if (canRevert) ...[
          OutlinedButton.icon(
            icon: const Icon(Icons.undo, size: 18),
            label: Text(s.markNotPickedUp),
            onPressed: () => _confirmRevert(context, provider),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              foregroundColor: Colors.orange.shade700,
              side: BorderSide(color: Colors.orange.shade400),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (next != null)
          FilledButton.icon(
            icon: const Icon(Icons.arrow_forward),
            label: Text("${next.labelOf(s)}${s.moveTo}"),
            onPressed: () async {
              String? driverId;

              // "Tayyor"ga o'tkazishda haydovchi tanlash
              if (next == OrderStatus.tayyor) {
                final result = await showSelectDriverDialog(
                  context,
                  currentDriverId: order.assignedDriverId,
                );
                if (!context.mounted) return;
                // Bekor qilindi yoki yopildi — hech narsa qilma
                if (!result.confirmed) return;
                driverId = result.driver?.id;
              }

              final sms = await provider.updateOrderStatus(
                order.id,
                next,
                driverId: driverId,
              );
              final msg = _statusMsg(next, sms, s);
              onStatusChange(msg, Color(next.colorValue));
              if (context.mounted) Navigator.of(context).pop();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Color(next.colorValue),
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        if (canPay) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.check_circle_outline),
            label: Text(S(context.read<ThemeProvider>().language).markPaid),
            onPressed: () async {
              await provider.updatePaymentStatus(
                order.id,
                PaymentStatus.tolangan,
              );
              if (!context.mounted) return;
              onStatusChange(
                S(context.read<ThemeProvider>().language).paymentReceived,
                Colors.green,
              );
              Navigator.of(context).pop();
            },
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              foregroundColor: Colors.green,
              side: const BorderSide(color: Colors.green),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _confirmRevert(
    BuildContext context,
    OrderProvider provider,
  ) async {
    final s = S(context.read<ThemeProvider>().language);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.undo, color: Colors.orange, size: 36),
        title: Text(s.revertStatus, textAlign: TextAlign.center),
        content: Text(s.revertBody, textAlign: TextAlign.center),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.yesReturn),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final revertTo = order.status == OrderStatus.upakovka
        ? OrderStatus.yuvilyapti
        : OrderStatus.qabulQilindi;
    await provider.updateOrderStatus(order.id, revertTo);
    if (context.mounted) {
      onStatusChange('${s.revertStatus}: ${s.markNotPickedUp}', Colors.orange);
      Navigator.of(context).pop();
    }
  }

  String _statusMsg(OrderStatus next, SmsResult? sms, S s) {
    if (next != OrderStatus.tayyor)
      return '${s.statusUpdatedMsg}${next.labelOf(s)}';
    switch (sms) {
      case SmsResult.sent:
        return s.readySmsSent;
      case SmsResult.permissionDenied:
        return s.readySmsNoPermit;
      default:
        return s.readyOk;
    }
  }

  OrderStatus? _next(OrderStatus s) {
    final i = OrderStatus.values.indexOf(s);
    if (i < OrderStatus.values.length - 1) return OrderStatus.values[i + 1];
    return null;
  }
}

// ─── Status stepper ────────────────────────────────────────────────────────────

class _StatusStepper extends StatelessWidget {
  final OrderStatus current;
  const _StatusStepper({required this.current});

  @override
  Widget build(BuildContext context) {
    final lang = S(context.read<ThemeProvider>().language);
    final statuses = OrderStatus.values;
    final idx = statuses.indexOf(current);

    return Row(
      children: statuses.asMap().entries.map((e) {
        final i = e.key;
        final s = e.value;
        final done = i <= idx;
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: done
                            ? Color(s.colorValue)
                            : Colors.grey.shade200,
                        boxShadow: done
                            ? [
                                BoxShadow(
                                  color: Color(
                                    s.colorValue,
                                  ).withValues(alpha: 0.35),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        done ? Icons.check : Icons.circle,
                        color: done ? Colors.white : Colors.grey.shade400,
                        size: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      s.labelOf(lang),
                      style: TextStyle(
                        fontSize: 9,
                        color: done
                            ? Color(s.colorValue)
                            : Colors.grey.shade400,
                        fontWeight: done ? FontWeight.bold : FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              if (i < statuses.length - 1)
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 2,
                    color: i < idx ? Colors.green : Colors.grey.shade200,
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ─── Reusable card ─────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<_InfoRow> rows;

  const _Card({required this.title, required this.icon, required this.rows});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: cs.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: cs.primary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            ...rows,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;
  final VoidCallback? onCopy;
  final Widget? trailing;
  final Widget? valueWidget;

  const _InfoRow(
    this.label,
    this.value, {
    this.valueColor,
    this.bold = false,
    this.onCopy,
    this.trailing,
    this.valueWidget,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (label.isNotEmpty)
            SizedBox(
              width: 90,
              child: Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          Expanded(
            child:
                valueWidget ??
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: bold ? FontWeight.bold : FontWeight.w500,
                    color: valueColor,
                  ),
                ),
          ),
          if (onCopy != null) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onCopy,
              child: Icon(
                Icons.copy_outlined,
                size: 14,
                color: theme.colorScheme.outline,
              ),
            ),
          ],
          if (trailing != null) ...[const SizedBox(width: 6), trailing!],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  final Color color;
  const _Chip(this.text, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: 0.4)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.warning_amber_rounded, color: color, size: 12),
        const SizedBox(width: 3),
        Text(text, style: TextStyle(color: color, fontSize: 11)),
      ],
    ),
  );
}

// ─── Price card ───────────────────────────────────────────────────────────────

class _PriceCard extends StatelessWidget {
  final OrderModel order;
  final double totalSum;
  final NumberFormat moneyFmt;
  final DateFormat fmt;
  final S s;
  final bool readOnly;

  const _PriceCard({
    required this.order,
    required this.totalSum,
    required this.moneyFmt,
    required this.fmt,
    required this.s,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasManual = order.manualPrice != null;
    final advance = order.advancePayment;
    final remaining = totalSum > 0
        ? (totalSum - advance).clamp(0.0, double.infinity)
        : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.payments_outlined, size: 16, color: cs.primary),
                const SizedBox(width: 8),
                Text(
                  s.dateAndPayment,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: cs.primary,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                // Narx o'zgartirish tugmasi (faqat admin uchun)
                if (!readOnly)
                  GestureDetector(
                    onTap: () => _showPriceDialog(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: hasManual
                            ? Colors.orange.withValues(alpha: 0.1)
                            : cs.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: hasManual
                              ? Colors.orange.shade300
                              : cs.outlineVariant,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.edit_outlined,
                            size: 13,
                            color: hasManual
                                ? Colors.orange.shade700
                                : cs.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            hasManual ? s.agreedPrice : s.setPriceTitle,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: hasManual
                                  ? Colors.orange.shade700
                                  : cs.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const Divider(height: 16),

            _InfoRow(s.pickupDateLabel, fmt.format(order.pickupDate)),
            if (order.totalPrice > 0 && hasManual)
              _InfoRow(
                s.calculatedPrice,
                "${moneyFmt.format(order.totalPrice)} ${s.currency}",
                valueColor: cs.onSurfaceVariant,
              ),
            if (totalSum > 0) ...[
              _InfoRow(
                hasManual ? s.agreedPrice : s.totalPrice,
                "${moneyFmt.format(totalSum)} ${s.currency}",
                valueColor: hasManual
                    ? Colors.orange.shade700
                    : Colors.green.shade700,
              ),
            ],
            if (advance > 0) ...[
              _InfoRow(
                s.advancePayment,
                "${moneyFmt.format(advance)} ${s.currency}",
                valueColor: Colors.orange,
              ),
              if (totalSum > 0)
                _InfoRow(
                  s.remainingAmount,
                  "${moneyFmt.format(remaining)} ${s.currency}",
                  valueColor: Colors.red.shade700,
                ),
            ],
            _InfoRow(
              s.paid,
              order.paymentStatus.labelOf(s),
              valueColor: order.paymentStatus == PaymentStatus.tolangan
                  ? Colors.green
                  : Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showPriceDialog(BuildContext context) async {
    final s = S(context.read<ThemeProvider>().language);
    final rawValue = order.manualPrice != null
        ? order.manualPrice!.toInt().toString()
        : (order.totalPrice > 0 ? order.totalPrice.toInt().toString() : '');
    final initialText = rawValue.isNotEmpty
        ? ThousandsSeparatorInputFormatter()
              .formatEditUpdate(
                const TextEditingValue(text: ''),
                TextEditingValue(text: rawValue),
              )
              .text
        : '';
    final ctrl = TextEditingController(text: initialText);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.price_change_outlined,
              size: 40,
              color: Colors.orange,
            ),
            const SizedBox(height: 12),
            Text(
              s.setPriceTitle,
              style: Theme.of(
                ctx,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            if (order.totalPrice > 0)
              Text(
                '${s.calculatedPrice}: ${NumberFormat('#,###').format(order.totalPrice)} ${s.currency}',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            const SizedBox(height: 20),
            TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              inputFormatters: [ThousandsSeparatorInputFormatter()],
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: s.agreedPrice,
                suffixText: s.currency,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () async {
                final amount = double.tryParse(
                  ctrl.text.replaceAll(' ', '').replaceAll(',', '.').trim(),
                );
                Navigator.pop(ctx);
                if (!context.mounted) return;
                try {
                  await context.read<OrderProvider>().setManualPrice(
                    order.id,
                    amount,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          amount != null
                              ? "✓ ${s.agreedPrice}: ${NumberFormat('#,###').format(amount)} ${s.currency}"
                              : "✓ ${s.cancelAgreedPrice}",
                        ),
                        backgroundColor: Colors.orange.shade700,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${s.error}: $e'),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
              child: Text(
                s.save,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (order.manualPrice != null) ...[
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  if (!context.mounted) return;
                  await context.read<OrderProvider>().setManualPrice(
                    order.id,
                    null,
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(s.cancelAgreedPrice),
              ),
            ],
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(s.close),
            ),
          ],
        ),
      ),
    );
  }
}
