/// SRIBEESonline - Product Repository
///
/// Repository for product-related API operations.
/// Implements caching and offline support.
library;

import '../api/api_client.dart';
import 'base_repository.dart';
import '../../features/products/models/product_model.dart';

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

  /// Get products with filtering and pagination
  Future<ProductListResult> getProducts({
    int page = 1,
    int pageSize = 20,
    String? query,
    String? categoryId,
    double? minPrice,
    double? maxPrice,
    bool? inStock,
    bool? isFeatured,
    bool? onSale,
    String sortBy = 'relevance',
    String sortOrder = 'desc',
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
      'sort_by': sortBy,
      'sort_order': sortOrder,
    };

    if (query != null) queryParams['query'] = query;
    if (categoryId != null) queryParams['category_id'] = categoryId;
    if (minPrice != null) queryParams['min_price'] = minPrice;
    if (maxPrice != null) queryParams['max_price'] = maxPrice;
    if (inStock != null) queryParams['in_stock'] = inStock;
    if (isFeatured != null) queryParams['is_featured'] = isFeatured;
    if (onSale != null) queryParams['on_sale'] = onSale;

    final response = await apiClient.get<Map<String, dynamic>>(
      '/api/v1/products/search',
      queryParameters: queryParams,
    );

    final products = (response['products'] as List?)
            ?.map((e) => Product.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return ProductListResult(
      products: products,
      total: response['total'] as int? ?? 0,
      facets: response['facets'] as Map<String, dynamic>?,
    );
  }

  /// Get single product by ID
  Future<Product?> getProductById(String productId) async {
    try {
      final response = await apiClient.get<Map<String, dynamic>>(
        '/api/v1/products/$productId',
      );
      return Product.fromJson(response);
    } on ApiException catch (e) {
      if (e.isNotFound) return null;
      rethrow;
    }
  }

  /// Get search autocomplete suggestions
  Future<List<SearchSuggestion>> getSearchSuggestions(String query) async {
    final response = await apiClient.get<List<dynamic>>(
      '/api/v1/products/autocomplete',
      queryParameters: {'query': query, 'limit': 10},
    );

    return response
        .map((e) => SearchSuggestion.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get trending searches
  Future<List<String>> getTrendingSearches() async {
    final response = await apiClient.get<List<dynamic>>(
      '/api/v1/products/trending-searches',
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
      '/api/v1/products/$productId/related',
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
      '/api/v1/products/$productId/reviews',
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
      '/api/v1/products/$productId/reviews',
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
      userName: json['user']?['first_name'] as String?,
      rating: json['rating'] as int,
      title: json['title'] as String?,
      comment: json['comment'] as String?,
      isVerifiedPurchase: json['is_verified_purchase'] as bool? ?? false,
      helpfulCount: json['helpful_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
