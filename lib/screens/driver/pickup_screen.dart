// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/strings.dart';
import '../../models/order_model.dart';
import '../../providers/order_provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/order_number.dart';
import '../../utils/phone_utils.dart';
import '../../widgets/call_button.dart';

class PickupScreen extends StatefulWidget {
  final OrderModel order;
  const PickupScreen({super.key, required this.order});

  @override
  State<PickupScreen> createState() => _PickupScreenState();
}

class _PickupScreenState extends State<PickupScreen> {
  int _count = 1;
  late List<TextEditingController> _w, _h;
  final double _ppm = 15000; // price per m²
  bool _saving = false;

  // Location
  double? _lat, _lng;
  bool _locLoading = false;
  bool _locDone = false;
  String _locMsg = '';

  @override
  void initState() {
    super.initState();
    final ex = widget.order.carpets;
    _count = (ex != null && ex.isNotEmpty) ? ex.length : 1;
    _initCtrls(_count);
    if (ex != null) {
      for (int i = 0; i < ex.length && i < _count; i++) {
        _w[i].text = ex[i].width.toString();
        _h[i].text = ex[i].height.toString();
      }
    }
    if (widget.order.pickupLat != null) {
      _lat = widget.order.pickupLat;
      _lng = widget.order.pickupLng;
      _locDone = true;
      _locMsg = 'Manzil saqlangan';
    }
    _getLocation();
  }

  void _initCtrls(int n) {
    _w = List.generate(n, (_) => TextEditingController());
    _h = List.generate(n, (_) => TextEditingController());
  }

  void _setCount(int n) {
    if (n < 1 || n > 50) return;
    final ow = _w.map((c) => c.text).toList();
    final oh = _h.map((c) => c.text).toList();
    final old = _count;
    for (final c in _w) {
      c.dispose();
    }
    for (final c in _h) {
      c.dispose();
    }
    _w = List.generate(n, (i) => TextEditingController()..text = i < old ? ow[i] : '');
    _h = List.generate(n, (i) => TextEditingController()..text = i < old ? oh[i] : '');
    setState(() => _count = n);
  }

  @override
  void dispose() {
    for (final c in _w) {
      c.dispose();
    }
    for (final c in _h) {
      c.dispose();
    }
    super.dispose();
  }

  double? _p(TextEditingController c) {
    final v = double.tryParse(c.text.replaceAll(',', '.').trim());
    return (v != null && v > 0) ? v : null;
  }

  double get _totalArea {
    double t = 0;
    for (int i = 0; i < _count; i++) {
      final w = _p(_w[i]), h = _p(_h[i]);
      if (w != null && h != null) t += w * h;
    }
    return t;
  }

  int get _filled {
    int n = 0;
    for (int i = 0; i < _count; i++) {
      if (_p(_w[i]) != null && _p(_h[i]) != null) n++;
    }
    return n;
  }

