/// SRIBEESonline - Network Connectivity Service
///
/// Monitors network connectivity and manages offline mode.
/// Triggers sync when connection is restored.
library;

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Network status enum
enum NetworkStatus {
  online,
  offline,
}

/// Connectivity provider
final connectivityProvider =
    StateNotifierProvider<ConnectivityNotifier, NetworkStatus>((ref) {
  return ConnectivityNotifier();
});

/// Is online provider
final isOnlineProvider = Provider<bool>((ref) {
  return ref.watch(connectivityProvider) == NetworkStatus.online;
});

/// Connectivity notifier
class ConnectivityNotifier extends StateNotifier<NetworkStatus> {
  late final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  ConnectivityNotifier() : super(NetworkStatus.online) {
    _connectivity = Connectivity();
    _init();
  }

  Future<void> _init() async {
    // Check initial status
    final results = await _connectivity.checkConnectivity();
    _updateStatus(results);

    // Listen for changes
    _subscription = _connectivity.onConnectivityChanged.listen(_updateStatus);
  }

  void _updateStatus(List<ConnectivityResult> results) {
    if (results.isEmpty || results.contains(ConnectivityResult.none)) {
      state = NetworkStatus.offline;
    } else {
      state = NetworkStatus.online;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

/// Sync manager for offline operations
class SyncManager {
  static SyncManager? _instance;
  static SyncManager get instance => _instance ??= SyncManager._();

  SyncManager._();

  final _syncCallbacks = <String, Future<void> Function()>{};
  bool _isSyncing = false;

  /// Register a sync callback
  void registerSyncCallback(String key, Future<void> Function() callback) {
    _syncCallbacks[key] = callback;
  }

  /// Unregister a sync callback
  void unregisterSyncCallback(String key) {
    _syncCallbacks.remove(key);
  }

  /// Trigger sync for all registered callbacks
  Future<void> syncAll() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      for (final callback in _syncCallbacks.values) {
        try {
          await callback();
        } catch (e) {
          // Log error but continue with other syncs
          print('Sync error: $e');
        }
      }
    } finally {
      _isSyncing = false;
    }
  }

  /// Check if sync is in progress
  bool get isSyncing => _isSyncing;
}

/// Provider for sync manager
final syncManagerProvider = Provider<SyncManager>((ref) {
  final connectivity = ref.watch(connectivityProvider);

  // Trigger sync when coming back online
  if (connectivity == NetworkStatus.online) {
    SyncManager.instance.syncAll();
  }

  return SyncManager.instance;
});
