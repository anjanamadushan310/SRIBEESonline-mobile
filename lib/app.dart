/// SRIBEESonline - Root Application Widget
///
/// Sets up MaterialApp with:
///   - Riverpod-driven locale from [languageProvider]
///   - A modern green-themed Material 3 design system
///   - [SplashScreen] as the initial route
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'config/app_config.dart';
import 'core/api/api_client.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/language_provider.dart';
import 'core/providers/notification_provider.dart';
import 'core/services/push_notification_service.dart';
import 'features/onboarding/screens/splash_screen.dart';

// ==========================================================================
// Root widget — inserted into runApp() by each main_*.dart entry point.
// ProviderScope is created in main so that SharedPreferences can be injected
// before the widget tree builds.
// ==========================================================================

class SRIBEESonlineApp extends ConsumerStatefulWidget {
  const SRIBEESonlineApp({super.key});

  @override
  ConsumerState<SRIBEESonlineApp> createState() => _SRIBEESonlineAppState();
}

class _SRIBEESonlineAppState extends ConsumerState<SRIBEESonlineApp> {
  @override
  void initState() {
    super.initState();
    // Set up FCM after the first frame: wire handlers, then push the token if
    // the user is already logged in (startup case).
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await PushNotificationService.instance.configure(
        api: ref.read(apiClientProvider),
        prefs: ref.read(sharedPrefsProvider),
        onForeground: _onForegroundMessage,
      );
      if (ref.read(isAuthenticatedProvider)) {
        await PushNotificationService.instance.syncToken();
      }
    });
  }

  /// Foreground push: refresh the unread badge and surface a snackbar.
  void _onForegroundMessage(RemoteMessage message) {
    // The unread count derives from this provider — invalidate to re-fetch.
    ref.invalidate(notificationsProvider);

    final n = message.notification;
    final title = n?.title ?? message.data['title']?.toString();
    final body = n?.body ?? message.data['message']?.toString();
    final text = [title, body].where((s) => s != null && s.isNotEmpty).join(' — ');
    if (text.isEmpty) return;

    pushScaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(languageProvider);
    // Framework (Material/Cupertino) only has delegates for a limited set of
    // locales. For si/ta we pass 'en' so framework widgets get English strings;
    // our app still uses languageProvider (si/ta/en) for custom copy.
    final resolvedLocale = _resolveFrameworkLocale(locale);

    // Register the FCM token whenever the user transitions into an
    // authenticated state (covers login after a fresh start).
    ref.listen<bool>(isAuthenticatedProvider, (prev, next) {
      if (next == true && prev != true) {
        PushNotificationService.instance.syncToken();
      }
    });

    return MaterialApp(
      title: AppConfig.instance.appName,
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: pushScaffoldMessengerKey,

      // ── Locale ──
      locale: resolvedLocale,
      supportedLocales: AppLocales.supported,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // ── Theme ──
      theme: _buildTheme(),

      // ── Entry screen ──
      home: const SplashScreen(),
    );
  }

  /// Use English for framework localizations when app locale is si/ta
  /// (Flutter does not ship Material/Cupertino translations for those).
  static Locale? _resolveFrameworkLocale(Locale? locale) {
    if (locale == null) return null;
    if (locale.languageCode == 'si' || locale.languageCode == 'ta') {
      return const Locale('en');
    }
    return locale;
  }

  // ========================================================================
  // Theme
  // ========================================================================
  ThemeData _buildTheme() {
    const primaryGreen = Color(0xFF2E7D32);
    const seedColor = primaryGreen;

    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
      primary: primaryGreen,
      secondary: const Color(0xFFFFA726),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,

      // Scaffold
      scaffoldBackgroundColor: Colors.white,

      // AppBar
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),

      // Elevated buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),

      // Outlined buttons
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryGreen,
          minimumSize: const Size(double.infinity, 54),
          side: const BorderSide(color: primaryGreen, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),

      // Cards
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: const Color(0xFFF5F5F5),
      ),

      // Input fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
