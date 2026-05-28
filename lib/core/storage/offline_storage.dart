/// SRIBEESonline - Offline Storage Service
///
/// Hive-based local storage for offline support.
/// Caches products, cart, user data, and pending operations.
library;

import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

/// Box names for different data types
class HiveBoxes {
  static const String products = 'products';
  static const String categories = 'categories';
  static const String cart = 'cart';
  static const String user = 'user';
  static const String tokens = 'tokens';
  static const String wishlist = 'wishlist';
  static const String pendingOps = 'pending_operations';
  static const String settings = 'settings';
  static const String searchHistory = 'search_history';
}

/// Offline storage service
class OfflineStorageService {
  static OfflineStorageService? _instance;
  static OfflineStorageService get instance => _instance!;

  bool _initialized = false;

  /// Initialize Hive and open boxes
  static Future<void> initialize() async {
    if (_instance != null && _instance!._initialized) return;

    await Hive.initFlutter();

    _instance = OfflineStorageService._();
    await _instance!._openBoxes();
    _instance!._initialized = true;
  }

  OfflineStorageService._();

  Future<void> _openBoxes() async {
    await Future.wait([
      Hive.openBox(HiveBoxes.products),
      Hive.openBox(HiveBoxes.categories),
      Hive.openBox(HiveBoxes.cart),
      Hive.openBox(HiveBoxes.user),
      Hive.openBox(HiveBoxes.tokens),
      Hive.openBox(HiveBoxes.wishlist),
      Hive.openBox(HiveBoxes.pendingOps),
      Hive.openBox(HiveBoxes.settings),
      Hive.openBox(HiveBoxes.searchHistory),
    ]);
  }

  // ===========================================================================
  // Generic Operations
  // ===========================================================================

  /// Get a box by name
  Box _getBox(String name) => Hive.box(name);

  /// Save data with optional expiry
  Future<void> save<T>(
    String boxName,
    String key,
    T value, {
    Duration? expiry,
  }) async {
    final box = _getBox(boxName);
    final data = {
      'value': value is Map || value is List ? jsonEncode(value) : value,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'expiry': expiry?.inMilliseconds,
    };
    await box.put(key, data);
  }

  /// Get data (returns null if expired)
  T? get<T>(String boxName, String key, {T Function(dynamic)? parser}) {
    final box = _getBox(boxName);
    final data = box.get(key);

    if (data == null) return null;

    // Check expiry
    final expiry = data['expiry'] as int?;
    if (expiry != null) {
      final timestamp = data['timestamp'] as int;
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - timestamp > expiry) {
        // Expired - delete and return null
        box.delete(key);
        return null;
      }
    }

    final value = data['value'];
    
    if (parser != null) {
      if (value is String) {
        try {
          return parser(jsonDecode(value));
        } catch (_) {
          return parser(value);
        }
      }
      return parser(value);
    }

