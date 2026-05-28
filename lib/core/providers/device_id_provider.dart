/// SRIBEESonline - Device ID Provider
///
/// Provides a persistent device/session id for guest users (e.g. branch
/// resolve-by-location). Stored in SharedPreferences.
library;

import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'language_provider.dart';

const _key = 'device_id';

String _generateId() {
  final r = Random();
  return 'guest_${DateTime.now().millisecondsSinceEpoch}_${r.nextInt(0x7FFFFFFF).toRadixString(16)}';
}

/// Persistent device id for this app install (used as X-Device-Id for guest APIs).
final deviceIdProvider = Provider<String>((ref) {
  final prefs = ref.watch(sharedPrefsProvider);
  var id = prefs.getString(_key);
  if (id == null || id.isEmpty) {
    id = _generateId();
    prefs.setString(_key, id);
  }
  return id;
});
