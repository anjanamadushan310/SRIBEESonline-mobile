/// SRIBEESonline - Cart Provider
///
/// Backend-driven shopping cart state (Riverpod), synced with the Redis cart
/// APIs:
///
///   GET    /cart                        - load cart
///   POST   /cart/items                  - add item
///   PUT    /cart/items/{id}?variant_id= - update quantity (0 ⇒ remove)
///   DELETE /cart/items/{id}?variant_id= - remove item
///   DELETE /cart                        - clear cart
///   POST   /cart/coupon                 - apply coupon
///   DELETE /cart/coupon                 - remove coupon
///
/// The backend cart requires authentication; for guests the cart falls back
/// to purely local state with the same public API (`items`, `itemCount`,
/// `addItem`, `updateQuantity`, `removeItem`, `clearCart`), so the UI does
/// not need to care which mode is active.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../../features/cart/models/cart_model.dart';
import 'auth_provider.dart';

// Flat delivery fee applied to the local (guest) cart once it has items.
// Server carts use the totals computed by the backend.
const double _deliveryFee = 350;

// =============================================================================
// Cart State
// =============================================================================

class CartState {
  final List<CartItem> items;
  final bool isLoading;
  final String? error;
  final CartTotals? totals;
  final AppliedCoupon? coupon;

  const CartState({
    this.items = const [],
    this.isLoading = false,
    this.error,
    this.totals,
    this.coupon,
  });

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  bool get isEmpty => items.isEmpty;

  double get subtotal => totals?.subtotal ?? 0;

  double get total => totals?.total ?? 0;

  CartState copyWith({
    List<CartItem>? items,
    bool? isLoading,
    String? error,
    CartTotals? totals,
    AppliedCoupon? coupon,
    bool clearError = false,
    bool clearCoupon = false,
  }) {
    return CartState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      totals: totals ?? this.totals,
      coupon: clearCoupon ? null : (coupon ?? this.coupon),
    );
  }
}

// =============================================================================
// Providers
// =============================================================================

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  // Recreated on login/logout so the server cart is (re)loaded.
  final isAuthenticated = ref.watch(isAuthenticatedProvider);
  return CartNotifier(apiClient, isAuthenticated: isAuthenticated);
});

/// Cart item count (for badge).
final cartItemCountProvider =
    Provider<int>((ref) => ref.watch(cartProvider).itemCount);

/// Cart total (for display).
final cartTotalProvider =
    Provider<double>((ref) => ref.watch(cartProvider).total);

class CartNotifier extends StateNotifier<CartState> {
  final ApiClient _api;
  final bool _isAuthenticated;

  CartNotifier(this._api, {required bool isAuthenticated})
      : _isAuthenticated = isAuthenticated,
        super(const CartState()) {
    if (_isAuthenticated) {
      loadCart();
    } else {
      _recalculateLocalTotals();
    }
  }

  bool get _useServer => _isAuthenticated && _api.isAuthenticated;

  // ==========================================================================
  // Server sync
  // ==========================================================================

  /// GET /cart — replace local state with the server cart.
  Future<void> loadCart() async {
    if (!_useServer) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _api.get<Map<String, dynamic>>('/cart');
      _applyServerCart(response);
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (_) {
      state = state.copyWith(isLoading: false, error: 'Failed to load cart.');
    }
  }

  void _applyServerCart(Map<String, dynamic> response) {
    final data = response['data'];
    final cart = Cart.fromJson(
      data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{},
    );
    state = CartState(
      items: cart.items,
      totals: cart.totals ?? const CartTotals(),
      coupon: cart.coupon,
      isLoading: false,
    );
  }

  // ==========================================================================
  // Public API (same signatures the UI already relies on)
  // ==========================================================================

  /// Add item to cart (or bump quantity if it already exists).
  Future<void> addItem({
    required String productId,
    String? variantId,
    int quantity = 1,
    required double price,
    required String name,
    String? imageUrl,
    String? sku,
  }) async {
    if (!_useServer) {
      _addItemLocal(
        productId: productId,
        variantId: variantId,
        quantity: quantity,
        price: price,
        name: name,
        imageUrl: imageUrl,
      );
      return;
    }

    try {
      final response = await _api.post<Map<String, dynamic>>(
        '/cart/items',
        data: {
          'product_id': productId,
          'quantity': quantity,
          'price': price,
          'name': name,
          if (imageUrl != null) 'image': imageUrl,
          if (sku != null) 'sku': sku,
          if (variantId != null) 'variant_id': variantId,
        },
      );
      _applyServerCart(response);
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
    } catch (_) {
      state = state.copyWith(error: 'Failed to add item to cart.');
    }
  }

