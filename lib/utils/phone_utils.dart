import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// +998 93 444 56 64 formatiga o'tkazadi
String formatPhone(String raw) {
  // Faqat raqamlar
  String digits = raw.replaceAll(RegExp(r'\D'), '');

  // 998 bilan boshlanmasa qo'shamiz
  if (digits.startsWith('998')) {
    digits = digits.substring(3);
  } else if (digits.startsWith('8') && digits.length >= 9) {
    digits = digits.substring(1);
  } else if (digits.startsWith('0') && digits.length >= 9) {
    digits = digits.substring(1);
  }

  // 9 ta raqam: operator(2) + 7 ta raqam
  if (digits.length > 9) digits = digits.substring(0, 9);

  final buf = StringBuffer('+998 ');
  for (int i = 0; i < digits.length; i++) {
    if (i == 2 || i == 5 || i == 7) buf.write(' ');
    buf.write(digits[i]);
  }
  return buf.toString().trimRight();
}

/// Faqat raqamlarni qaytaradi: +998XXXXXXXXX
String rawPhone(String formatted) {
  final digits = formatted.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('998') && digits.length == 12) return '+$digits';
  if (digits.length == 9) return '+998$digits';
  return '+$digits';
}

/// Qo'ng'iroq qilish
Future<void> callPhone(String phone) async {
  final uri = Uri(scheme: 'tel', path: rawPhone(phone));
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

/// Minglik ajratuvchi formatter: 2000000 → "2 000 000"
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue old,
    TextEditingValue value,
  ) {
    final digits = value.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }
    final buf = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buf.write(' ');
      buf.write(digits[i]);
    }
    final result = buf.toString();
    return TextEditingValue(
      text: result,
      selection: TextSelection.collapsed(offset: result.length),
    );
  }
}

/// O'chirish uchun TextInputFormatter
class PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue old,
    TextEditingValue value,
  ) {
    final digits = value.text.replaceAll(RegExp(r'\D'), '');
    String clean = digits;
    if (clean.startsWith('998')) {
      clean = clean.substring(3);
    } else if (clean.startsWith('8')) {
      clean = clean.substring(1);
    } else if (clean.startsWith('0')) {
      clean = clean.substring(1);
    }
    if (clean.length > 9) clean = clean.substring(0, 9);

    final buf = StringBuffer('+998 ');
    for (int i = 0; i < clean.length; i++) {
      if (i == 2 || i == 5 || i == 7) buf.write(' ');
      buf.write(clean[i]);
    }
    final result = buf.toString().trimRight();
    return TextEditingValue(
      text: result,
      selection: TextSelection.collapsed(offset: result.length),
    );
  }
}
