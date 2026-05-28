/// SRIBEESonline - Language Provider
///
/// Riverpod state management for the user's preferred language.
/// Persists the selection to SharedPreferences so the splash screen
/// can skip the language picker on subsequent launches.
///
/// Supported locales: Sinhala (si), Tamil (ta), English (en).
library;

import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// SharedPreferences provider  (overridden in main via ProviderScope)
// ---------------------------------------------------------------------------
final sharedPrefsProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPrefsProvider must be overridden with a real SharedPreferences '
    'instance in the root ProviderScope.',
  );
});

// ---------------------------------------------------------------------------
// Supported locales
// ---------------------------------------------------------------------------
class AppLocales {
  static const sinhala = Locale('si');
  static const tamil = Locale('ta');
  static const english = Locale('en');

  static const supported = [sinhala, tamil, english];

  static const labels = {
    'si': 'සිංහල',
    'ta': 'தமிழ்',
    'en': 'English',
  };
}

// ---------------------------------------------------------------------------
// Language provider
// ---------------------------------------------------------------------------
final languageProvider =
    StateNotifierProvider<LanguageNotifier, Locale?>((ref) {
  final prefs = ref.watch(sharedPrefsProvider);
  return LanguageNotifier(prefs);
});

/// Convenience: true when the user has already chosen a language.
final hasLanguageProvider = Provider<bool>((ref) {
  return ref.watch(languageProvider) != null;
});

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------
class LanguageNotifier extends StateNotifier<Locale?> {
  static const _key = 'language_code';

  final SharedPreferences _prefs;

  LanguageNotifier(this._prefs) : super(null) {
    _loadSaved();
  }

  void _loadSaved() {
    final code = _prefs.getString(_key);
    if (code != null && code.isNotEmpty) {
      state = Locale(code);
    }
  }

  /// Persist the selected language and update the app locale.
  Future<void> setLanguage(String code) async {
    await _prefs.setString(_key, code);
    state = Locale(code);
  }

  /// Clear language (forces re-selection on next launch).
  Future<void> clear() async {
    await _prefs.remove(_key);
    state = null;
  }
}
