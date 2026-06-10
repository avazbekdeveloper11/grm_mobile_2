import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../utils/latin_to_cyrillic.dart';
import '../utils/map_utils.dart';

/// Koordinataga asoslangan manzilni qisqa, o'qiladigan joy nomiga aylantirib
/// ko'rsatadi (mas. "Juriyat"). Hal qilinmaguncha yoki xato bo'lsa `fallback`
/// matnini ko'rsatadi.
class ResolvedAddressText extends StatefulWidget {
  final double lat;
  final double lng;
  final String fallback;
  final TextStyle? style;
  final int? maxLines;

  const ResolvedAddressText({
    super.key,
    required this.lat,
    required this.lng,
    required this.fallback,
    this.style,
    this.maxLines,
  });

  @override
  State<ResolvedAddressText> createState() => _ResolvedAddressTextState();
}

class _ResolvedAddressTextState extends State<ResolvedAddressText> {
  String? _address;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(covariant ResolvedAddressText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lat != widget.lat || oldWidget.lng != widget.lng) {
      _address = null;
      _resolve();
    }
  }

  Future<void> _resolve() async {
    final currentRequest = ++_requestId;
    final lat = widget.lat;
    final lng = widget.lng;
    final address = await reverseGeocode(lat, lng);
    if (mounted && currentRequest == _requestId) {
      setState(() => _address = address);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCyr = context.watch<ThemeProvider>().language == AppLanguage.uzCyrillic;
    final text = _address ?? widget.fallback;
    return Text(
      isCyr ? latinToCyrillic(text) : text,
      style: widget.style ?? const TextStyle(fontWeight: FontWeight.w500),
      maxLines: widget.maxLines,
      overflow: widget.maxLines != null ? TextOverflow.ellipsis : null,
    );
  }
}
