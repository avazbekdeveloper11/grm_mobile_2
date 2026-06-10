import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

final _coordPattern = RegExp(
  r'^\s*(-?\d{1,3}(?:\.\d+)?)\s*,\s*(-?\d{1,3}(?:\.\d+)?)\s*$',
);

/// "39.77261, 67.02908" kabi manzil matnidan koordinatalarni ajratib oladi.
({double lat, double lng})? coordsFromAddress(String address) {
  final match = _coordPattern.firstMatch(address);
  if (match == null) return null;
  final lat = double.tryParse(match.group(1)!);
  final lng = double.tryParse(match.group(2)!);
  if (lat == null || lng == null) return null;
  if (lat < -90 || lat > 90 || lng < -180 || lng > 180) return null;
  return (lat: lat, lng: lng);
}

final _addressCache = <String, String?>{};

/// Koordinatadan qisqa, aniq joy nomini olish (OpenStreetMap Nominatim).
/// Masalan: "Зарафшон тракти, Югантепа, Жўрабекободдан, Жомбой..." emas, balki shunchaki "Juriyat".
/// Natija keshlanadi, xatolik bo'lsa null qaytaradi.
Future<String?> reverseGeocode(double lat, double lng) async {
  final key = '${lat.toStringAsFixed(5)},${lng.toStringAsFixed(5)}';
  if (_addressCache.containsKey(key)) return _addressCache[key];
  try {
    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&accept-language=uz&addressdetails=1&zoom=14',
    );
    final res = await http
        .get(uri, headers: {'User-Agent': 'GilamYuvishApp/1.0'})
        .timeout(const Duration(seconds: 8));
    if (res.statusCode != 200) {
      _addressCache[key] = null;
      return null;
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final addr = data['address'] as Map<String, dynamic>?;
    String? short;
    if (addr != null) {
      for (final field in [
        'village', 'town', 'city', 'suburb', 'neighbourhood',
        'hamlet', 'municipality', 'city_district', 'county',
      ]) {
        final v = (addr[field] as String?)?.trim();
        if (v != null && v.isNotEmpty) { short = v; break; }
      }
    }
    short ??= (data['display_name'] as String?)?.split(',').first.trim();
    _addressCache[key] = (short != null && short.isNotEmpty) ? short : null;
    return _addressCache[key];
  } catch (_) {
    _addressCache[key] = null;
    return null;
  }
}

Future<void> openInMaps(double lat, double lng) async {
  final geoUri = Uri.parse('geo:$lat,$lng?q=$lat,$lng');
  if (await canLaunchUrl(geoUri)) {
    await launchUrl(geoUri);
    return;
  }
  final webUri = Uri.parse('https://maps.google.com/?q=$lat,$lng');
  await launchUrl(webUri, mode: LaunchMode.externalApplication);
}
