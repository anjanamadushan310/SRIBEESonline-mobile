/// SRIBEESonline - Product Repository
///
/// Repository for product-related API operations.
/// Implements caching and offline support.
library;

import '../../../core/api/api_client.dart';
import '../../../core/repositories/base_repository.dart';
import '../models/product_model.dart';

/// Product list result
class ProductListResult {
  final List<Product> products;
  final int total;
  final Map<String, dynamic>? facets;

  ProductListResult({
    required this.products,
    required this.total,
    this.facets,
  });
}

/// Search suggestion
class SearchSuggestion {
  final String type; // 'product' or 'category'
  final String text;
  final String id;

  SearchSuggestion({
    required this.type,
    required this.text,
    required this.id,
  });

  factory SearchSuggestion.fromJson(Map<String, dynamic> json) {
    return SearchSuggestion(
      type: json['type'] as String,
      text: json['text'] as String,
      id: json['id'] as String,
    );
  }
}

class ProductRepository extends BaseRepository with OfflineCapable {
  ProductRepository(super.apiClient);

  // Backend sort_by only accepts these; anything else is dropped so the API
  // doesn't 422 on legacy values like "relevance".
  static const _allowedSort = {'created_at', 'price', 'name', 'view_count'};

  /// Parse a `{ success, data: { products: [...], pagination: { total } } }`
  /// envelope into a [ProductListResult].
  ProductListResult _parseListEnvelope(Map<String, dynamic> response) {
    final data = (response['data'] as Map?) ?? const {};
    final products = (data['products'] as List?)
            ?.map((e) => Product.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList() ??
        [];
    final total = (data['pagination'] as Map?)?['total'] as int? ??
        products.length;
    return ProductListResult(products: products, total: total);
  }

  /// Get products with filtering and pagination (GET /products).
  ///
  /// The branch is **not** passed from the client: the backend resolves it from
  /// the caller's session (set via /session/set-location) and merges each
  /// product's branch override over the global catalog before responding. That
  /// keeps a client from shopping a branch it hasn't been routed to — so the
  /// prices and stock in the response are already branch-correct.
  ///
  /// `categoryId` matches the category and everything under its
  /// sub-categories; `subcategoryId` narrows to one leaf.
  Future<ProductListResult> getProducts({
    int page = 1,
    int pageSize = 20,
    String? query,
    String? categoryId,
    String? subcategoryId,
    double? minPrice,
    double? maxPrice,
    bool? inStock,
    bool? isFeatured,
    bool? onSale,
    String sortBy = 'created_at',
    String sortOrder = 'desc',
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': pageSize,
    };

    if (query != null && query.isNotEmpty) queryParams['search'] = query;
    if (categoryId != null) queryParams['category_id'] = categoryId;
    if (subcategoryId != null) queryParams['subcategory_id'] = subcategoryId;
    if (minPrice != null) queryParams['min_price'] = minPrice;
    if (maxPrice != null) queryParams['max_price'] = maxPrice;
    if (isFeatured != null) queryParams['is_featured'] = isFeatured;
    if (_allowedSort.contains(sortBy)) {
      queryParams['sort_by'] = sortBy;
      queryParams['sort_order'] = sortOrder;
    }

    final response = await apiClient.get<Map<String, dynamic>>(
      // Base URL already includes /api/v1 — do not repeat the prefix here.
      '/products',
      queryParameters: queryParams,
    );
    return _parseListEnvelope(response);
  }

  /// Home "Quick Sale" feed — highest-discount products for the active branch.
  /// GET /products/home-feed.
  Future<List<Product>> getHomeFeed({int limit = 20}) async {
    final response = await apiClient.get<Map<String, dynamic>>(
      '/products/home-feed',
      queryParameters: {'limit': limit},
    );
    final data = (response['data'] as Map?) ?? const {};
    return (data['products'] as List?)
            ?.map((e) => Product.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList() ??
        [];
  }

  /// Full-text search within the active branch. GET /products/search.
  Future<ProductListResult> searchProducts({
    required String query,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await apiClient.get<Map<String, dynamic>>(
      '/products/search',
      queryParameters: {'q': query, 'page': page, 'limit': limit},
    );
    return _parseListEnvelope(response);
  }

  /// Get single product by ID (GET /products/{id}).
  Future<Product?> getProductById(String productId) async {
    try {
      final response = await apiClient.get<Map<String, dynamic>>(
        '/products/$productId',
      );
      final data = response['data'];
      if (data is Map) {
        return Product.fromJson(Map<String, dynamic>.from(data));
      }
      return Product.fromJson(response);
    } on ApiException catch (e) {
      if (e.isNotFound) return null;
      rethrow;
    }
  }

  /// Get search autocomplete suggestions
  Future<List<SearchSuggestion>> getSearchSuggestions(String query) async {
    final response = await apiClient.get<List<dynamic>>(
      '/products/autocomplete',
      queryParameters: {'query': query, 'limit': 10},
    );

    return response
        .map((e) => SearchSuggestion.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get trending searches
  Future<List<String>> getTrendingSearches() async {
    final response = await apiClient.get<List<dynamic>>(
      '/products/trending-searches',
    );
    return response.map((e) => e as String).toList();
  }

  /// Get products by category
  Future<ProductListResult> getProductsByCategory(
    String categoryId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    return getProducts(
      page: page,
      pageSize: pageSize,
      categoryId: categoryId,
    );
  }

  /// Get featured products
  Future<List<Product>> getFeaturedProducts({int limit = 10}) async {
    final result = await getProducts(
      pageSize: limit,
      isFeatured: true,
    );
    return result.products;
  }

  /// Get products on sale
  Future<List<Product>> getOnSaleProducts({int limit = 20}) async {
    final result = await getProducts(
      pageSize: limit,
      onSale: true,
    );
    return result.products;
  }

  /// Get related products
  Future<List<Product>> getRelatedProducts(
    String productId, {
    int limit = 10,
  }) async {
    final response = await apiClient.get<List<dynamic>>(
      '/products/$productId/related',
      queryParameters: {'limit': limit},
    );

    return response
        .map((e) => Product.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get product reviews
  Future<ProductReviewsResult> getProductReviews(
    String productId, {
    int page = 1,
    int pageSize = 10,
    String sortBy = 'newest',
  }) async {
    final response = await apiClient.get<Map<String, dynamic>>(
      '/products/$productId/reviews',
      queryParameters: {
        'page': page,
        'page_size': pageSize,
        'sort_by': sortBy,
      },
    );

    final reviews = (response['reviews'] as List?)
            ?.map((e) => ProductReview.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return ProductReviewsResult(
      reviews: reviews,
      total: response['total'] as int? ?? 0,
      averageRating: (response['average_rating'] as num?)?.toDouble() ?? 0,
      ratingDistribution:
          (response['rating_distribution'] as Map<String, dynamic>?)?.map(
                (k, v) => MapEntry(int.parse(k), v as int),
              ) ??
              {},
    );
  }

  /// Submit product review
  Future<ProductReview> submitReview({
    required String productId,
    required int rating,
    String? title,
    String? comment,
  }) async {
    final response = await apiClient.post<Map<String, dynamic>>(
      '/products/$productId/reviews',
      data: {
        'rating': rating,
        if (title != null) 'title': title,
        if (comment != null) 'comment': comment,
      },
    );

    return ProductReview.fromJson(response);
  }
}

/// Product reviews result
class ProductReviewsResult {
  final List<ProductReview> reviews;
  final int total;
  final double averageRating;
  final Map<int, int> ratingDistribution;

  ProductReviewsResult({
    required this.reviews,
    required this.total,
    required this.averageRating,
    required this.ratingDistribution,
  });
}

/// Product review model
class ProductReview {
  final String id;
  final String productId;
  final String userId;
  final String? userName;
  final int rating;
  final String? title;
  final String? comment;
  final bool isVerifiedPurchase;
  final int helpfulCount;
  final DateTime createdAt;

  ProductReview({
    required this.id,
    required this.productId,
    required this.userId,
    this.userName,
    required this.rating,
    this.title,
    this.comment,
    this.isVerifiedPurchase = false,
    this.helpfulCount = 0,
    required this.createdAt,
  });

  factory ProductReview.fromJson(Map<String, dynamic> json) {
    return ProductReview(
      id: json['review_id'] as String,
      productId: json['product_id'] as String,
      userId: json['user_id'] as String,
      userName: json['user']?['full_name'] as String? ??
          json['user']?['first_name'] as String?,
      rating: json['rating'] as int,
      title: json['title'] as String?,
      comment: json['comment'] as String?,
      isVerifiedPurchase: json['is_verified_purchase'] as bool? ?? false,
      helpfulCount: json['helpful_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