    return value as T?;
  }

  /// Delete data
  Future<void> delete(String boxName, String key) async {
    final box = _getBox(boxName);
    await box.delete(key);
  }

  /// Clear a box
  Future<void> clearBox(String boxName) async {
    final box = _getBox(boxName);
    await box.clear();
  }

  /// Clear all data
  Future<void> clearAll() async {
    await Future.wait([
      clearBox(HiveBoxes.products),
      clearBox(HiveBoxes.categories),
      clearBox(HiveBoxes.cart),
      clearBox(HiveBoxes.wishlist),
      clearBox(HiveBoxes.searchHistory),
    ]);
  }

  // ===========================================================================
  // Products Cache
  // ===========================================================================

  /// Cache product list
  Future<void> cacheProducts(
    String cacheKey,
    List<Map<String, dynamic>> products, {
    Duration expiry = const Duration(minutes: 30),
  }) async {
    await save(HiveBoxes.products, cacheKey, products, expiry: expiry);
  }

  /// Get cached products
  List<Map<String, dynamic>>? getCachedProducts(String cacheKey) {
    return get<List<Map<String, dynamic>>>(
      HiveBoxes.products,
      cacheKey,
      parser: (data) {
        final list = data as List;
        return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      },
    );
  }

  /// Cache single product
  Future<void> cacheProduct(
    String productId,
    Map<String, dynamic> product, {
    Duration expiry = const Duration(hours: 1),
  }) async {
    await save(HiveBoxes.products, 'product_$productId', product, expiry: expiry);
  }

  /// Get cached product
  Map<String, dynamic>? getCachedProduct(String productId) {
    return get<Map<String, dynamic>>(
      HiveBoxes.products,
      'product_$productId',
      parser: (data) => Map<String, dynamic>.from(data as Map),
    );
  }

  // ===========================================================================
  // Cart Storage
  // ===========================================================================

  /// Save cart locally
  Future<void> saveCart(Map<String, dynamic> cart) async {
    await save(HiveBoxes.cart, 'current_cart', cart);
  }

  /// Get local cart
  Map<String, dynamic>? getCart() {
    return get<Map<String, dynamic>>(
      HiveBoxes.cart,
      'current_cart',
      parser: (data) => Map<String, dynamic>.from(data as Map),
    );
  }

  /// Save cart version for sync
  Future<void> saveCartVersion(String version) async {
    await save(HiveBoxes.cart, 'cart_version', version);
  }

  /// Get cart version
  String? getCartVersion() {
    return get<String>(HiveBoxes.cart, 'cart_version');
  }

  // ===========================================================================
  // User & Auth
  // ===========================================================================

  /// Save auth tokens
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await save(HiveBoxes.tokens, 'auth_tokens', {
      'access_token': accessToken,
      'refresh_token': refreshToken,
    });
  }

  /// Get auth tokens
  Map<String, String>? getTokens() {
    return get<Map<String, String>>(
      HiveBoxes.tokens,
      'auth_tokens',
      parser: (data) {
        final map = data as Map;
        return {
          'access_token': map['access_token'] as String,
          'refresh_token': map['refresh_token'] as String,
        };
      },
    );
  }

  /// Clear auth tokens
  Future<void> clearTokens() async {
    await delete(HiveBoxes.tokens, 'auth_tokens');
  }

  /// Save user data
  Future<void> saveUser(Map<String, dynamic> user) async {
    await save(HiveBoxes.user, 'current_user', user);
  }

  /// Get user data
  Map<String, dynamic>? getUser() {
    return get<Map<String, dynamic>>(
      HiveBoxes.user,
      'current_user',
      parser: (data) => Map<String, dynamic>.from(data as Map),
    );
  }

  /// Clear user data
  Future<void> clearUser() async {
    await delete(HiveBoxes.user, 'current_user');
  }

  // ===========================================================================
  // Pending Operations (Offline Queue)
  // ===========================================================================

  /// Add pending operation
  Future<void> addPendingOperation(Map<String, dynamic> operation) async {
    final box = _getBox(HiveBoxes.pendingOps);
    final key = 'op_${DateTime.now().millisecondsSinceEpoch}';
    await box.put(key, jsonEncode(operation));
  }

  /// Get all pending operations
  List<Map<String, dynamic>> getPendingOperations() {
    final box = _getBox(HiveBoxes.pendingOps);
    return box.values
        .map((e) => Map<String, dynamic>.from(jsonDecode(e as String) as Map))
        .toList();
  }

  /// Remove pending operation
  Future<void> removePendingOperation(String key) async {
    final box = _getBox(HiveBoxes.pendingOps);
    await box.delete(key);
  }

  /// Clear all pending operations
  Future<void> clearPendingOperations() async {
    await clearBox(HiveBoxes.pendingOps);
  }

  // ===========================================================================
  // Search History
  // ===========================================================================

  /// Add to search history
  Future<void> addSearchHistory(String query) async {
    final box = _getBox(HiveBoxes.searchHistory);
    var history = box.get('history') as List<dynamic>? ?? [];
    
    // Remove if exists
    history = history.where((e) => e != query).toList();
    
    // Add to front
    history.insert(0, query);
    
    // Keep only last 20
    if (history.length > 20) {
      history = history.sublist(0, 20);
    }
    
    await box.put('history', history);
  }

  /// Get search history
  List<String> getSearchHistory() {
    final box = _getBox(HiveBoxes.searchHistory);
    final history = box.get('history') as List<dynamic>? ?? [];
    return history.map((e) => e as String).toList();
  }

  /// Clear search history
  Future<void> clearSearchHistory() async {
    await delete(HiveBoxes.searchHistory, 'history');
  }

  // ===========================================================================
  // Settings
  // ===========================================================================

  /// Save setting
  Future<void> saveSetting(String key, dynamic value) async {
    final box = _getBox(HiveBoxes.settings);
    await box.put(key, value);
  }

  /// Get setting
  T? getSetting<T>(String key, {T? defaultValue}) {
    final box = _getBox(HiveBoxes.settings);
    return box.get(key, defaultValue: defaultValue) as T?;
  }
}
