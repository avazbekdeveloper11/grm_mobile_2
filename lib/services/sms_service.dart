import 'package:telephony/telephony.dart';

class SmsService {
  static final _telephony = Telephony.instance;

  /// Gilam tayyor bo'lganda mijozga SMS yuborish.
  /// [phone] - mijoz telefon raqami
  /// [customerName] - mijoz ismi
  /// Ruxsat so'ralmagan bo'lsa, avval so'raydi.
  static Future<SmsResult> sendReadyNotification({
    required String phone, 
  }) async {
    final permitted = await _telephony.requestPhoneAndSmsPermissions;
    if (permitted != true) {
      return SmsResult.permissionDenied;
    }

    final normalized = _normalizePhone(phone);
    final message =
        'Gilamingiz yuvib tayyor bo\'ldi! '
        'Yetkazib berish uchun siz bilan bog\'lanamiz. '
        'Gilam tozalash xizmati.';

    try {
      await _telephony.sendSms(
        to: normalized,
        message: message,
        isMultipart: true,
      );
      return SmsResult.sent;
    } catch (e) {
      return SmsResult.failed;
    }
  }

  static String _normalizePhone(String phone) {
    // Remove spaces, dashes, parentheses
    String n = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    // Ensure starts with +998 or 998
    if (n.startsWith('0')) n = '998${n.substring(1)}';
    if (!n.startsWith('+')) n = '+$n';
    return n;
  }
}

enum SmsResult { sent, failed, permissionDenied }
