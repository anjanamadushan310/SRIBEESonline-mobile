// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'product_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$ProductListState {
  List<Product> get products => throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;
  bool get isLoadingMore => throw _privateConstructorUsedError;
  bool get hasReachedEnd => throw _privateConstructorUsedError;
  int get currentPage => throw _privateConstructorUsedError;
  int get pageSize => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;
  ProductFilters? get filters => throw _privateConstructorUsedError;

  /// Create a copy of ProductListState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProductListStateCopyWith<ProductListState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProductListStateCopyWith<$Res> {
  factory $ProductListStateCopyWith(
          ProductListState value, $Res Function(ProductListState) then) =
      _$ProductListStateCopyWithImpl<$Res, ProductListState>;
  @useResult
  $Res call(
      {List<Product> products,
      bool isLoading,
      bool isLoadingMore,
      bool hasReachedEnd,
      int currentPage,
      int pageSize,
      String? error,
      ProductFilters? filters});

  $ProductFiltersCopyWith<$Res>? get filters;
}

/// @nodoc
class _$ProductListStateCopyWithImpl<$Res, $Val extends ProductListState>
    implements $ProductListStateCopyWith<$Res> {
  _$ProductListStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProductListState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? products = null,
    Object? isLoading = null,
    Object? isLoadingMore = null,
    Object? hasReachedEnd = null,
    Object? currentPage = null,
    Object? pageSize = null,
    Object? error = freezed,
    Object? filters = freezed,
  }) {
    return _then(_value.copyWith(
      products: null == products
          ? _value.products
          : products // ignore: cast_nullable_to_non_nullable
              as List<Product>,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      isLoadingMore: null == isLoadingMore
          ? _value.isLoadingMore
          : isLoadingMore // ignore: cast_nullable_to_non_nullable
              as bool,
      hasReachedEnd: null == hasReachedEnd
          ? _value.hasReachedEnd
          : hasReachedEnd // ignore: cast_nullable_to_non_nullable
              as bool,
      currentPage: null == currentPage
          ? _value.currentPage
          : currentPage // ignore: cast_nullable_to_non_nullable
              as int,
      pageSize: null == pageSize
          ? _value.pageSize
          : pageSize // ignore: cast_nullable_to_non_nullable
              as int,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      filters: freezed == filters
          ? _value.filters
          : filters // ignore: cast_nullable_to_non_nullable
              as ProductFilters?,
    ) as $Val);
  }

  /// Create a copy of ProductListState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ProductFiltersCopyWith<$Res>? get filters {
    if (_value.filters == null) {
      return null;
    }

    return $ProductFiltersCopyWith<$Res>(_value.filters!, (value) {
      return _then(_value.copyWith(filters: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ProductListStateImplCopyWith<$Res>
    implements $ProductListStateCopyWith<$Res> {
  factory _$$ProductListStateImplCopyWith(_$ProductListStateImpl value,
          $Res Function(_$ProductListStateImpl) then) =
      __$$ProductListStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {List<Product> products,
      bool isLoading,
      bool isLoadingMore,
      bool hasReachedEnd,
      int currentPage,
      int pageSize,
      String? error,
      ProductFilters? filters});

  @override
  $ProductFiltersCopyWith<$Res>? get filters;
}

/// @nodoc
class __$$ProductListStateImplCopyWithImpl<$Res>
    extends _$ProductListStateCopyWithImpl<$Res, _$ProductListStateImpl>
    implements _$$ProductListStateImplCopyWith<$Res> {
  __$$ProductListStateImplCopyWithImpl(_$ProductListStateImpl _value,
      $Res Function(_$ProductListStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of ProductListState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? products = null,
    Object? isLoading = null,
    Object? isLoadingMore = null,
    Object? hasReachedEnd = null,
    Object? currentPage = null,
    Object? pageSize = null,
    Object? error = freezed,
    Object? filters = freezed,
  }) {
    return _then(_$ProductListStateImpl(
      products: null == products
          ? _value._products
          : products // ignore: cast_nullable_to_non_nullable
              as List<Product>,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      isLoadingMore: null == isLoadingMore
          ? _value.isLoadingMore
          : isLoadingMore // ignore: cast_nullable_to_non_nullable
              as bool,
      hasReachedEnd: null == hasReachedEnd
          ? _value.hasReachedEnd
          : hasReachedEnd // ignore: cast_nullable_to_non_nullable
              as bool,
      currentPage: null == currentPage
          ? _value.currentPage
          : currentPage // ignore: cast_nullable_to_non_nullable
              as int,
      pageSize: null == pageSize
          ? _value.pageSize
          : pageSize // ignore: cast_nullable_to_non_nullable
              as int,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      filters: freezed == filters
          ? _value.filters
          : filters // ignore: cast_nullable_to_non_nullable
              as ProductFilters?,
    ));
  }
}

/// @nodoc

class _$ProductListStateImpl implements _ProductListState {
  const _$ProductListStateImpl(
      {final List<Product> products = const [],
      this.isLoading = false,
      this.isLoadingMore = false,
      this.hasReachedEnd = false,
      this.currentPage = 1,
      this.pageSize = 20,
      this.error,
      this.filters})
      : _products = products;

  final List<Product> _products;
  @override
  @JsonKey()
  List<Product> get products {
    if (_products is EqualUnmodifiableListView) return _products;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_products);
  }

  @override
  @JsonKey()
  final bool isLoading;
  @override
  @JsonKey()
  final bool isLoadingMore;
  @override
  @JsonKey()
  final bool hasReachedEnd;
  @override
  @JsonKey()
  final int currentPage;
  @override
  @JsonKey()
  final int pageSize;
  @override
  final String? error;
  @override
  final ProductFilters? filters;

  @override
  String toString() {
    return 'ProductListState(products: $products, isLoading: $isLoading, isLoadingMore: $isLoadingMore, hasReachedEnd: $hasReachedEnd, currentPage: $currentPage, pageSize: $pageSize, error: $error, filters: $filters)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProductListStateImpl &&
            const DeepCollectionEquality().equals(other._products, _products) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.isLoadingMore, isLoadingMore) ||
                other.isLoadingMore == isLoadingMore) &&
            (identical(other.hasReachedEnd, hasReachedEnd) ||
                other.hasReachedEnd == hasReachedEnd) &&
            (identical(other.currentPage, currentPage) ||
                other.currentPage == currentPage) &&
            (identical(other.pageSize, pageSize) ||
                other.pageSize == pageSize) &&
            (identical(other.error, error) || other.error == error) &&
            (identical(other.filters, filters) || other.filters == filters));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_products),
      isLoading,
      isLoadingMore,
      hasReachedEnd,
      currentPage,
      pageSize,
      error,
      filters);

  /// Create a copy of ProductListState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProductListStateImplCopyWith<_$ProductListStateImpl> get copyWith =>
      __$$ProductListStateImplCopyWithImpl<_$ProductListStateImpl>(
          this, _$identity);
}

