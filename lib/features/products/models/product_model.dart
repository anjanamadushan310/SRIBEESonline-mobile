/// SRIBEESonline - Product Model
///
/// Product data model with JSON serialization.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'product_model.freezed.dart';
part 'product_model.g.dart';

@freezed
class Product with _$Product {
  const factory Product({
    required String id,
    required String name,
    required String? description,
    required double price,
    double? salePrice,
    required int stockQuantity,
    required String categoryId,
    String? categoryName,
    String? brand,
    String? sku,
    @Default([]) List<ProductImage> images,
    @Default([]) List<ProductVariant> variants,
    double? averageRating,
    int? reviewCount,
    @Default(false) bool isFeatured,
    @Default(true) bool isActive,
    String? createdAt,
    String? updatedAt,
  }) = _Product;

  factory Product.fromJson(Map<String, dynamic> json) => _$ProductFromJson({
        'id': json['product_id'] ?? json['id'],
        'name': json['name'],
        'description': json['description'],
        'price': (json['price'] as num).toDouble(),
        'salePrice': json['sale_price'] != null
            ? (json['sale_price'] as num).toDouble()
            : null,
        'stockQuantity': json['stock_quantity'] ?? 0,
        'categoryId': json['category_id'] ?? '',
        'categoryName': json['category']?['name'],
        'brand': json['brand'],
        'sku': json['sku'],
        'images': json['images'] ?? [],
        'variants': json['variants'] ?? [],
        'averageRating': json['average_rating'] != null
            ? (json['average_rating'] as num).toDouble()
            : null,
        'reviewCount': json['review_count'],
        'isFeatured': json['is_featured'] ?? false,
        'isActive': json['is_active'] ?? true,
        'createdAt': json['created_at'],
        'updatedAt': json['updated_at'],
      });
}

extension ProductExtensions on Product {
  /// Get the effective price (sale price if available)
  double get effectivePrice => salePrice ?? price;

  /// Check if product is on sale
  bool get isOnSale => salePrice != null && salePrice! < price;

  /// Get discount percentage
  int get discountPercentage {
    if (!isOnSale) return 0;
    return ((price - salePrice!) / price * 100).round();
  }

  /// Check if in stock
  bool get isInStock => stockQuantity > 0;

  /// Get primary image URL
  String? get primaryImageUrl => images.isNotEmpty ? images.first.imageUrl : null;

  /// Check if has variants
  bool get hasVariants => variants.isNotEmpty;
}

@freezed
class ProductImage with _$ProductImage {
  const factory ProductImage({
    required String id,
    required String imageUrl,
    String? thumbnailUrl,
    @Default(false) bool isPrimary,
    @Default(0) int displayOrder,
  }) = _ProductImage;

  factory ProductImage.fromJson(Map<String, dynamic> json) =>
      _$ProductImageFromJson({
        'id': json['image_id'] ?? json['id'] ?? '',
        'imageUrl': json['image_url'] ?? json['url'] ?? '',
        'thumbnailUrl': json['thumbnail_url'],
        'isPrimary': json['is_primary'] ?? false,
        'displayOrder': json['display_order'] ?? 0,
      });
}

@freezed
class ProductVariant with _$ProductVariant {
  const factory ProductVariant({
    required String id,
    required String name,
    String? sku,
    double? priceAdjustment,
    int? stockQuantity,
    @Default([]) List<VariantOption> options,
  }) = _ProductVariant;

  factory ProductVariant.fromJson(Map<String, dynamic> json) =>
      _$ProductVariantFromJson({
        'id': json['variant_id'] ?? json['id'] ?? '',
        'name': json['name'] ?? '',
        'sku': json['sku'],
        'priceAdjustment': json['price_adjustment'] != null
            ? (json['price_adjustment'] as num).toDouble()
            : null,
        'stockQuantity': json['stock_quantity'],
        'options': json['options'] ?? [],
      });
}

@freezed
class VariantOption with _$VariantOption {
  const factory VariantOption({
    required String name,
    required String value,
  }) = _VariantOption;

  factory VariantOption.fromJson(Map<String, dynamic> json) =>
      _$VariantOptionFromJson(json);
}