  Future<void> _getLocation() async {
    setState(() { _locLoading = true; _locMsg = 'Aniqlanmoqda...'; });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        setState(() { _locLoading = false; _locMsg = "GPS o'chirilgan"; });
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        setState(() { _locLoading = false; _locMsg = 'Ruxsat berilmagan'; });
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 10)));
      setState(() {
        _lat = pos.latitude; _lng = pos.longitude;
        _locLoading = false; _locDone = true; _locMsg = 'Manzil aniqlandi';
      });
    } catch (_) {
      setState(() { _locLoading = false; _locMsg = 'Aniqlanmadi'; });
    }
  }

  Future<void> _save() async {
    final ms = <Map<String, double>>[];
    for (int i = 0; i < _count; i++) {
      final w = _p(_w[i]), h = _p(_h[i]);
      if (w != null && h != null) ms.add({'width': w, 'height': h});
    }
    if (ms.isEmpty) {
      final s = S(context.read<ThemeProvider>().language);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(s.minOneCarpetSize),
          backgroundColor: Colors.red));
      return;
    }
    setState(() => _saving = true);
    try {
      final provider = context.read<OrderProvider>();
      await provider.addCarpetMeasurements(widget.order.id, ms, lat: _lat, lng: _lng);
      await provider.updateOrderStatus(widget.order.id, OrderStatus.yuvilyapti);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('✓ Olib kelindi! ${ms.length} ta gilam  •  '
              '${_totalArea.toStringAsFixed(2)} m²  •  '
              "${NumberFormat('#,###').format(_totalArea * _ppm)} so'm"),
          backgroundColor: Color(OrderStatus.yuvilyapti.colorValue),
        ));
      }
    } catch (e) {
      if (mounted) {
        final s = S(context.read<ThemeProvider>().language);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${s.error}: $e'), backgroundColor: Colors.red));
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final s = S(context.read<ThemeProvider>().language);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fmt = NumberFormat('#,###');
    final area = _totalArea;
    final filled = _filled;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: cs.surfaceContainerLowest,
        title: Column(children: [
          Text(s.receiveCarpets,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text(orderNumber(widget.order.id),
              style: TextStyle(fontSize: 12, color: cs.primary, fontWeight: FontWeight.bold)),
        ]),
        centerTitle: true,
      ),

      body: Column(
        children: [
          // ─── Mijoz info strip ──────────────────────────────────────────
          Container(
            margin: const EdgeInsets.fromLTRB(14, 0, 14, 0),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.order.customerName,
                    style: TextStyle(fontWeight: FontWeight.bold,
                        color: cs.onSurface, fontSize: 15)),
                Text(widget.order.address,
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(formatPhone(widget.order.phone),
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
              ])),
              CallButton(phone: widget.order.phone, mini: true),
              const SizedBox(width: 6),
              // Location indicator
              GestureDetector(
                onTap: _locLoading ? null : (_locDone ? () => _openMap() : _getLocation),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _locDone ? Colors.green : cs.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _locLoading
                      ? const SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Icon(_locDone ? Icons.location_on : Icons.location_off_outlined,
                          color: _locDone ? Colors.white : cs.onSurfaceVariant, size: 20),
                ),
              ),
            ]),
          ),

          const SizedBox(height: 12),

          // ─── Gilam soni ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: _CountSelector(
              count: _count,
              onChanged: _setCount,
              isDark: isDark,
            ),
          ),

          const SizedBox(height: 10),

          // ─── Carpet cards (scrollable) ─────────────────────────────────
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
              itemCount: _count,
              itemBuilder: (ctx, i) => _CarpetCard(
                index: i,
                wCtrl: _w[i],
                hCtrl: _h[i],
                ppm: _ppm,
                onChanged: () => setState(() {}),
                isDark: isDark,
              ),
            ),
          ),
        ],
      ),

      // ─── Bottom bar ────────────────────────────────────────────────────
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
          decoration: BoxDecoration(
            color: isDark ? cs.surfaceContainerHigh : Colors.white,
            border: Border(top: BorderSide(color: cs.outlineVariant)),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Total strip
            if (area > 0) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade600, Colors.green.shade400],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('$filled / $_count gilam',
                        style: const TextStyle(color: Colors.white70, fontSize: 11)),
                    Text('${area.toStringAsFixed(2)} m²',
                        style: const TextStyle(color: Colors.white,
                            fontWeight: FontWeight.bold, fontSize: 18)),
                  ]),
                  const Spacer(),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(s.totalPrice,
                        style: const TextStyle(color: Colors.white70, fontSize: 11)),
                    Text("${fmt.format(area * _ppm)} so'm",
                        style: const TextStyle(color: Colors.white,
                            fontWeight: FontWeight.bold, fontSize: 18)),
                  ]),
                ]),
              ),
            ],

            // Save button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 54),
                  backgroundColor: Color(OrderStatus.yuvilyapti.colorValue),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _saving
                    ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.check_circle_outline, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          filled < _count && filled > 0
                              ? "Saqlash va Olib kelindi ($filled/$_count)"
                              : "Saqlash va Olib kelindi",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void _openMap() async {
    if (_lat == null) return;
    final geoUri = Uri.parse('geo:$_lat,$_lng?q=$_lat,$_lng');
    if (await canLaunchUrl(geoUri)) {
      await launchUrl(geoUri);
      return;
    }
    final webUri = Uri.parse('https://maps.google.com/?q=$_lat,$_lng');
    await launchUrl(webUri, mode: LaunchMode.externalApplication);
  }
}

// ─── Count selector ────────────────────────────────────────────────────────────

class _CountSelector extends StatelessWidget {
  final int count;
  final ValueChanged<int> onChanged;
  final bool isDark;

