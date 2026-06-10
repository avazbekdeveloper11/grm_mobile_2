import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('FCM background: ${message.notification?.title}');
}

class FcmService {
  static final _fln = FlutterLocalNotificationsPlugin();
  static final _messaging = FirebaseMessaging.instance;

  static const _channel = AndroidNotificationChannel(
    'gilam_orders_v2',
    'Gilam buyurtmalari',
    description: 'Yangi buyurtma va yetkazish xabarlari',
    importance: Importance.high,
    playSound: true,
    sound: RawResourceAndroidNotificationSound('order_notification'),
  );

  static Future<void> init(ApiService api) async {
    try {
      // Ruxsat so'rash
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('FCM ruxsat: ${settings.authorizationStatus}');

      // Local notifications kanal
      await _fln
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(_channel);

      await _fln.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
      );

      // Background handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Foreground notification
      FirebaseMessaging.onMessage.listen((message) {
        final n = message.notification;
        if (n != null) {
          _fln.show(
            n.hashCode,
            n.title,
            n.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                _channel.id,
                _channel.name,
                channelDescription: _channel.description,
                importance: Importance.high,
                priority: Priority.high,
                icon: '@mipmap/ic_launcher',
                sound: const RawResourceAndroidNotificationSound('order_notification'),
                playSound: true,
              ),
            ),
          );
        }
      });

      // Token olish va saqlash
      await _refreshToken(api);
      _messaging.onTokenRefresh.listen((t) => _saveToken(api, t));
    } catch (e) {
      debugPrint('FCM init xatolik: $e');
    }
  }

  static Future<void> _refreshToken(ApiService api) async {
    // Release modeda token kech kelishi mumkin — 3 marta urinib ko'ramiz
    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        final token = await _messaging.getToken()
            .timeout(const Duration(seconds: 10));
        if (token != null) {
          debugPrint('FCM token (attempt $attempt): ${token.substring(0, 20)}...');
          await _saveToken(api, token);
          return;
        }
      } catch (e) {
        debugPrint('FCM getToken attempt $attempt xatolik: $e');
        if (attempt < 3) await Future.delayed(const Duration(seconds: 3));
      }
    }
  }

  static Future<void> _saveToken(ApiService api, String token) async {
    try {
      await api.saveFcmToken(token);
      debugPrint('FCM token backend ga saqlandi ✅');
    } catch (e) {
      debugPrint('FCM token saqlash xatolik: $e');
    }
  }

  static Future<void> clearToken(ApiService api) async {
    try {
      await _messaging.deleteToken();
    } catch (_) {}
  }
}
