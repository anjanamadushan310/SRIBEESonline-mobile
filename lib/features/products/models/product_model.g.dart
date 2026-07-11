// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ProductImpl _$$ProductImplFromJson(Map<String, dynamic> json) =>
    _$ProductImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      price: (json['price'] as num).toDouble(),
      salePrice: (json['salePrice'] as num?)?.toDouble(),
      globalPrice: (json['globalPrice'] as num?)?.toDouble(),
      stockQuantity: (json['stockQuantity'] as num).toInt(),
      categoryId: json['categoryId'] as String,
      categoryName: json['categoryName'] as String?,
      subcategoryId: json['subcategoryId'] as String?,
      subcategoryName: json['subcategoryName'] as String?,
      brand: json['brand'] as String?,
      sku: json['sku'] as String?,
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => ProductImage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      variants: (json['variants'] as List<dynamic>?)
              ?.map((e) => ProductVariant.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      averageRating: (json['averageRating'] as num?)?.toDouble(),
      reviewCount: (json['reviewCount'] as num?)?.toInt(),
      isFeatured: json['isFeatured'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );

Map<String, dynamic> _$$ProductImplToJson(_$ProductImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'price': instance.price,
      'salePrice': instance.salePrice,
      'globalPrice': instance.globalPrice,
      'stockQuantity': instance.stockQuantity,
      'categoryId': instance.categoryId,
      'categoryName': instance.categoryName,
      'subcategoryId': instance.subcategoryId,
      'subcategoryName': instance.subcategoryName,
      'brand': instance.brand,
      'sku': instance.sku,
      'images': instance.images,
      'variants': instance.variants,
      'averageRating': instance.averageRating,
      'reviewCount': instance.reviewCount,
      'isFeatured': instance.isFeatured,
      'isActive': instance.isActive,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
    };

_$ProductImageImpl _$$ProductImageImplFromJson(Map<String, dynamic> json) =>
    _$ProductImageImpl(
      id: json['id'] as String,
      imageUrl: json['imageUrl'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      isPrimary: json['isPrimary'] as bool? ?? false,
      displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$ProductImageImplToJson(_$ProductImageImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'imageUrl': instance.imageUrl,
      'thumbnailUrl': instance.thumbnailUrl,
      'isPrimary': instance.isPrimary,
      'displayOrder': instance.displayOrder,
    };

_$ProductVariantImpl _$$ProductVariantImplFromJson(Map<String, dynamic> json) =>
    _$ProductVariantImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      sku: json['sku'] as String?,
      priceAdjustment: (json['priceAdjustment'] as num?)?.toDouble(),
      stockQuantity: (json['stockQuantity'] as num?)?.toInt(),
      options: (json['options'] as List<dynamic>?)
              ?.map((e) => VariantOption.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$ProductVariantImplToJson(
        _$ProductVariantImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'sku': instance.sku,
      'priceAdjustment': instance.priceAdjustment,
      'stockQuantity': instance.stockQuantity,
      'options': instance.options,
    };

_$VariantOptionImpl _$$VariantOptionImplFromJson(Map<String, dynamic> json) =>
    _$VariantOptionImpl(
      name: json['name'] as String,
      value: json['value'] as String,
    );

Map<String, dynamic> _$$VariantOptionImplToJson(_$VariantOptionImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'value': instance.value,
    };
