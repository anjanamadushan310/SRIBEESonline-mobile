/// SRIBEESonline Flutter App - Firebase Service
///
/// Initializes Firebase for Auth (phone), Analytics, Crashlytics.
/// Requires google-services.json (Android) / GoogleService-Info.plist (iOS).

import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';

class FirebaseService {
  static bool _isInitialized = false;

  static bool get isInitialized => _isInitialized;

  /// Initialize Firebase. Call from main before runApp.
  /// In debug/development, if config is missing (no google-services.json),
  /// initialization is skipped and the app continues without Firebase.
  static Future<void> initialize({bool optional = false}) async {
    if (_isInitialized) return;
    try {
      await Firebase.initializeApp();
      _isInitialized = true;
      if (kDebugMode) {
        print('Firebase: Initialized');
      }
    } catch (e, st) {
      if (kDebugMode) {
        print('Firebase: Init failed — $e');
        print(st);
      }
      if (optional) {
        if (kDebugMode) {
          print('Firebase: Continuing without Firebase (optional init).');
        }
        return;
      }
      rethrow;
    }
  }

  /// Log custom event (no-op)
  static Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {}

  /// Log screen view (no-op)
  static Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {}

  /// Log add to cart (no-op)
  static Future<void> logAddToCart({
    required String itemId,
    required String itemName,
    required double price,
    int quantity = 1,
    String? currency = 'LKR',
  }) async {}

  /// Log purchase (no-op)
  static Future<void> logPurchase({
    required String transactionId,
    required double value,
    required List<Map<String, dynamic>> items,
    String? currency = 'LKR',
  }) async {}

  /// Set user properties (no-op)
  static Future<void> setUserProperties({
    required String userId,
    String? userType,
  }) async {}

  /// Clear user on logout (no-op)
  static Future<void> clearUser() async {}

  /// Log custom error (no-op)
  static Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    bool fatal = false,
  }) async {}

  /// Set Crashlytics user identifier (no-op)
  static Future<void> setCrashlyticsUser(String userId) async {}

  /// Add custom key (no-op)
  static Future<void> setCustomKey(String key, dynamic value) async {}
}
