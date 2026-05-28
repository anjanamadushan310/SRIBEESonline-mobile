/// SRIBEESonline - Product Providers
///
/// Riverpod providers for product listing, search, and details.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../api/api_client.dart';
import '../../features/products/models/product_model.dart';
import '../../features/products/repositories/product_repository.dart';

part 'product_provider.freezed.dart';

// =============================================================================
// Repository Provider
// =============================================================================

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ProductRepository(apiClient);
});

// =============================================================================
// Product List State
// =============================================================================

@freezed
class ProductListState with _$ProductListState {
  const factory ProductListState({
    @Default([]) List<Product> products,
    @Default(false) bool isLoading,
    @Default(false) bool isLoadingMore,
    @Default(false) bool hasReachedEnd,
    @Default(1) int currentPage,
    @Default(20) int pageSize,
    String? error,
    ProductFilters? filters,
  }) = _ProductListState;
}

@freezed
class ProductFilters with _$ProductFilters {
  const factory ProductFilters({
    String? query,
    String? categoryId,
    List<String>? categoryIds,
    double? minPrice,
    double? maxPrice,
    bool? inStock,
    bool? onSale,
    List<String>? brands,
    double? minRating,
    @Default('relevance') String sortBy,
    @Default('desc') String sortOrder,
  }) = _ProductFilters;
}

// =============================================================================
// Product List Provider
// =============================================================================

final productListProvider =
    StateNotifierProvider<ProductListNotifier, ProductListState>((ref) {
  final repository = ref.watch(productRepositoryProvider);
  return ProductListNotifier(repository);
});

class ProductListNotifier extends StateNotifier<ProductListState> {
  final ProductRepository _repository;

  ProductListNotifier(this._repository) : super(const ProductListState());

  /// Load initial products
  Future<void> loadProducts({ProductFilters? filters}) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      filters: filters,
      currentPage: 1,
      hasReachedEnd: false,
    );

    try {
      final result = await _repository.getProducts(
        page: 1,
        pageSize: state.pageSize,
        query: filters?.query,
        categoryId: filters?.categoryId,
        minPrice: filters?.minPrice,
        maxPrice: filters?.maxPrice,
        inStock: filters?.inStock,
        sortBy: filters?.sortBy ?? 'relevance',
        sortOrder: filters?.sortOrder ?? 'desc',
      );

      state = state.copyWith(
        products: result.products,
        isLoading: false,
        hasReachedEnd: result.products.length < state.pageSize,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Load more products (pagination)
  Future<void> loadMore() async {
    if (state.isLoadingMore || state.hasReachedEnd) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final nextPage = state.currentPage + 1;
      final filters = state.filters;

      final result = await _repository.getProducts(
        page: nextPage,
        pageSize: state.pageSize,
        query: filters?.query,
        categoryId: filters?.categoryId,
        minPrice: filters?.minPrice,
        maxPrice: filters?.maxPrice,
        inStock: filters?.inStock,
        sortBy: filters?.sortBy ?? 'relevance',
        sortOrder: filters?.sortOrder ?? 'desc',
      );

      state = state.copyWith(
        products: [...state.products, ...result.products],
        currentPage: nextPage,
        isLoadingMore: false,
        hasReachedEnd: result.products.length < state.pageSize,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  /// Refresh products
  Future<void> refresh() async {
    await loadProducts(filters: state.filters);
  }

  /// Apply filters
  Future<void> applyFilters(ProductFilters filters) async {
    await loadProducts(filters: filters);
  }

  /// Clear filters
  Future<void> clearFilters() async {
    await loadProducts();
  }
}

// =============================================================================
// Product Detail Provider
// =============================================================================

final productDetailProvider =
    FutureProvider.family<Product?, String>((ref, productId) async {
  final repository = ref.watch(productRepositoryProvider);
  return repository.getProductById(productId);
});

// =============================================================================
// Search Providers
// =============================================================================

/// Search query state
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Autocomplete suggestions
final searchSuggestionsProvider =
    FutureProvider.family<List<SearchSuggestion>, String>((ref, query) async {
  if (query.length < 2) return [];
  
  final repository = ref.watch(productRepositoryProvider);
  return repository.getSearchSuggestions(query);
});

/// Trending searches
final trendingSearchesProvider = FutureProvider<List<String>>((ref) async {
  final repository = ref.watch(productRepositoryProvider);
  return repository.getTrendingSearches();
});

/// Search results with filters
final searchResultsProvider =
    StateNotifierProvider<ProductListNotifier, ProductListState>((ref) {
  final repository = ref.watch(productRepositoryProvider);
  return ProductListNotifier(repository);
});

// =============================================================================
// Category Products
// =============================================================================

final categoryProductsProvider = StateNotifierProvider.family<
    ProductListNotifier, ProductListState, String>((ref, categoryId) {
  final repository = ref.watch(productRepositoryProvider);
  final notifier = ProductListNotifier(repository);
  
  // Auto-load products for this category
  notifier.loadProducts(
    filters: ProductFilters(categoryId: categoryId),
  );
  
  return notifier;
});

// =============================================================================
// Featured Products
// =============================================================================

final featuredProductsProvider = FutureProvider<List<Product>>((ref) async {
  final repository = ref.watch(productRepositoryProvider);
  final result = await repository.getProducts(
    pageSize: 10,
    isFeatured: true,
  );
  return result.products;
});

// =============================================================================
// On Sale Products
// =============================================================================

final onSaleProductsProvider = FutureProvider<List<Product>>((ref) async {
  final repository = ref.watch(productRepositoryProvider);
  final result = await repository.getProducts(
    pageSize: 20,
    onSale: true,
  );
  return result.products;
});

// =============================================================================
// Recently Viewed
// =============================================================================

final recentlyViewedProvider =
    StateNotifierProvider<RecentlyViewedNotifier, List<Product>>((ref) {
  return RecentlyViewedNotifier();
});

class RecentlyViewedNotifier extends StateNotifier<List<Product>> {
  static const int maxItems = 20;

  RecentlyViewedNotifier() : super([]);

  void addProduct(Product product) {
    // Remove if exists
    final filtered = state.where((p) => p.id != product.id).toList();
    
    // Add to front
    state = [product, ...filtered].take(maxItems).toList();
  }

  void clear() {
    state = [];
  }
}
