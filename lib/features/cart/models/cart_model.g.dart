// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cart_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CartItemImpl _$$CartItemImplFromJson(Map<String, dynamic> json) =>
    _$CartItemImpl(
      productId: json['productId'] as String,
      variantId: json['variantId'] as String?,
      quantity: (json['quantity'] as num).toInt(),
      price: (json['price'] as num).toDouble(),
      name: json['name'] as String,
      imageUrl: json['imageUrl'] as String?,
      addedAt: json['addedAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );

Map<String, dynamic> _$$CartItemImplToJson(_$CartItemImpl instance) =>
    <String, dynamic>{
      'productId': instance.productId,
      'variantId': instance.variantId,
      'quantity': instance.quantity,
      'price': instance.price,
      'name': instance.name,
      'imageUrl': instance.imageUrl,
      'addedAt': instance.addedAt,
      'updatedAt': instance.updatedAt,
    };

_$CartImpl _$$CartImplFromJson(Map<String, dynamic> json) => _$CartImpl(
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => CartItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      totals: json['totals'] == null
          ? null
          : CartTotals.fromJson(json['totals'] as Map<String, dynamic>),
      coupon: json['coupon'] == null
          ? null
          : AppliedCoupon.fromJson(json['coupon'] as Map<String, dynamic>),
      version: json['version'] as String?,
      updatedAt: (json['updatedAt'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$CartImplToJson(_$CartImpl instance) =>
    <String, dynamic>{
      'items': instance.items,
      'totals': instance.totals,
      'coupon': instance.coupon,
      'version': instance.version,
      'updatedAt': instance.updatedAt,
    };

_$CartTotalsImpl _$$CartTotalsImplFromJson(Map<String, dynamic> json) =>
    _$CartTotalsImpl(
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0,
      tax: (json['tax'] as num?)?.toDouble() ?? 0,
      shipping: (json['shipping'] as num?)?.toDouble() ?? 0,
      total: (json['total'] as num?)?.toDouble() ?? 0,
    );

Map<String, dynamic> _$$CartTotalsImplToJson(_$CartTotalsImpl instance) =>
    <String, dynamic>{
      'subtotal': instance.subtotal,
      'discount': instance.discount,
      'tax': instance.tax,
      'shipping': instance.shipping,
      'total': instance.total,
    };

_$AppliedCouponImpl _$$AppliedCouponImplFromJson(Map<String, dynamic> json) =>
    _$AppliedCouponImpl(
      code: json['code'] as String,
      discountType: json['discountType'] as String,
      discountValue: (json['discountValue'] as num).toDouble(),
    );

Map<String, dynamic> _$$AppliedCouponImplToJson(_$AppliedCouponImpl instance) =>
    <String, dynamic>{
      'code': instance.code,
      'discountType': instance.discountType,
      'discountValue': instance.discountValue,
    };
