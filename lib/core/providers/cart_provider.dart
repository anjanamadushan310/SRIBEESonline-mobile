/// SRIBEESonline - Cart Provider
///
/// Riverpod state management for shopping cart.
/// Supports offline mode and server sync.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../api/api_client.dart';
import '../../features/cart/models/cart_model.dart';
import '../../features/cart/repositories/cart_repository.dart';

part 'cart_provider.freezed.dart';

// =============================================================================
// Cart State
// =============================================================================

@freezed
class CartState with _$CartState {
  const factory CartState({
    @Default([]) List<CartItem> items,
    @Default(false) bool isLoading,
    @Default(false) bool isSyncing,
    String? error,
    CartTotals? totals,
    AppliedCoupon? coupon,
    String? cartVersion,
  }) = _CartState;

  const CartState._();

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);
  
  bool get isEmpty => items.isEmpty;
  
  double get subtotal => totals?.subtotal ?? 0;
  
  double get total => totals?.total ?? 0;
}

@freezed
class CartTotals with _$CartTotals {
  const factory CartTotals({
    @Default(0) double subtotal,
    @Default(0) double discount,
    @Default(0) double tax,
    @Default(0) double shipping,
    @Default(0) double total,
  }) = _CartTotals;

  factory CartTotals.fromJson(Map<String, dynamic> json) => CartTotals(
        subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
        discount: (json['discount'] as num?)?.toDouble() ?? 0,
        tax: (json['tax'] as num?)?.toDouble() ?? 0,
        shipping: (json['shipping'] as num?)?.toDouble() ?? 0,
        total: (json['total'] as num?)?.toDouble() ?? 0,
      );
}

@freezed
class AppliedCoupon with _$AppliedCoupon {
  const factory AppliedCoupon({
    required String code,
    required String discountType,
    required double discountValue,
  }) = _AppliedCoupon;
}

// =============================================================================
// Repository Provider
// =============================================================================

final cartRepositoryProvider = Provider<CartRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CartRepository(apiClient);
});

// =============================================================================
// Cart Provider
// =============================================================================

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  final repository = ref.watch(cartRepositoryProvider);
  return CartNotifier(repository);
});

/// Cart item count (for badge)
final cartItemCountProvider = Provider<int>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.itemCount;
});

/// Cart total (for display)
final cartTotalProvider = Provider<double>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.total;
});

class CartNotifier extends StateNotifier<CartState> {
  final CartRepository _repository;

  CartNotifier(this._repository) : super(const CartState()) {
    _loadCart();
  }

  /// Load cart from local storage and sync with server
  Future<void> _loadCart() async {
    state = state.copyWith(isLoading: true);

    try {
      // Load from local storage first (offline support)
      final localCart = await _repository.getLocalCart();
      if (localCart != null) {
        state = state.copyWith(
          items: localCart.items,
          totals: localCart.totals,
          coupon: localCart.coupon,
          cartVersion: localCart.version,
        );
      }

      // Sync with server
      await syncWithServer();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Sync cart with server
  Future<void> syncWithServer() async {
    if (state.isSyncing) return;

    state = state.copyWith(isSyncing: true);

    try {
      final result = await _repository.syncCart(
        items: state.items,
        coupon: state.coupon,
        version: state.cartVersion,
      );

      state = state.copyWith(
        items: result.items,
        totals: result.totals,
        coupon: result.coupon,
        cartVersion: result.version,
        isSyncing: false,
      );

      // Save to local storage
      await _repository.saveLocalCart(result);
    } catch (e) {
      state = state.copyWith(isSyncing: false);
      // Keep local cart on sync failure
    }
  }

  /// Add item to cart
  Future<void> addItem({
    required String productId,
    String? variantId,
    int quantity = 1,
    required double price,
    required String name,
    String? imageUrl,
  }) async {
    // Optimistic update
    final existingIndex = state.items.indexWhere(
      (item) => item.productId == productId && item.variantId == variantId,
    );

    List<CartItem> updatedItems;

    if (existingIndex >= 0) {
      // Update quantity
      updatedItems = [...state.items];
      final existing = updatedItems[existingIndex];
      updatedItems[existingIndex] = existing.copyWith(
        quantity: existing.quantity + quantity,
      );
    } else {
      // Add new item
      final newItem = CartItem(
        productId: productId,
        variantId: variantId,
        quantity: quantity,
        price: price,
        name: name,
        imageUrl: imageUrl,
      );
      updatedItems = [...state.items, newItem];
    }

    state = state.copyWith(items: updatedItems);
    _recalculateTotals();

    // Sync with server
    await _repository.addItem(
      productId: productId,
      variantId: variantId,
      quantity: quantity,
    );
  }

  /// Update item quantity
  Future<void> updateQuantity({
    required String productId,
    String? variantId,
    required int quantity,
  }) async {
    if (quantity <= 0) {
      await removeItem(productId: productId, variantId: variantId);
      return;
    }

    final updatedItems = state.items.map((item) {
      if (item.productId == productId && item.variantId == variantId) {
        return item.copyWith(quantity: quantity);
      }
      return item;
    }).toList();

    state = state.copyWith(items: updatedItems);
    _recalculateTotals();

    await _repository.updateQuantity(
      productId: productId,
      variantId: variantId,
      quantity: quantity,
    );
  }

  /// Remove item from cart
  Future<void> removeItem({
    required String productId,
    String? variantId,
  }) async {
    final updatedItems = state.items
        .where((item) =>
            !(item.productId == productId && item.variantId == variantId))
        .toList();

    state = state.copyWith(items: updatedItems);
    _recalculateTotals();

    await _repository.removeItem(
      productId: productId,
      variantId: variantId,
    );
  }

  /// Apply coupon code
  Future<bool> applyCoupon(String code) async {
    try {
      final result = await _repository.applyCoupon(code);
      
      state = state.copyWith(
        coupon: result.coupon,
        totals: result.totals,
      );
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Remove coupon
  Future<void> removeCoupon() async {
    state = state.copyWith(coupon: null);
    _recalculateTotals();
    
    await _repository.removeCoupon();
  }

  /// Clear cart
  Future<void> clearCart() async {
    state = const CartState();
    await _repository.clearCart();
  }

  /// Recalculate totals locally
  void _recalculateTotals() {
    final subtotal = state.items.fold<double>(
      0,
      (sum, item) => sum + (item.price * item.quantity),
    );

    double discount = 0;
    if (state.coupon != null) {
      if (state.coupon!.discountType == 'percentage') {
        discount = subtotal * (state.coupon!.discountValue / 100);
      } else {
        discount = state.coupon!.discountValue;
      }
      discount = discount.clamp(0, subtotal);
    }

    final taxableAmount = subtotal - discount;
    final tax = taxableAmount * 0.08; // 8% tax
    final shipping = taxableAmount >= 50 ? 0.0 : 5.99;
    final total = taxableAmount + tax + shipping;

    state = state.copyWith(
      totals: CartTotals(
        subtotal: subtotal,
        discount: discount,
        tax: tax,
        shipping: shipping,
        total: total,
      ),
    );
  }
}
