// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../l10n/strings.dart';
import '../../models/order_model.dart';
import '../../providers/theme_provider.dart';
import '../../models/service_model.dart';
import '../../providers/order_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../utils/order_number.dart';
import '../../utils/phone_utils.dart';
import '../../widgets/call_button.dart';

class PickupItemsScreen extends StatefulWidget {
  final OrderModel order;
  const PickupItemsScreen({super.key, required this.order});
  @override
  State<PickupItemsScreen> createState() => _PickupItemsScreenState();
}

class _PickupItemsScreenState extends State<PickupItemsScreen> {
  List<ServiceModel> _services = [];
  final Map<String, _ServiceEntry> _entries = {};
  bool _loading = true;
  bool _saving = false;
  final _fmt = NumberFormat('#,###');

  // Location
  double? _lat, _lng;
  bool _locLoading = false;
  bool _locDone = false;
  String _locMsg = '';

  // Discount
  bool _discountEnabled = false;
  double _discountMinSqm = 0;
  double _discountAmt = 0;        // eski fixed amount
  double _discountPct = 0;        // foiz (masalan 5.0 = 5%)
  double _discountStepSqm = 10;   // har necha kvadratda 2x bo'ladi

  // Oldindan to'lov
  final _advanceCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadServices();
    _loadDiscountSettings();
    // Oldindan to'lovni to'ldirish
    if (widget.order.advancePayment > 0) {
      _advanceCtrl.text = ThousandsSeparatorInputFormatter().formatEditUpdate(
        const TextEditingValue(text: ''),
        TextEditingValue(text: widget.order.advancePayment.toInt().toString()),
      ).text;
    }
    // Agar avval location saqlangan bo'lsa, uni oldindan to'ldirish
    if (widget.order.pickupLat != null && widget.order.pickupLng != null) {
      _lat = widget.order.pickupLat;
      _lng = widget.order.pickupLng;
      _locDone = true;
      _locMsg = 'ok';
    } else {
      _getLocation();
    }
  }

  Future<void> _getLocation() async {
    setState(() { _locLoading = true; _locMsg = ''; _locDone = false; });
    try {
      // GPS yoqilganmi?
      if (!await Geolocator.isLocationServiceEnabled()) {
        setState(() { _locLoading = false; _locMsg = 'gps_off'; });
        _showGpsOffDialog();
        return;
      }
      // Ruxsat tekshiruv
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        setState(() { _locLoading = false; _locMsg = 'perm_denied'; });
        _showPermDeniedDialog();
        return;
      }
      if (perm == LocationPermission.denied) {
        setState(() { _locLoading = false; _locMsg = 'perm_denied'; });
        return;
      }
      // Koordinata olish — avval tez (lastKnown), keyin aniq
      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 20),
          ),
        );
      } catch (_) {
        // Timeout yoki boshqa xato — oxirgi ma'lum joylashuvni olish
        pos = await Geolocator.getLastKnownPosition();
      }
      if (pos == null) {
        setState(() { _locLoading = false; _locMsg = 'error'; });
        return;
      }
      setState(() {
        _lat = pos!.latitude;
        _lng = pos.longitude;
        _locLoading = false;
        _locDone = true;
        _locMsg = 'ok';
      });
    } catch (e) {
      setState(() { _locLoading = false; _locMsg = 'error'; });
    }
  }

  void _showGpsOffDialog() {
    final s = S(context.read<ThemeProvider>().language);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.location_off, color: Colors.red, size: 48),
        title: Text(s.gpsOff, textAlign: TextAlign.center),
        content: Text(
          s.gpsOff + " — " + s.gpsEnable.toLowerCase(),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s.cancel),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.settings, size: 18),
            label: Text(s.gpsEnable),
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openLocationSettings();
            },
          ),
        ],
      ),
    );
  }

  void _showPermDeniedDialog() {
    final s = S(context.read<ThemeProvider>().language);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.location_disabled, color: Colors.orange, size: 48),
        title: Text(s.permDeniedTitle, textAlign: TextAlign.center),
        content: Text(s.permDeniedMsg, textAlign: TextAlign.center),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s.cancel),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.settings, size: 18),
            label: Text(s.openSettings),
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openAppSettings();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _loadDiscountSettings() async {
    try {
      final settings = await context.read<ApiService>().getSettings();
      if (mounted) {
        setState(() {
          _discountEnabled = settings['discount_enabled'] == 1 || settings['discount_enabled'] == '1';
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
        // Group by service_id
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
            // Remove default empty piece and fill with saved pieces
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
    _advanceCtrl.dispose();
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

  // Global settings discounti
  double get _globalDiscount {
    if (!_discountEnabled || _discountMinSqm <= 0) return 0;
    if (_totalSqm < _discountMinSqm) return 0;

    // Foizli progressiv skidka (discount_percentage > 0 bo'lsa)
    if (_discountPct > 0 && _discountStepSqm > 0) {
      final steps = ((_totalSqm - _discountMinSqm) / _discountStepSqm).floor();
      final pct = (_discountPct * (1 << steps)).clamp(0.0, 100.0); // 2^steps
      return _rawTotal * pct / 100;
    }

    // Eski fixed amount
    return _discountAmt;
  }

  // Joriy skidka foizi (ko'rsatish uchun)
  double get _globalDiscountPct {
    if (!_discountEnabled || _discountMinSqm <= 0 || _discountPct <= 0) return 0;
    if (_totalSqm < _discountMinSqm) return 0;
    final steps = ((_totalSqm - _discountMinSqm) / _discountStepSqm).floor();
    return (_discountPct * (1 << steps)).clamp(0.0, 100.0);
  }

  // Per-service discountlar yig'indisi (belgilangan miqdordan oshsa bir marta foiz)
  double get _serviceDiscount {
    double t = 0;
    for (final svc in _services) {
      if (!svc.discountEnabled || svc.discountMinQty <= 0 || svc.discountAmount <= 0) continue;
      final e = _entries[svc.id];
      if (e == null || !e.enabled || !e.isValid) continue;
      final qty = e.qty(svc.unitType);
      if (qty < svc.discountMinQty) continue;
      t += e.calcTotal(svc.pricePerUnit) * svc.discountAmount / 100;
    }
    return t;
  }


  double get _discount => _globalDiscount + _serviceDiscount;

  double get _totalPrice => (_rawTotal - _discount).clamp(0, double.infinity);

  int get _filledCount =>
      _entries.values.where((e) => e.enabled && e.isValid).length;

  Future<void> _saveWithoutMeasurements() async {
    final s = S(context.read<ThemeProvider>().language);

    // GPS yo'q bo'lsa — avval olishga urinib ko'r
    if (!_locDone) {
      await _getLocation();
      if (!mounted) return;
    }

    final hasLoc = _locDone && _lat != null && _lng != null;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Icon(
          hasLoc ? Icons.schedule : Icons.location_off,
          color: hasLoc ? Colors.orange : Colors.red,
          size: 44,
        ),
        title: Text(s.measureAtHome, textAlign: TextAlign.center),
        content: Text(
          hasLoc
              ? s.measureAtHomeInfo
              : 'GPS manzil aniqlanmadi. Manzilsiz davom etasizmi? O\'lchamlarni keyinroq kiritishingiz mumkin.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(s.cancel)),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
                backgroundColor: hasLoc ? Colors.orange : Colors.red),
            child: Text(s.yes),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _saving = true);
    try {
      if (hasLoc) {
        final api = context.read<ApiService>();
        await api.savePickupLocation(widget.order.id, _lat!, _lng!);
      }
      final driverId = context.read<AuthProvider>().currentUser?.id;
      await context.read<OrderProvider>().updateOrderStatus(
        widget.order.id,
        OrderStatus.qabulQilindi,
        driverId: driverId,
      );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${s.pickedUpSuccess} ${s.measurePending}'),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) _snack('Xatolik: $e', error: true);
    }
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _save() async {
    final s = S(context.read<ThemeProvider>().language);

    // Majburiy location tekshiruv
    if (!_locDone || _lat == null || _lng == null) {
      _snack('Avval manzilni aniqlang!', error: true);
      _getLocation();
      return;
    }

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

      for (final s in validServices) {
        final e = _entries[s.id]!;
        if (s.unitType == UnitType.sqm) {
          for (final p in e.pieces) {
            if (!p.isValid) continue;
            items.add({
              'service_id': int.parse(s.id),
              'width': double.parse(p.widthCtrl.text.replaceAll(',', '.')),
              'height': double.parse(p.heightCtrl.text.replaceAll(',', '.')),
            });
          }
        } else if (s.unitType == UnitType.meter) {
          final pieceCount = int.tryParse(e.itemCountCtrl.text.trim()) ?? 0;
          items.add({
            'service_id': int.parse(s.id),
            'quantity': double.parse(e.countCtrl.text.replaceAll(',', '.')),
            if (pieceCount > 0) 'notes': '${pieceCount}ta',
          });
        } else {
          items.add({
            'service_id': int.parse(s.id),
            'quantity': int.parse(e.countCtrl.text.trim()),
          });
        }
      }

      final totalPrice = _totalPrice;
      final advanceAmount = double.tryParse(
          _advanceCtrl.text.replaceAll(' ', '').replaceAll(',', '.').trim()) ?? 0;

      final orderId = widget.order.id;

      // Location va items saqlash
      await api.savePickupLocation(orderId, _lat!, _lng!);
      await api.saveOrderItems(orderId, items);
      if (advanceAmount > 0) {
        // saveAdvancePayment provider orqali — offline-aware
        await context.read<OrderProvider>().saveAdvancePayment(orderId, advanceAmount);
      }
      final driverId = context.read<AuthProvider>().currentUser?.id;
      await context.read<OrderProvider>().updateOrderStatus(
        widget.order.id,
        OrderStatus.qabulQilindi,
        driverId: driverId,
      );

      if (mounted) {
        final s = S(context.read<ThemeProvider>().language);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${s.pickedUpSuccess}  ${_fmt.format(totalPrice)} so\'m'),
            backgroundColor: Color(OrderStatus.qabulQilindi.colorValue),
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
            Text(
              s.receiveItems,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
          : Column(
              children: [
                // Mijoz info
                Container(
                  margin: const EdgeInsets.fromLTRB(14, 0, 14, 0),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.order.customerName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: cs.onSurface,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              widget.order.address,
                              style: TextStyle(
                                fontSize: 12,
                                color: cs.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              formatPhone(widget.order.phone),
                              style: TextStyle(
                                fontSize: 12,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      CallButton(phone: widget.order.phone, mini: true),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Location holati
                GestureDetector(
                  onTap: _locLoading ? null : _getLocation,
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(14, 0, 14, 0),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    decoration: BoxDecoration(
                      color: _locDone
                          ? Colors.green.withValues(alpha: 0.1)
                          : _locLoading
                              ? Colors.blue.withValues(alpha: 0.07)
                              : Colors.red.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _locDone
                            ? Colors.green.withValues(alpha: 0.5)
                            : _locLoading
                                ? Colors.blue.withValues(alpha: 0.3)
                                : Colors.red.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                    ),
                    child: Row(children: [
                      _locLoading
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2.5))
                          : Icon(
                              _locDone ? Icons.location_on : Icons.location_off_outlined,
                              color: _locDone ? Colors.green : Colors.red,
                              size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _locLoading
                                  ? s.gpsDetecting
                                  : _locDone
                                      ? s.gpsDetected
                                      : _locMsg == 'gps_off'
                                          ? s.gpsOffTap
                                          : _locMsg == 'perm_denied'
                                              ? s.gpsPermDenied
                                              : s.gpsNotDetected,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _locDone
                                    ? Colors.green.shade700
                                    : _locLoading
                                        ? Colors.blue.shade700
                                        : Colors.red.shade700,
                              ),
                            ),
                            if (_locDone && _lat != null)
                              Text(
                                '${_lat!.toStringAsFixed(5)}, ${_lng!.toStringAsFixed(5)}',
                                style: TextStyle(fontSize: 11, color: Colors.green.shade600),
                              ),
                          ],
                        ),
                      ),
                      if (!_locDone && !_locLoading)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(s.gpsDetectBtn,
                              style: const TextStyle(color: Colors.white,
                                  fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                    ]),
                  ),
                ),
                const SizedBox(height: 8),

                // Services list + oldindan to'lov
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
                    itemCount: _services.length + 1,
                    itemBuilder: (ctx, i) {
                      // Oxirgi item — oldindan to'lov maydoni
                      if (i == _services.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 4, bottom: 8),
                          child: TextField(
                            controller: _advanceCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [ThousandsSeparatorInputFormatter()],
                            decoration: InputDecoration(
                              labelText: s.advancePaymentHint,
                              prefixIcon: const Icon(
                                  Icons.account_balance_wallet_outlined,
                                  color: Colors.orange),
                              suffixText: "so'm",
                              filled: true,
                              fillColor: isDark
                                  ? cs.surfaceContainerHighest
                                  : Colors.orange.withValues(alpha: 0.05),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.orange.shade300)),
                              enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.orange.shade300)),
                              focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Colors.orange, width: 2)),
                            ),
                          ),
                        );
                      }
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
                ),
              ],
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
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
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                          if (_discount > 0) ...[
                            Text(
                              '${s.subtotal}: ${_fmt.format(_rawTotal)} ${s.currency}',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12,
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
                child: _locLoading
                    ? FilledButton(
                        onPressed: null,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 52),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(width: 18, height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white)),
                            const SizedBox(width: 10),
                            Text(s.gpsDetecting),
                          ],
                        ),
                      )
                    : !_locDone
                        ? FilledButton.icon(
                            onPressed: _getLocation,
                            icon: const Icon(Icons.location_on),
                            label: Text(
                              s.gpsNotDetected.replaceAll(' — bosing', ''),
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.red,
                              minimumSize: const Size(0, 52),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                          )
                        : FilledButton(
                            onPressed: _saving ? null : _save,
                            style: FilledButton.styleFrom(
                              backgroundColor: Color(OrderStatus.yuvilyapti.colorValue),
                              minimumSize: const Size(0, 52),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                            child: _saving
                                ? const SizedBox(
                                    width: 22, height: 22,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white))
                                : Text(
                                    s.saveAndPickedUp,
                                    style: const TextStyle(
                                        fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                          ),
              ),
              if (!_saving && !_locLoading) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _saveWithoutMeasurements,
                    icon: const Icon(Icons.schedule, size: 18, color: Colors.orange),
                    label: Text(
                      s.measureAtHome,
                      style: const TextStyle(
                          color: Colors.orange,
                          fontSize: 14,
                          fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.orange),
                      minimumSize: const Size(0, 46),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
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
      case UnitType.sqm:    return 'm²';
      case UnitType.meter:  return 'm';
      case UnitType.piece:  return 'ta';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isSqm = service.unitType == UnitType.sqm;
    final isMeter = service.unitType == UnitType.meter;
    final valid = entry.enabled && entry.isValid;
    final currentQty = valid ? entry.qty(service.unitType) : 0.0;

    // Per-service foizli skidka hisoblash
    final hasDisc = service.discountEnabled && service.discountMinQty > 0 && service.discountAmount > 0;
    final discQualifies = hasDisc && currentQty >= service.discountMinQty;
    final discNearby = hasDisc && !discQualifies && currentQty > 0;
    final rawTotal = entry.enabled ? entry.calcTotal(service.pricePerUnit) : 0.0;
    final discPct = discQualifies ? service.discountAmount.clamp(0.0, 100.0) : 0.0;
    final discAmt = rawTotal * discPct / 100;
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
            // Header row
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
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        "${fmt.format(service.pricePerUnit)} so'm/${service.unitType.label}",
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                        ),
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
                          "${fmt.format(rawTotal)} so'm",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.red,
                            decoration: TextDecoration.lineThrough,
                            decorationColor: Colors.red,
                          ),
                        ),
                        Text(
                          "${fmt.format(total)} so'm",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ] else
                        Text(
                          "${fmt.format(total)} so'm",
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade300),
                  ),
                  child: Row(children: [
                    const Icon(Icons.discount, size: 14, color: Colors.orange),
                    const SizedBox(width: 6),
                    Text(
                      'Skidka: ${discPct.toStringAsFixed(0)}% (-${fmt.format(discAmt)} so\'m)',
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: cs.outlineVariant),
                  ),
                  child: Row(children: [
                    Icon(Icons.discount_outlined, size: 13, color: cs.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Expanded(child: Text(
                      '${fmt.format(service.discountMinQty)} ${_unitSuffix(service.unitType)} dan oshsa → ${service.discountAmount.toStringAsFixed(0)}% skidka (hozir: ${discQualifies ? "${service.discountAmount.toStringAsFixed(0)}%" : "hali yoq"})',
                      style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                    )),
                  ]),
                ),
            ],

            // Input section
            if (entry.enabled) ...[
              const SizedBox(height: 10),
              if (isSqm)
                _SqmInput(entry: entry, cs: cs, isDark: isDark, fmt: fmt, onChanged: onChanged)
              else if (isMeter)
                _MeterInput(entry: entry, isDark: isDark, onChanged: onChanged)
              else
                _PieceInput(entry: entry, cs: cs, isDark: isDark, onChanged: onChanged),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── sqm input: count → per-piece width×height ────────────────────────────────

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
    // Bo'sh yoki noto'g'ri qiymatda pieces'ga tegmaymiz
    if (n == null || n <= 0) { refresh(); return; }
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
        // Count input
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

        // Per-piece measurements
        if (entry.pieces.isNotEmpty) ...[
          const SizedBox(height: 10),
          ...entry.pieces.asMap().entries.map((e) {
            final i = e.key;
            final p = e.value;
            return _PieceRow(
              index: i,
              piece: p,
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
                color: cs.primary,
              ),
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
            child: Text(
              '×',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: cs.outline,
              ),
            ),
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
                color: Colors.blue.shade700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── meter (uzunlik) input ────────────────────────────────────────────────────

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
    final meters = double.tryParse(entry.countCtrl.text.replaceAll(',', '.').trim());
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: _NumField(
            ctrl: entry.itemCountCtrl,
            label: S(context.read<ThemeProvider>().language).howMany,
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
                color: cs.primary,
              ),
            ),
          ),
        ],
      ],
    );
  }
}


// ─── piece (dona) input ────────────────────────────────────────────────────────

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
        fillColor: isDark
            ? cs.surfaceContainerHighest
            : const Color(0xFFF5F7FA),
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
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
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
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
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
  final TextEditingController sizeCtrl = TextEditingController(); // piece uchun o'lcham (m)
  final TextEditingController itemCountCtrl = TextEditingController(); // meter uchun dona soni
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
        return _parseDecimal(countCtrl.text) != null;
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
