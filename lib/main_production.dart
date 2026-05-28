/// SRIBEESonline Flutter App - Main Entry Point
///
/// Production environment entry point.
/// Use: flutter run --release --target lib/main_production.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config/app_config.dart';
import 'config/sentry_service.dart';
import 'config/firebase_service.dart';
import 'core/providers/language_provider.dart';
import 'app.dart';

void main() async {
  // Initialize app configuration for production
  AppConfig.initialize(Environment.production);

  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // Initialize Firebase
  await FirebaseService.initialize();

  // Initialize Sentry with app runner
  await SentryService.initialize(
    appRunner: () => runApp(
      ProviderScope(
        overrides: [
          sharedPrefsProvider.overrideWithValue(prefs),
        ],
        child: const SRIBEESonlineApp(),
      ),
    ),
  );
}
