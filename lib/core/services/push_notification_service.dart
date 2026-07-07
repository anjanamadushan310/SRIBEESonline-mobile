/// SRIBEESonline - Push Notification Service (FCM)
///
/// Wraps firebase_messaging:
///   - requests notification permission,
///   - retrieves the FCM device token and registers it with the backend
///     (POST /api/v1/notifications/push/token),
///   - re-registers automatically when the token rotates,
///   - forwards foreground messages to a callback (snackbar + unread badge).
///
/// All Firebase calls are guarded on [FirebaseService.isInitialized] so the app
/// degrades gracefully when Firebase config (google-services.json etc.) is
/// absent — nothing here throws on a device without Firebase set up.
library;

import 'dart:io' show Platform;
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/firebase_service.dart';
import '../api/api_client.dart';

/// Global key so the foreground handler can surface a snackbar from anywhere.
/// Wired into MaterialApp.scaffoldMessengerKey in app.dart.
final GlobalKey<ScaffoldMessengerState> pushScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  ApiClient? _api;
  SharedPreferences? _prefs;
  bool _listenersReady = false;

  /// Call once at startup (after Firebase init). Requests permission and wires
  /// the foreground + token-refresh handlers. Safe (no-op) without Firebase.
  Future<void> configure({
    required ApiClient api,
    required SharedPreferences prefs,
    required void Function(RemoteMessage message) onForeground,
  }) async {
    _api = api;
    _prefs = prefs;

    if (!FirebaseService.isInitialized || _listenersReady) return;
    _listenersReady = true;

    try {
      await _messaging.requestPermission(alert: true, badge: true, sound: true);
      // Show heads-up notifications while the app is in the foreground (iOS).
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      FirebaseMessaging.onMessage.listen(onForeground);
      _messaging.onTokenRefresh.listen(_registerToken);
    } catch (e) {
      if (kDebugMode) debugPrint('Push: configure failed — $e');
    }
  }

  /// Fetch the current FCM token and register it with the backend. Call after a
  /// successful login and on startup when the user is already authenticated.
  Future<void> syncToken() async {
    if (!FirebaseService.isInitialized) return;
    try {
      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) return;
      await _registerToken(token);
    } catch (e) {
      if (kDebugMode) debugPrint('Push: syncToken failed — $e');
    }
  }

  Future<void> _registerToken(String token) async {
    final api = _api;
    if (api == null) return;
    try {
      await api.post<Map<String, dynamic>>(
        '/notifications/push/token',
        data: {
          'token': token,
          'platform': _platform(),
          'device_id': _deviceId(),
        },
      );
      if (kDebugMode) debugPrint('Push: token registered with backend');
    } catch (e) {
      // Best-effort: a failed registration must never disrupt the app.
      if (kDebugMode) debugPrint('Push: token register failed — $e');
    }
  }

  String _platform() => Platform.isIOS ? 'ios' : 'android';

  /// A stable per-install device id, persisted in SharedPreferences so a
  /// rotated FCM token updates this device's row instead of orphaning it.
  String? _deviceId() {
    final prefs = _prefs;
    if (prefs == null) return null;
    const key = 'fcm_device_id';
    var id = prefs.getString(key);
    if (id == null || id.isEmpty) {
      id = 'dev_${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(1 << 31)}';
      prefs.setString(key, id);
    }
    return id;
  }
}
