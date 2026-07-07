// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'cart_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

CartItem _$CartItemFromJson(Map<String, dynamic> json) {
  return _CartItem.fromJson(json);
}

/// @nodoc
mixin _$CartItem {
  String get productId => throw _privateConstructorUsedError;
  String? get variantId => throw _privateConstructorUsedError;
  int get quantity => throw _privateConstructorUsedError;
  double get price => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get imageUrl => throw _privateConstructorUsedError;
  String? get addedAt => throw _privateConstructorUsedError;
  String? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this CartItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CartItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CartItemCopyWith<CartItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CartItemCopyWith<$Res> {
  factory $CartItemCopyWith(CartItem value, $Res Function(CartItem) then) =
      _$CartItemCopyWithImpl<$Res, CartItem>;
  @useResult
  $Res call(
      {String productId,
      String? variantId,
      int quantity,
      double price,
      String name,
      String? imageUrl,
      String? addedAt,
      String? updatedAt});
}

/// @nodoc
class _$CartItemCopyWithImpl<$Res, $Val extends CartItem>
    implements $CartItemCopyWith<$Res> {
  _$CartItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CartItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? productId = null,
    Object? variantId = freezed,
    Object? quantity = null,
    Object? price = null,
    Object? name = null,
    Object? imageUrl = freezed,
    Object? addedAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_value.copyWith(
      productId: null == productId
          ? _value.productId
          : productId // ignore: cast_nullable_to_non_nullable
              as String,
      variantId: freezed == variantId
          ? _value.variantId
          : variantId // ignore: cast_nullable_to_non_nullable
              as String?,
      quantity: null == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as int,
      price: null == price
          ? _value.price
          : price // ignore: cast_nullable_to_non_nullable
              as double,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      imageUrl: freezed == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      addedAt: freezed == addedAt
          ? _value.addedAt
          : addedAt // ignore: cast_nullable_to_non_nullable
              as String?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CartItemImplCopyWith<$Res>
    implements $CartItemCopyWith<$Res> {
  factory _$$CartItemImplCopyWith(
          _$CartItemImpl value, $Res Function(_$CartItemImpl) then) =
      __$$CartItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String productId,
      String? variantId,
      int quantity,
      double price,
      String name,
      String? imageUrl,
      String? addedAt,
      String? updatedAt});
}

/// @nodoc
class __$$CartItemImplCopyWithImpl<$Res>
    extends _$CartItemCopyWithImpl<$Res, _$CartItemImpl>
    implements _$$CartItemImplCopyWith<$Res> {
  __$$CartItemImplCopyWithImpl(
      _$CartItemImpl _value, $Res Function(_$CartItemImpl) _then)
      : super(_value, _then);

  /// Create a copy of CartItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? productId = null,
    Object? variantId = freezed,
    Object? quantity = null,
    Object? price = null,
    Object? name = null,
    Object? imageUrl = freezed,
    Object? addedAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_$CartItemImpl(
      productId: null == productId
          ? _value.productId
          : productId // ignore: cast_nullable_to_non_nullable
              as String,
      variantId: freezed == variantId
          ? _value.variantId
          : variantId // ignore: cast_nullable_to_non_nullable
              as String?,
      quantity: null == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as int,
      price: null == price
          ? _value.price
          : price // ignore: cast_nullable_to_non_nullable
              as double,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      imageUrl: freezed == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      addedAt: freezed == addedAt
          ? _value.addedAt
          : addedAt // ignore: cast_nullable_to_non_nullable
              as String?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CartItemImpl implements _CartItem {
  const _$CartItemImpl(
      {required this.productId,
      this.variantId,
      required this.quantity,
      required this.price,
      required this.name,
      this.imageUrl,
      this.addedAt,
      this.updatedAt});

  factory _$CartItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$CartItemImplFromJson(json);

  @override
  final String productId;
  @override
  final String? variantId;
  @override
  final int quantity;
  @override
  final double price;
  @override
  final String name;
  @override
  final String? imageUrl;
  @override
  final String? addedAt;
  @override
  final String? updatedAt;

  @override
  String toString() {
    return 'CartItem(productId: $productId, variantId: $variantId, quantity: $quantity, price: $price, name: $name, imageUrl: $imageUrl, addedAt: $addedAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CartItemImpl &&
            (identical(other.productId, productId) ||
                other.productId == productId) &&
            (identical(other.variantId, variantId) ||
                other.variantId == variantId) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.price, price) || other.price == price) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            (identical(other.addedAt, addedAt) || other.addedAt == addedAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, productId, variantId, quantity,
      price, name, imageUrl, addedAt, updatedAt);

  /// Create a copy of CartItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CartItemImplCopyWith<_$CartItemImpl> get copyWith =>
      __$$CartItemImplCopyWithImpl<_$CartItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CartItemImplToJson(
      this,
    );
  }
}

abstract class _CartItem implements CartItem {
  const factory _CartItem(
      {required final String productId,
      final String? variantId,
      required final int quantity,
      required final double price,
      required final String name,
      final String? imageUrl,
      final String? addedAt,
      final String? updatedAt}) = _$CartItemImpl;

  factory _CartItem.fromJson(Map<String, dynamic> json) =
      _$CartItemImpl.fromJson;

  @override
  String get productId;
  @override
  String? get variantId;
  @override
  int get quantity;
  @override
  double get price;
  @override
  String get name;
  @override
  String? get imageUrl;
  @override
  String? get addedAt;
  @override
  String? get updatedAt;

  /// Create a copy of CartItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CartItemImplCopyWith<_$CartItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Cart _$CartFromJson(Map<String, dynamic> json) {
  return _Cart.fromJson(json);
}

/// @nodoc
mixin _$Cart {
  List<CartItem> get items => throw _privateConstructorUsedError;
  CartTotals? get totals => throw _privateConstructorUsedError;
  AppliedCoupon? get coupon => throw _privateConstructorUsedError;
  String? get version => throw _privateConstructorUsedError;
  int? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this Cart to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Cart
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CartCopyWith<Cart> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CartCopyWith<$Res> {
  factory $CartCopyWith(Cart value, $Res Function(Cart) then) =
      _$CartCopyWithImpl<$Res, Cart>;
  @useResult
  $Res call(
      {List<CartItem> items,
      CartTotals? totals,
      AppliedCoupon? coupon,
      String? version,
      int? updatedAt});

  $CartTotalsCopyWith<$Res>? get totals;
  $AppliedCouponCopyWith<$Res>? get coupon;
}

/// @nodoc
class _$CartCopyWithImpl<$Res, $Val extends Cart>
    implements $CartCopyWith<$Res> {
  _$CartCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Cart
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? totals = freezed,
    Object? coupon = freezed,
    Object? version = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_value.copyWith(
      items: null == items
          ? _value.items
          : items // ignore: cast_nullable_to_non_nullable
              as List<CartItem>,
      totals: freezed == totals
          ? _value.totals
          : totals // ignore: cast_nullable_to_non_nullable
              as CartTotals?,
      coupon: freezed == coupon
          ? _value.coupon
          : coupon // ignore: cast_nullable_to_non_nullable
              as AppliedCoupon?,
      version: freezed == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as String?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }

  /// Create a copy of Cart
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $CartTotalsCopyWith<$Res>? get totals {
    if (_value.totals == null) {
      return null;
    }

    return $CartTotalsCopyWith<$Res>(_value.totals!, (value) {
      return _then(_value.copyWith(totals: value) as $Val);
    });
  }

  /// Create a copy of Cart
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $AppliedCouponCopyWith<$Res>? get coupon {
    if (_value.coupon == null) {
      return null;
    }

    return $AppliedCouponCopyWith<$Res>(_value.coupon!, (value) {
      return _then(_value.copyWith(coupon: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$CartImplCopyWith<$Res> implements $CartCopyWith<$Res> {
  factory _$$CartImplCopyWith(
          _$CartImpl value, $Res Function(_$CartImpl) then) =
      __$$CartImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {List<CartItem> items,
      CartTotals? totals,
      AppliedCoupon? coupon,
      String? version,
      int? updatedAt});

  @override
  $CartTotalsCopyWith<$Res>? get totals;
  @override
  $AppliedCouponCopyWith<$Res>? get coupon;
}

/// @nodoc
class __$$CartImplCopyWithImpl<$Res>
    extends _$CartCopyWithImpl<$Res, _$CartImpl>
    implements _$$CartImplCopyWith<$Res> {
  __$$CartImplCopyWithImpl(_$CartImpl _value, $Res Function(_$CartImpl) _then)
      : super(_value, _then);

  /// Create a copy of Cart
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? totals = freezed,
    Object? coupon = freezed,
    Object? version = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_$CartImpl(
      items: null == items
          ? _value._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<CartItem>,
      totals: freezed == totals
          ? _value.totals
          : totals // ignore: cast_nullable_to_non_nullable
              as CartTotals?,
      coupon: freezed == coupon
          ? _value.coupon
          : coupon // ignore: cast_nullable_to_non_nullable
              as AppliedCoupon?,
      version: freezed == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as String?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CartImpl implements _Cart {
  const _$CartImpl(
      {final List<CartItem> items = const [],
      this.totals,
      this.coupon,
      this.version,
      this.updatedAt})
      : _items = items;

  factory _$CartImpl.fromJson(Map<String, dynamic> json) =>
      _$$CartImplFromJson(json);

  final List<CartItem> _items;
  @override
  @JsonKey()
  List<CartItem> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  final CartTotals? totals;
  @override
  final AppliedCoupon? coupon;
  @override
  final String? version;
  @override
  final int? updatedAt;

  @override
  String toString() {
    return 'Cart(items: $items, totals: $totals, coupon: $coupon, version: $version, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CartImpl &&
            const DeepCollectionEquality().equals(other._items, _items) &&
            (identical(other.totals, totals) || other.totals == totals) &&
            (identical(other.coupon, coupon) || other.coupon == coupon) &&
            (identical(other.version, version) || other.version == version) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_items),
      totals,
      coupon,
      version,
      updatedAt);

  /// Create a copy of Cart
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CartImplCopyWith<_$CartImpl> get copyWith =>
      __$$CartImplCopyWithImpl<_$CartImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CartImplToJson(
      this,
    );
  }
}

abstract class _Cart implements Cart {
  const factory _Cart(
      {final List<CartItem> items,
      final CartTotals? totals,
      final AppliedCoupon? coupon,
      final String? version,
      final int? updatedAt}) = _$CartImpl;

  factory _Cart.fromJson(Map<String, dynamic> json) = _$CartImpl.fromJson;

  @override
  List<CartItem> get items;
  @override
  CartTotals? get totals;
  @override
  AppliedCoupon? get coupon;
  @override
  String? get version;
  @override
  int? get updatedAt;

  /// Create a copy of Cart
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CartImplCopyWith<_$CartImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CartTotals _$CartTotalsFromJson(Map<String, dynamic> json) {
  return _CartTotals.fromJson(json);
}

/// @nodoc
mixin _$CartTotals {
  double get subtotal => throw _privateConstructorUsedError;
  double get discount => throw _privateConstructorUsedError;
  double get tax => throw _privateConstructorUsedError;
  double get shipping => throw _privateConstructorUsedError;
  double get total => throw _privateConstructorUsedError;

  /// Serializes this CartTotals to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CartTotals
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CartTotalsCopyWith<CartTotals> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CartTotalsCopyWith<$Res> {
  factory $CartTotalsCopyWith(
          CartTotals value, $Res Function(CartTotals) then) =
      _$CartTotalsCopyWithImpl<$Res, CartTotals>;
  @useResult
  $Res call(
      {double subtotal,
      double discount,
      double tax,
      double shipping,
      double total});
}

/// @nodoc
class _$CartTotalsCopyWithImpl<$Res, $Val extends CartTotals>
    implements $CartTotalsCopyWith<$Res> {
  _$CartTotalsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CartTotals
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? subtotal = null,
    Object? discount = null,
    Object? tax = null,
    Object? shipping = null,
    Object? total = null,
  }) {
    return _then(_value.copyWith(
      subtotal: null == subtotal
          ? _value.subtotal
          : subtotal // ignore: cast_nullable_to_non_nullable
              as double,
      discount: null == discount
          ? _value.discount
          : discount // ignore: cast_nullable_to_non_nullable
              as double,
      tax: null == tax
          ? _value.tax
          : tax // ignore: cast_nullable_to_non_nullable
              as double,
      shipping: null == shipping
          ? _value.shipping
          : shipping // ignore: cast_nullable_to_non_nullable
              as double,
      total: null == total
          ? _value.total
          : total // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CartTotalsImplCopyWith<$Res>
    implements $CartTotalsCopyWith<$Res> {
  factory _$$CartTotalsImplCopyWith(
          _$CartTotalsImpl value, $Res Function(_$CartTotalsImpl) then) =
      __$$CartTotalsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {double subtotal,
      double discount,
      double tax,
      double shipping,
      double total});
}

/// @nodoc
class __$$CartTotalsImplCopyWithImpl<$Res>
    extends _$CartTotalsCopyWithImpl<$Res, _$CartTotalsImpl>
    implements _$$CartTotalsImplCopyWith<$Res> {
  __$$CartTotalsImplCopyWithImpl(
      _$CartTotalsImpl _value, $Res Function(_$CartTotalsImpl) _then)
      : super(_value, _then);

  /// Create a copy of CartTotals
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? subtotal = null,
    Object? discount = null,
    Object? tax = null,
    Object? shipping = null,
    Object? total = null,
  }) {
    return _then(_$CartTotalsImpl(
      subtotal: null == subtotal
          ? _value.subtotal
          : subtotal // ignore: cast_nullable_to_non_nullable
              as double,
      discount: null == discount
          ? _value.discount
          : discount // ignore: cast_nullable_to_non_nullable
              as double,
      tax: null == tax
          ? _value.tax
          : tax // ignore: cast_nullable_to_non_nullable
              as double,
      shipping: null == shipping
          ? _value.shipping
          : shipping // ignore: cast_nullable_to_non_nullable
              as double,
      total: null == total
          ? _value.total
          : total // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CartTotalsImpl implements _CartTotals {
  const _$CartTotalsImpl(
      {this.subtotal = 0,
      this.discount = 0,
      this.tax = 0,
      this.shipping = 0,
      this.total = 0});

  factory _$CartTotalsImpl.fromJson(Map<String, dynamic> json) =>
      _$$CartTotalsImplFromJson(json);

  @override
  @JsonKey()
  final double subtotal;
  @override
  @JsonKey()
  final double discount;
  @override
  @JsonKey()
  final double tax;
  @override
  @JsonKey()
  final double shipping;
  @override
  @JsonKey()
  final double total;

  @override
  String toString() {
    return 'CartTotals(subtotal: $subtotal, discount: $discount, tax: $tax, shipping: $shipping, total: $total)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CartTotalsImpl &&
            (identical(other.subtotal, subtotal) ||
                other.subtotal == subtotal) &&
            (identical(other.discount, discount) ||
                other.discount == discount) &&
            (identical(other.tax, tax) || other.tax == tax) &&
            (identical(other.shipping, shipping) ||
                other.shipping == shipping) &&
            (identical(other.total, total) || other.total == total));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, subtotal, discount, tax, shipping, total);

  /// Create a copy of CartTotals
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CartTotalsImplCopyWith<_$CartTotalsImpl> get copyWith =>
      __$$CartTotalsImplCopyWithImpl<_$CartTotalsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CartTotalsImplToJson(
      this,
    );
  }
}

abstract class _CartTotals implements CartTotals {
  const factory _CartTotals(
      {final double subtotal,
      final double discount,
      final double tax,
      final double shipping,
      final double total}) = _$CartTotalsImpl;

  factory _CartTotals.fromJson(Map<String, dynamic> json) =
      _$CartTotalsImpl.fromJson;

  @override
  double get subtotal;
  @override
  double get discount;
  @override
  double get tax;
  @override
  double get shipping;
  @override
  double get total;

  /// Create a copy of CartTotals
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CartTotalsImplCopyWith<_$CartTotalsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AppliedCoupon _$AppliedCouponFromJson(Map<String, dynamic> json) {
  return _AppliedCoupon.fromJson(json);
}

/// @nodoc
mixin _$AppliedCoupon {
  String get code => throw _privateConstructorUsedError;
  String get discountType => throw _privateConstructorUsedError;
  double get discountValue => throw _privateConstructorUsedError;

  /// Serializes this AppliedCoupon to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AppliedCoupon
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AppliedCouponCopyWith<AppliedCoupon> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AppliedCouponCopyWith<$Res> {
  factory $AppliedCouponCopyWith(
          AppliedCoupon value, $Res Function(AppliedCoupon) then) =
      _$AppliedCouponCopyWithImpl<$Res, AppliedCoupon>;
  @useResult
  $Res call({String code, String discountType, double discountValue});
}

/// @nodoc
class _$AppliedCouponCopyWithImpl<$Res, $Val extends AppliedCoupon>
    implements $AppliedCouponCopyWith<$Res> {
  _$AppliedCouponCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AppliedCoupon
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? code = null,
    Object? discountType = null,
    Object? discountValue = null,
  }) {
    return _then(_value.copyWith(
      code: null == code
          ? _value.code
          : code // ignore: cast_nullable_to_non_nullable
              as String,
      discountType: null == discountType
          ? _value.discountType
          : discountType // ignore: cast_nullable_to_non_nullable
              as String,
      discountValue: null == discountValue
          ? _value.discountValue
          : discountValue // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AppliedCouponImplCopyWith<$Res>
    implements $AppliedCouponCopyWith<$Res> {
  factory _$$AppliedCouponImplCopyWith(
          _$AppliedCouponImpl value, $Res Function(_$AppliedCouponImpl) then) =
      __$$AppliedCouponImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String code, String discountType, double discountValue});
}

/// @nodoc
class __$$AppliedCouponImplCopyWithImpl<$Res>
    extends _$AppliedCouponCopyWithImpl<$Res, _$AppliedCouponImpl>
    implements _$$AppliedCouponImplCopyWith<$Res> {
  __$$AppliedCouponImplCopyWithImpl(
      _$AppliedCouponImpl _value, $Res Function(_$AppliedCouponImpl) _then)
      : super(_value, _then);

  /// Create a copy of AppliedCoupon
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? code = null,
    Object? discountType = null,
    Object? discountValue = null,
  }) {
    return _then(_$AppliedCouponImpl(
      code: null == code
          ? _value.code
          : code // ignore: cast_nullable_to_non_nullable
              as String,
      discountType: null == discountType
          ? _value.discountType
          : discountType // ignore: cast_nullable_to_non_nullable
              as String,
      discountValue: null == discountValue
          ? _value.discountValue
          : discountValue // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AppliedCouponImpl implements _AppliedCoupon {
  const _$AppliedCouponImpl(
      {required this.code,
      required this.discountType,
      required this.discountValue});

  factory _$AppliedCouponImpl.fromJson(Map<String, dynamic> json) =>
      _$$AppliedCouponImplFromJson(json);

  @override
  final String code;
  @override
  final String discountType;
  @override
  final double discountValue;

  @override
  String toString() {
    return 'AppliedCoupon(code: $code, discountType: $discountType, discountValue: $discountValue)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AppliedCouponImpl &&
            (identical(other.code, code) || other.code == code) &&
            (identical(other.discountType, discountType) ||
                other.discountType == discountType) &&
            (identical(other.discountValue, discountValue) ||
                other.discountValue == discountValue));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, code, discountType, discountValue);

  /// Create a copy of AppliedCoupon
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AppliedCouponImplCopyWith<_$AppliedCouponImpl> get copyWith =>
      __$$AppliedCouponImplCopyWithImpl<_$AppliedCouponImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AppliedCouponImplToJson(
      this,
    );
  }
}

abstract class _AppliedCoupon implements AppliedCoupon {
  const factory _AppliedCoupon(
      {required final String code,
      required final String discountType,
      required final double discountValue}) = _$AppliedCouponImpl;

  factory _AppliedCoupon.fromJson(Map<String, dynamic> json) =
      _$AppliedCouponImpl.fromJson;

  @override
  String get code;
  @override
  String get discountType;
  @override
  double get discountValue;

  /// Create a copy of AppliedCoupon
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AppliedCouponImplCopyWith<_$AppliedCouponImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