abstract class _ProductListState implements ProductListState {
  const factory _ProductListState(
      {final List<Product> products,
      final bool isLoading,
      final bool isLoadingMore,
      final bool hasReachedEnd,
      final int currentPage,
      final int pageSize,
      final String? error,
      final ProductFilters? filters}) = _$ProductListStateImpl;

  @override
  List<Product> get products;
  @override
  bool get isLoading;
  @override
  bool get isLoadingMore;
  @override
  bool get hasReachedEnd;
  @override
  int get currentPage;
  @override
  int get pageSize;
  @override
  String? get error;
  @override
  ProductFilters? get filters;

  /// Create a copy of ProductListState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProductListStateImplCopyWith<_$ProductListStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$ProductFilters {
  String? get query => throw _privateConstructorUsedError;
  String? get categoryId => throw _privateConstructorUsedError;
  List<String>? get categoryIds => throw _privateConstructorUsedError;
  double? get minPrice => throw _privateConstructorUsedError;
  double? get maxPrice => throw _privateConstructorUsedError;
  bool? get inStock => throw _privateConstructorUsedError;
  bool? get onSale => throw _privateConstructorUsedError;
  List<String>? get brands => throw _privateConstructorUsedError;
  double? get minRating => throw _privateConstructorUsedError;
  String get sortBy => throw _privateConstructorUsedError;
  String get sortOrder => throw _privateConstructorUsedError;

