/// SRIBEESonline Flutter App - Main Entry Point
///
/// Development environment entry point.
/// Use this for local development with hot reload.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config/app_config.dart';
import 'config/sentry_service.dart';
import 'config/firebase_service.dart';
import 'core/providers/language_provider.dart';
import 'app.dart';

void main() async {
  // Initialize app configuration for development
  AppConfig.initialize(Environment.development);

  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences (needed before the widget tree builds
  // so providers can read persisted language & branch selections).
  final prefs = await SharedPreferences.getInstance();

  // Initialize Firebase; skip without crashing if config is missing (no google-services.json)
  await FirebaseService.initialize(optional: true);

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