  const _CountSelector({required this.count, required this.onChanged, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? cs.surfaceContainerHigh : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.layers_outlined, size: 16, color: cs.primary),
          const SizedBox(width: 6),
          Text(S(context.read<ThemeProvider>().language).howManyCarpets,
              style: TextStyle(fontWeight: FontWeight.bold, color: cs.primary, fontSize: 14)),
        ]),
        const SizedBox(height: 12),
        // Quick chips 1–20 + custom (50 gacha)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            // Quick numbers 1–20
            ...List.generate(20, (i) => i + 1).map((n) => Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                onTap: () => onChanged(n),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: count == n ? cs.primary : cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: count == n ? cs.primary : cs.outlineVariant,
                      width: count == n ? 2 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text('$n',
                        style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold,
                          color: count == n ? cs.onPrimary : cs.onSurface,
                        )),
                  ),
                ),
              ),
            )),
            // Custom button for 21–50
            GestureDetector(
              onTap: () => _showCustomInput(context),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: count > 20 ? 60 : 44, height: 42,
                decoration: BoxDecoration(
                  color: count > 20 ? cs.primary : cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: count > 20 ? cs.primary : cs.outlineVariant,
                    width: count > 20 ? 2 : 1,
                  ),
                ),
                child: Center(
                  child: Text(count > 20 ? '$count' : '+',
                      style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold,
                        color: count > 20 ? cs.onPrimary : cs.onSurface,
                      )),
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  void _showCustomInput(BuildContext context) {
    final ctrl = TextEditingController(text: count > 20 ? '$count' : '');
    final s = S(context.read<ThemeProvider>().language);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(s.carpetCountTitle),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(suffixText: s.pieceCounter, labelText: s.enterCountLabel),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(s.bekor)),
          FilledButton(
            onPressed: () {
              final n = int.tryParse(ctrl.text.trim());
              if (n != null && n >= 1 && n <= 50) {
                onChanged(n);
                Navigator.pop(ctx);
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

// ─── Carpet card ───────────────────────────────────────────────────────────────

class _CarpetCard extends StatelessWidget {
  final int index;
  final TextEditingController wCtrl, hCtrl;
  final double ppm;
  final VoidCallback onChanged;
  final bool isDark;

  const _CarpetCard({
    required this.index,
    required this.wCtrl,
    required this.hCtrl,
    required this.ppm,
    required this.onChanged,
    required this.isDark,
  });

  double? _p(TextEditingController c) {
    final v = double.tryParse(c.text.replaceAll(',', '.').trim());
    return (v != null && v > 0) ? v : null;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = S(context.watch<ThemeProvider>().language);
    final w = _p(wCtrl), h = _p(hCtrl);
    final area = (w != null && h != null) ? w * h : null;
    final done = area != null;
    final fmt = NumberFormat('#,###');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: done
            ? Colors.green.withValues(alpha: isDark ? 0.12 : 0.06)
            : (isDark ? cs.surfaceContainerHigh : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: done ? Colors.green.withValues(alpha: 0.5) : cs.outlineVariant,
          width: done ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(children: [
          // Header
          Row(children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: done ? Colors.green : cs.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text('${index + 1}',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold,
                        color: done ? Colors.white : cs.onPrimaryContainer)),
              ),
            ),
            const SizedBox(width: 10),
            Text('${index + 1}-${s.carpet.toLowerCase()}',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            const Spacer(),
            if (done) ...[
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('${area.toStringAsFixed(2)} m²',
                    style: TextStyle(fontWeight: FontWeight.bold,
                        color: Colors.green.shade700, fontSize: 14)),
                Text("${fmt.format(area * ppm)} so'm",
                    style: TextStyle(fontSize: 12, color: Colors.green.shade600)),
              ]),
            ] else
              Text(s.enterSizeLabel,
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          ]),

          const SizedBox(height: 12),

          // Input row — big, finger-friendly
          Row(children: [
            Expanded(
              child: _BigField(ctrl: wCtrl, label: s.widthLabel, suffix: 'm',
                  onChanged: onChanged, isDark: isDark),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('×',
                  style: TextStyle(fontSize: 26, color: cs.outline,
                      fontWeight: FontWeight.w300)),
            ),
            Expanded(
              child: _BigField(ctrl: hCtrl, label: s.heightLabel, suffix: 'm',
                  onChanged: onChanged, isDark: isDark),
            ),
          ]),
        ]),
      ),
    );
  }
}

class _BigField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label, suffix;
  final VoidCallback onChanged;
  final bool isDark;

  const _BigField({
    required this.ctrl, required this.label, required this.suffix,
    required this.onChanged, required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TextField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        filled: true,
        fillColor: isDark ? cs.surfaceContainerHighest : const Color(0xFFF5F7FA),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      ),
      onChanged: (_) => onChanged(),
    );
  }
}
