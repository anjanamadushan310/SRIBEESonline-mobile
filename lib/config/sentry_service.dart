/// SRIBEESonline Flutter App - Sentry Integration
/// 
/// Error tracking and performance monitoring using Sentry.
/// Initialize in main.dart before runApp().

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'app_config.dart';

class SentryService {
  static bool _isInitialized = false;
  
  /// Initialize Sentry with app configuration
  /// Call this in main() before runApp()
  static Future<void> initialize({
    required Function() appRunner,
  }) async {
    final dsn = AppConfig.instance.sentryDsn;
    
    // Skip Sentry in development or if DSN not configured
    if (dsn.isEmpty || AppConfig.isDevelopment) {
      if (kDebugMode) {
        print('Sentry: Skipping initialization (development mode or no DSN)');
      }
      appRunner();
      return;
    }
    
    await SentryFlutter.init(
      (options) {
        options.dsn = dsn;
        options.environment = AppConfig.environment.name;
        options.release = 'sribeesonline-mobile@1.0.0';
        
        // Performance monitoring
        options.tracesSampleRate = AppConfig.instance.sentryTracesSampleRate;
        
        // Only capture errors in release mode
        options.debug = kDebugMode;
        
        // Capture unhandled errors
        options.attachStacktrace = true;
        
        // Privacy: don't send user PII by default
        options.sendDefaultPii = false;
        
        // Before sending hook for filtering
        options.beforeSend = (event, hint) {
          // Filter out development errors if needed
          if (AppConfig.isDevelopment) {
            return null; // Don't send in development
          }
          return event;
        };
      },
      appRunner: appRunner,
    );
    
    _isInitialized = true;
    if (kDebugMode) {
      print('Sentry: Initialized for ${AppConfig.environment.name}');
    }
  }
  
  /// Capture exception with optional context
  static void captureException(
    dynamic exception, {
    StackTrace? stackTrace,
    Map<String, dynamic>? extra,
  }) {
    if (!_isInitialized) return;
    
    Sentry.captureException(
      exception,
      stackTrace: stackTrace,
      withScope: extra != null
          ? (scope) {
              extra.forEach((key, value) {
                scope.setExtra(key, value);
              });
            }
          : null,
    );
  }
  
  /// Capture message for non-error logging
  static void captureMessage(
    String message, {
    SentryLevel level = SentryLevel.info,
    Map<String, dynamic>? extra,
  }) {
    if (!_isInitialized) return;
    
    Sentry.captureMessage(
      message,
      level: level,
      withScope: extra != null
          ? (scope) {
              extra.forEach((key, value) {
                scope.setExtra(key, value);
              });
            }
          : null,
    );
  }
  
  /// Set user context for error tracking
  static void setUser({
    required String id,
    String? email,
    String? username,
  }) {
    if (!_isInitialized) return;
    
    Sentry.configureScope((scope) {
      scope.setUser(SentryUser(
        id: id,
        email: email,
        username: username,
      ));
    });
  }
  
  /// Clear user context on logout
  static void clearUser() {
    if (!_isInitialized) return;
    
    Sentry.configureScope((scope) {
      scope.setUser(null);
    });
  }
  
  /// Add breadcrumb for navigation/action tracking
  static void addBreadcrumb({
    required String message,
    String? category,
    Map<String, dynamic>? data,
  }) {
    if (!_isInitialized) return;
    
    Sentry.addBreadcrumb(Breadcrumb(
      message: message,
      category: category,
      data: data,
      timestamp: DateTime.now(),
    ));
  }
}
