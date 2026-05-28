/// SRIBEESonline - Cart Model
///
/// Cart item data model with JSON serialization.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'cart_model.freezed.dart';
part 'cart_model.g.dart';

@freezed
class CartItem with _$CartItem {
  const factory CartItem({
    required String productId,
    String? variantId,
    required int quantity,
    required double price,
    required String name,
    String? imageUrl,
    String? addedAt,
    String? updatedAt,
  }) = _CartItem;

  factory CartItem.fromJson(Map<String, dynamic> json) => _$CartItemFromJson({
        'productId': json['product_id'] ?? json['productId'],
        'variantId': json['variant_id'] ?? json['variantId'],
        'quantity': json['quantity'] ?? 1,
        'price': (json['price'] as num).toDouble(),
        'name': json['name'] ?? '',
        'imageUrl': json['image_url'] ?? json['imageUrl'],
        'addedAt': json['added_at'] ?? json['addedAt'],
        'updatedAt': json['updated_at'] ?? json['updatedAt'],
      });
}

extension CartItemExtensions on CartItem {
  /// Get total price for this item
  double get total => price * quantity;

  /// Get unique key for this cart item
  String get itemKey => '$productId:${variantId ?? ''}';
}

@freezed
class Cart with _$Cart {
  const factory Cart({
    @Default([]) List<CartItem> items,
    CartTotals? totals,
    AppliedCoupon? coupon,
    String? version,
    int? updatedAt,
  }) = _Cart;

  factory Cart.fromJson(Map<String, dynamic> json) => _$CartFromJson({
        'items': (json['items'] as List?)
                ?.map((e) => CartItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        'totals': json['totals'] != null
            ? CartTotals.fromJson(json['totals'] as Map<String, dynamic>)
            : null,
        'coupon': json['coupon'] != null
            ? AppliedCoupon.fromJson(json['coupon'] as Map<String, dynamic>)
            : null,
        'version': json['version'],
        'updatedAt': json['updated_at'] ?? json['updatedAt'],
      });
}

extension CartExtensions on Cart {
  /// Get total item count
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  /// Check if cart is empty
  bool get isEmpty => items.isEmpty;

  /// Get subtotal
  double get subtotal => totals?.subtotal ?? 0;

  /// Get total
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

  factory CartTotals.fromJson(Map<String, dynamic> json) => _$CartTotalsFromJson({
        'subtotal': (json['subtotal'] as num?)?.toDouble() ?? 0,
        'discount': (json['discount'] as num?)?.toDouble() ?? 0,
        'tax': (json['tax'] as num?)?.toDouble() ?? 0,
        'shipping': (json['shipping'] as num?)?.toDouble() ?? 0,
        'total': (json['total'] as num?)?.toDouble() ?? 0,
      });
}

@freezed
class AppliedCoupon with _$AppliedCoupon {
  const factory AppliedCoupon({
    required String code,
    required String discountType,
    required double discountValue,
  }) = _AppliedCoupon;

  factory AppliedCoupon.fromJson(Map<String, dynamic> json) =>
      _$AppliedCouponFromJson({
        'code': json['code'] ?? '',
        'discountType': json['discount_type'] ?? json['discountType'] ?? 'fixed',
        'discountValue':
            (json['discount_value'] ?? json['discountValue'] as num?)
                    ?.toDouble() ??
                0,
      });
}
