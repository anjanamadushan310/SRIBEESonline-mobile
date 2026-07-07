/// SRIBEESonline - Wishlist Provider
///
/// Backend-driven wishlist state with **optimistic** heart toggles: the icon
/// flips instantly, the API call runs behind it, and the state reverts if the
/// call fails. Auth-gated — guests get an empty wishlist and toggles report
/// [WishlistToggleOutcome.authRequired].
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../../features/saved/repositories/wishlist_repository.dart';
import 'auth_provider.dart';

// =============================================================================
// State
// =============================================================================

class WishlistState {
  final List<WishlistItem> items;

  /// (productId:variantId) keys for O(1) "is hearted" lookups.
  final Set<String> keys;
  final bool isLoading;
  final String? error;

  const WishlistState({
    this.items = const [],
    this.keys = const {},
    this.isLoading = false,
    this.error,
  });

  int get count => items.length;

  WishlistState copyWith({
    List<WishlistItem>? items,
    Set<String>? keys,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return WishlistState(
      items: items ?? this.items,
      keys: keys ?? this.keys,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// What actually happened on a toggle — drives the caller's snackbar.
enum WishlistToggleOutcome { added, removed, failed, authRequired }

// =============================================================================
// Providers
// =============================================================================

final wishlistRepositoryProvider = Provider<WishlistRepository>((ref) {
  return WishlistRepository(ref.watch(apiClientProvider));
});

final wishlistProvider =
    StateNotifierProvider<WishlistNotifier, WishlistState>((ref) {
  final repository = ref.watch(wishlistRepositoryProvider);
  // Recreated on login/logout so the server wishlist is (re)loaded.
  final isAuthenticated = ref.watch(isAuthenticatedProvider);
  return WishlistNotifier(repository, isAuthenticated: isAuthenticated);
});

/// O(1) heart state for a (productId, variantId) pair. Pass the key from
/// [wishlistKey] — for base products: `wishlistKey(product.id, null)`.
final isWishlistedProvider = Provider.family<bool, String>((ref, key) {
  return ref.watch(wishlistProvider).keys.contains(key);
});

// =============================================================================
// Notifier
// =============================================================================

class WishlistNotifier extends StateNotifier<WishlistState> {
  final WishlistRepository _repository;
  final bool _isAuthenticated;

  WishlistNotifier(this._repository, {required bool isAuthenticated})
      : _isAuthenticated = isAuthenticated,
        super(const WishlistState()) {
    if (_isAuthenticated) loadWishlist();
  }

  /// GET /wishlist — replace state with the server's list.
  Future<void> loadWishlist() async {
    if (!_isAuthenticated) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final items = await _repository.getWishlist();
      state = WishlistState(
        items: items,
        keys: items.map((i) => i.key).toSet(),
      );
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (_) {
      state = state.copyWith(
          isLoading: false, error: 'Failed to load your wishlist.');
    }
  }

  /// Optimistically toggle a (product, variant) in the wishlist.
  ///
  /// The heart state flips **before** the API call; on failure the previous
  /// state is restored and [WishlistToggleOutcome.failed] is returned so the
  /// caller can show an error snackbar.
  Future<WishlistToggleOutcome> toggle({
    required String productId,
    String? variantId,
    double? priceAtWatch,
  }) async {
    if (!_isAuthenticated) return WishlistToggleOutcome.authRequired;

    final key = wishlistKey(productId, variantId);
    final wasSaved = state.keys.contains(key);

    // Snapshot for revert.
    final prevItems = state.items;
    final prevKeys = state.keys;

    if (wasSaved) {
      // Optimistic remove.
      state = state.copyWith(
        keys: {...prevKeys}..remove(key),
        items: prevItems.where((i) => i.key != key).toList(),
        clearError: true,
      );
      try {
        await _repository.removeItem(
            productId: productId, variantId: variantId);
        return WishlistToggleOutcome.removed;
      } catch (_) {
        if (mounted) {
          state = state.copyWith(items: prevItems, keys: prevKeys);
        }
        return WishlistToggleOutcome.failed;
      }
    } else {
      // Optimistic add — flip the heart now; the full item snapshot (joined
      // product info) arrives with the quiet reload after the API succeeds.
      state = state.copyWith(keys: {...prevKeys, key}, clearError: true);
      try {
        await _repository.addItem(
          productId: productId,
          variantId: variantId,
          priceAtWatch: priceAtWatch,
        );
        // Refresh silently so the Saved tab gets the product snapshot.
        try {
          final items = await _repository.getWishlist();
          if (mounted) {
            state = WishlistState(
              items: items,
              keys: items.map((i) => i.key).toSet(),
            );
          }
        } catch (_) {
          // Keep the optimistic key; the tab will sync on next load/refresh.
        }
        return WishlistToggleOutcome.added;
      } catch (_) {
        if (mounted) {
          state = state.copyWith(items: prevItems, keys: prevKeys);
        }
        return WishlistToggleOutcome.failed;
      }
    }
  }
}
