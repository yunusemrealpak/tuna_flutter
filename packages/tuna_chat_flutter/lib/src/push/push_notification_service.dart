import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:tuna_chat/tuna_chat.dart';

/// Integrates Firebase Cloud Messaging with the TunaChat device token API.
///
/// Usage (call after `TunaChatSDK.init()` and `Firebase.initializeApp()`):
/// ```dart
/// await PushNotificationService.initialize(
///   deviceRepository: sl<DeviceRepository>(),
///   onChannelTap: (channelId) => navigatorKey.currentState?.push(...),
/// );
/// ```
///
/// **Platform setup required by the host app:**
/// - Android: `google-services.json` in `android/app/`
/// - iOS: `GoogleService-Info.plist` in `ios/Runner/`, APNs key in FCM console
class PushNotificationService {
  PushNotificationService._();

  static Future<void> initialize({
    required DeviceRepository deviceRepository,
    void Function(String channelId)? onChannelTap,
  }) async {
    final messaging = FirebaseMessaging.instance;

    // Request permission (required on iOS, optional prompt on Android 13+).
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Register current token with TunaChat backend.
    final token = await messaging.getToken();
    if (token != null) {
      await _registerToken(deviceRepository, token);
    }

    // Re-register when token rotates (FCM can rotate tokens).
    messaging.onTokenRefresh.listen((newToken) {
      _registerToken(deviceRepository, newToken);
    });

    // Foreground message handler — app is open and in foreground.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // Foreground push: the host app can listen here to show an in-app banner.
      // The SDK does not render UI directly; navigation is handled via onChannelTap.
    });

    // Background / terminated tap — user tapped the notification.
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final channelId = message.data['channel_id'] as String?;
      if (channelId != null && onChannelTap != null) {
        onChannelTap(channelId);
      }
    });

    // App opened from terminated state via notification tap.
    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      final channelId = initialMessage.data['channel_id'] as String?;
      if (channelId != null && onChannelTap != null) {
        onChannelTap(channelId);
      }
    }
  }

  static Future<void> _registerToken(
    DeviceRepository repository,
    String token,
  ) async {
    final platform = Platform.isIOS ? 'ios' : 'android';
    final provider = Platform.isIOS ? 'apns' : 'fcm';
    await repository.registerToken(
      token: token,
      platform: platform,
      pushProvider: provider,
    );
  }

  /// Deregisters the current device token (e.g. on logout).
  static Future<void> deregister(DeviceRepository repository) async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await repository.deregisterToken(token);
    }
  }
}