  /// Create a copy of ProductFilters
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProductFiltersCopyWith<ProductFilters> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProductFiltersCopyWith<$Res> {
  factory $ProductFiltersCopyWith(
          ProductFilters value, $Res Function(ProductFilters) then) =
      _$ProductFiltersCopyWithImpl<$Res, ProductFilters>;
  @useResult
  $Res call(
      {String? query,
      String? categoryId,
      List<String>? categoryIds,
      double? minPrice,
      double? maxPrice,
      bool? inStock,
      bool? onSale,
      List<String>? brands,
      double? minRating,
      String sortBy,
      String sortOrder});
}

/// @nodoc
class _$ProductFiltersCopyWithImpl<$Res, $Val extends ProductFilters>
    implements $ProductFiltersCopyWith<$Res> {
  _$ProductFiltersCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProductFilters
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? query = freezed,
    Object? categoryId = freezed,
    Object? categoryIds = freezed,
    Object? minPrice = freezed,
    Object? maxPrice = freezed,
    Object? inStock = freezed,
    Object? onSale = freezed,
    Object? brands = freezed,
    Object? minRating = freezed,
    Object? sortBy = null,
    Object? sortOrder = null,
  }) {
    return _then(_value.copyWith(
      query: freezed == query
          ? _value.query
          : query // ignore: cast_nullable_to_non_nullable
              as String?,
      categoryId: freezed == categoryId
          ? _value.categoryId
          : categoryId // ignore: cast_nullable_to_non_nullable
              as String?,
      categoryIds: freezed == categoryIds
          ? _value.categoryIds
          : categoryIds // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      minPrice: freezed == minPrice
          ? _value.minPrice
          : minPrice // ignore: cast_nullable_to_non_nullable
              as double?,
      maxPrice: freezed == maxPrice
          ? _value.maxPrice
          : maxPrice // ignore: cast_nullable_to_non_nullable
              as double?,
      inStock: freezed == inStock
          ? _value.inStock
          : inStock // ignore: cast_nullable_to_non_nullable
              as bool?,
      onSale: freezed == onSale
          ? _value.onSale
          : onSale // ignore: cast_nullable_to_non_nullable
              as bool?,
      brands: freezed == brands
          ? _value.brands
          : brands // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      minRating: freezed == minRating
          ? _value.minRating
          : minRating // ignore: cast_nullable_to_non_nullable
              as double?,
      sortBy: null == sortBy
          ? _value.sortBy
          : sortBy // ignore: cast_nullable_to_non_nullable
              as String,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ProductFiltersImplCopyWith<$Res>
    implements $ProductFiltersCopyWith<$Res> {
  factory _$$ProductFiltersImplCopyWith(_$ProductFiltersImpl value,
          $Res Function(_$ProductFiltersImpl) then) =
      __$$ProductFiltersImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String? query,
      String? categoryId,
      List<String>? categoryIds,
      double? minPrice,
      double? maxPrice,
      bool? inStock,
      bool? onSale,
      List<String>? brands,
      double? minRating,
      String sortBy,
      String sortOrder});
}

/// @nodoc
class __$$ProductFiltersImplCopyWithImpl<$Res>
    extends _$ProductFiltersCopyWithImpl<$Res, _$ProductFiltersImpl>
    implements _$$ProductFiltersImplCopyWith<$Res> {
  __$$ProductFiltersImplCopyWithImpl(
      _$ProductFiltersImpl _value, $Res Function(_$ProductFiltersImpl) _then)
      : super(_value, _then);

  /// Create a copy of ProductFilters
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? query = freezed,
    Object? categoryId = freezed,
    Object? categoryIds = freezed,
    Object? minPrice = freezed,
    Object? maxPrice = freezed,
    Object? inStock = freezed,
    Object? onSale = freezed,
    Object? brands = freezed,
    Object? minRating = freezed,
    Object? sortBy = null,
    Object? sortOrder = null,
  }) {
    return _then(_$ProductFiltersImpl(
      query: freezed == query
          ? _value.query
          : query // ignore: cast_nullable_to_non_nullable
              as String?,
      categoryId: freezed == categoryId
          ? _value.categoryId
          : categoryId // ignore: cast_nullable_to_non_nullable
              as String?,
      categoryIds: freezed == categoryIds
          ? _value._categoryIds
          : categoryIds // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      minPrice: freezed == minPrice
          ? _value.minPrice
          : minPrice // ignore: cast_nullable_to_non_nullable
              as double?,
      maxPrice: freezed == maxPrice
          ? _value.maxPrice
          : maxPrice // ignore: cast_nullable_to_non_nullable
              as double?,
      inStock: freezed == inStock
          ? _value.inStock
          : inStock // ignore: cast_nullable_to_non_nullable
              as bool?,
      onSale: freezed == onSale
          ? _value.onSale
          : onSale // ignore: cast_nullable_to_non_nullable
              as bool?,
      brands: freezed == brands
          ? _value._brands
          : brands // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      minRating: freezed == minRating
          ? _value.minRating
          : minRating // ignore: cast_nullable_to_non_nullable
              as double?,
      sortBy: null == sortBy
          ? _value.sortBy
          : sortBy // ignore: cast_nullable_to_non_nullable
              as String,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$ProductFiltersImpl implements _ProductFilters {
  const _$ProductFiltersImpl(
      {this.query,
      this.categoryId,
      final List<String>? categoryIds,
      this.minPrice,
      this.maxPrice,
      this.inStock,
      this.onSale,
      final List<String>? brands,
      this.minRating,
      this.sortBy = 'relevance',
      this.sortOrder = 'desc'})
      : _categoryIds = categoryIds,
        _brands = brands;

  @override
  final String? query;
  @override
  final String? categoryId;
  final List<String>? _categoryIds;
  @override
  List<String>? get categoryIds {
    final value = _categoryIds;
    if (value == null) return null;
    if (_categoryIds is EqualUnmodifiableListView) return _categoryIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final double? minPrice;
  @override
  final double? maxPrice;
  @override
  final bool? inStock;
  @override
  final bool? onSale;
  final List<String>? _brands;
  @override
  List<String>? get brands {
    final value = _brands;
    if (value == null) return null;
    if (_brands is EqualUnmodifiableListView) return _brands;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final double? minRating;
  @override
  @JsonKey()
  final String sortBy;
  @override
  @JsonKey()
  final String sortOrder;

  @override
  String toString() {
    return 'ProductFilters(query: $query, categoryId: $categoryId, categoryIds: $categoryIds, minPrice: $minPrice, maxPrice: $maxPrice, inStock: $inStock, onSale: $onSale, brands: $brands, minRating: $minRating, sortBy: $sortBy, sortOrder: $sortOrder)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProductFiltersImpl &&
            (identical(other.query, query) || other.query == query) &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            const DeepCollectionEquality()
                .equals(other._categoryIds, _categoryIds) &&
            (identical(other.minPrice, minPrice) ||
                other.minPrice == minPrice) &&
            (identical(other.maxPrice, maxPrice) ||
                other.maxPrice == maxPrice) &&
            (identical(other.inStock, inStock) || other.inStock == inStock) &&
            (identical(other.onSale, onSale) || other.onSale == onSale) &&
            const DeepCollectionEquality().equals(other._brands, _brands) &&
            (identical(other.minRating, minRating) ||
                other.minRating == minRating) &&
            (identical(other.sortBy, sortBy) || other.sortBy == sortBy) &&
            (identical(other.sortOrder, sortOrder) ||
                other.sortOrder == sortOrder));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      query,
      categoryId,
      const DeepCollectionEquality().hash(_categoryIds),
      minPrice,
      maxPrice,
      inStock,
      onSale,
      const DeepCollectionEquality().hash(_brands),
      minRating,
      sortBy,
      sortOrder);

  /// Create a copy of ProductFilters
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProductFiltersImplCopyWith<_$ProductFiltersImpl> get copyWith =>
      __$$ProductFiltersImplCopyWithImpl<_$ProductFiltersImpl>(
          this, _$identity);
}

abstract class _ProductFilters implements ProductFilters {
  const factory _ProductFilters(
      {final String? query,
      final String? categoryId,
      final List<String>? categoryIds,
      final double? minPrice,
      final double? maxPrice,
      final bool? inStock,
      final bool? onSale,
      final List<String>? brands,
      final double? minRating,
      final String sortBy,
      final String sortOrder}) = _$ProductFiltersImpl;

  @override
  String? get query;
  @override
  String? get categoryId;
  @override
  List<String>? get categoryIds;
  @override
  double? get minPrice;
  @override
  double? get maxPrice;
  @override
  bool? get inStock;
  @override
  bool? get onSale;
  @override
  List<String>? get brands;
  @override
  double? get minRating;
  @override
  String get sortBy;
  @override
  String get sortOrder;

  /// Create a copy of ProductFilters
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProductFiltersImplCopyWith<_$ProductFiltersImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
