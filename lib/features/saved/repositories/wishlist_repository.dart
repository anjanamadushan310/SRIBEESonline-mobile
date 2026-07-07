/// SRIBEESonline - Wishlist Repository
///
/// Interfaces with the variant-aware backend wishlist:
///
///   GET    /wishlist                          - list saved items
///   POST   /wishlist                          - add {product_id, variant_id?, price_at_watch?}
///   DELETE /wishlist/{product_id}?variant_id= - remove item
///
/// Items are keyed by (product_id, variant_id) — variant_id is null for the
/// base product, which is the common case in the current UI.
library;

import '../../../core/api/api_client.dart';

/// A saved wishlist entry (variant-aware).
class WishlistItem {
  final String wishlistItemId;
  final String productId;
  final String? variantId;
  final double? priceAtWatch;
  final DateTime? addedAt;

  // Embedded product snapshot (from the GET /wishlist join).
  final String name;
  final double price;
  final String? imageUrl;

  // Variant extras (when variant_id is set).
  final String? variantName;
  final double? currentPrice;
  final double priceDrop;
  final double priceDropPercentage;

  const WishlistItem({
    required this.wishlistItemId,
    required this.productId,
    this.variantId,
    this.priceAtWatch,
    this.addedAt,
    required this.name,
    required this.price,
    this.imageUrl,
    this.variantName,
    this.currentPrice,
    this.priceDrop = 0,
    this.priceDropPercentage = 0,
  });

  /// Effective display price: variant's live price when present, else the
  /// product's price, else the price captured at watch time.
  double get effectivePrice =>
      currentPrice ?? (price > 0 ? price : (priceAtWatch ?? 0));

  /// Unique key for (product, variant) lookups.
  String get key => wishlistKey(productId, variantId);

  factory WishlistItem.fromJson(Map<String, dynamic> json) {
    final product = (json['product'] as Map?) ?? const {};
    final images = (product['images'] as List?) ?? const [];
    String? imageUrl;
    if (images.isNotEmpty) {
      imageUrl = ((images.first as Map)['image_url'] ?? '').toString();
      if (imageUrl.isEmpty) imageUrl = null;
    }

    return WishlistItem(
      wishlistItemId: (json['wishlist_item_id'] ?? '').toString(),
      productId:
          (json['product_id'] ?? product['product_id'] ?? '').toString(),
      variantId: json['variant_id']?.toString(),
      priceAtWatch: (json['price_at_watch'] as num?)?.toDouble(),
      addedAt: json['added_at'] != null
          ? DateTime.tryParse(json['added_at'].toString())
          : null,
      name: (product['name'] ?? 'Product').toString(),
      price: (product['price'] as num?)?.toDouble() ?? 0,
      imageUrl: imageUrl,
      variantName: json['variant_name'] as String?,
      currentPrice: (json['current_price'] as num?)?.toDouble(),
      priceDrop: (json['price_drop'] as num?)?.toDouble() ?? 0,
      priceDropPercentage:
          (json['price_drop_percentage'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Canonical (product, variant) key used across wishlist state.
String wishlistKey(String productId, String? variantId) =>
    '$productId:${variantId ?? ''}';

class WishlistRepository {
  final ApiClient _api;

  WishlistRepository(this._api);

  /// GET /wishlist — the user's saved items.
  Future<List<WishlistItem>> getWishlist() async {
    final response = await _api.get<Map<String, dynamic>>('/wishlist');
    final data = (response['data'] as Map?) ?? const {};
    return (data['items'] as List?)
            ?.map((e) =>
                WishlistItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList() ??
        [];
  }

  /// POST /wishlist — add an item (base product when variantId is null).
  Future<void> addItem({
    required String productId,
    String? variantId,
    double? priceAtWatch,
  }) async {
    await _api.post<Map<String, dynamic>>(
      '/wishlist',
      data: {
        'product_id': productId,
        if (variantId != null) 'variant_id': variantId,
        if (priceAtWatch != null) 'price_at_watch': priceAtWatch,
      },
    );
  }

  /// DELETE /wishlist/{product_id} — remove an item.
  Future<void> removeItem({
    required String productId,
    String? variantId,
  }) async {
    await _api.delete(
      variantId != null
          ? '/wishlist/$productId?variant_id=$variantId'
          : '/wishlist/$productId',
    );
  }
}