  /// Update an item's quantity (removes it when quantity <= 0).
  Future<void> updateQuantity({
    required String productId,
    String? variantId,
    required int quantity,
  }) async {
    if (!_useServer) {
      _updateQuantityLocal(
        productId: productId,
        variantId: variantId,
        quantity: quantity,
      );
      return;
    }

    try {
      final response = await _api.put<Map<String, dynamic>>(
        variantId != null
            ? '/cart/items/$productId?variant_id=$variantId'
            : '/cart/items/$productId',
        data: {'quantity': quantity < 0 ? 0 : quantity},
      );
      _applyServerCart(response);
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
      await loadCart();
    } catch (_) {
      state = state.copyWith(error: 'Failed to update cart.');
    }
  }

  /// Remove an item from the cart.
  Future<void> removeItem({required String productId, String? variantId}) async {
    if (!_useServer) {
      _removeItemLocal(productId: productId, variantId: variantId);
      return;
    }

    try {
      // ApiClient.delete returns no body — refresh the cart afterwards.
      await _api.delete(
        variantId != null
            ? '/cart/items/$productId?variant_id=$variantId'
            : '/cart/items/$productId',
      );
      await loadCart();
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
    } catch (_) {
      state = state.copyWith(error: 'Failed to remove item.');
    }
  }

  /// Empty the cart.
  Future<void> clearCart() async {
    if (!_useServer) {
      state = const CartState();
      _recalculateLocalTotals();
      return;
    }

    try {
      await _api.delete('/cart');
      state = const CartState(totals: CartTotals());
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
    } catch (_) {
      state = state.copyWith(error: 'Failed to clear cart.');
    }
  }

  /// Apply a coupon code (server carts only).
  Future<void> applyCoupon(String code) async {
    if (!_useServer) return;
    try {
      final response = await _api.post<Map<String, dynamic>>(
        '/cart/coupon',
        data: {'code': code},
      );
      _applyServerCart(response);
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
    }
  }

  /// Remove the applied coupon (server carts only).
  Future<void> removeCoupon() async {
    if (!_useServer) return;
    try {
      await _api.delete('/cart/coupon');
      await loadCart();
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
    }
  }

  // ==========================================================================
  // Local (guest) cart fallback
  // ==========================================================================

  void _addItemLocal({
    required String productId,
    String? variantId,
    int quantity = 1,
    required double price,
    required String name,
    String? imageUrl,
  }) {
    final existingIndex = state.items.indexWhere(
      (item) => item.productId == productId && item.variantId == variantId,
    );

    final items = [...state.items];
    if (existingIndex >= 0) {
      final existing = items[existingIndex];
      items[existingIndex] =
          existing.copyWith(quantity: existing.quantity + quantity);
    } else {
      items.add(CartItem(
        productId: productId,
        variantId: variantId,
        quantity: quantity,
        price: price,
        name: name,
        imageUrl: imageUrl,
      ));
    }

    state = state.copyWith(items: items);
    _recalculateLocalTotals();
  }

  void _updateQuantityLocal({
    required String productId,
    String? variantId,
    required int quantity,
  }) {
    if (quantity <= 0) {
      _removeItemLocal(productId: productId, variantId: variantId);
      return;
    }

    final items = state.items.map((item) {
      if (item.productId == productId && item.variantId == variantId) {
        return item.copyWith(quantity: quantity);
      }
      return item;
    }).toList();

    state = state.copyWith(items: items);
    _recalculateLocalTotals();
  }

  void _removeItemLocal({required String productId, String? variantId}) {
    final items = state.items
        .where((item) =>
            !(item.productId == productId && item.variantId == variantId))
        .toList();

    state = state.copyWith(items: items);
    _recalculateLocalTotals();
  }

  void _recalculateLocalTotals() {
    final subtotal = state.items.fold<double>(
      0,
      (sum, item) => sum + (item.price * item.quantity),
    );
    final shipping = subtotal > 0 ? _deliveryFee : 0.0;

    state = state.copyWith(
      totals: CartTotals(
        subtotal: subtotal,
        shipping: shipping,
        total: subtotal + shipping,
      ),
    );
  }
}
