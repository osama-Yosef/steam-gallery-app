// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'catalog_query.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CatalogQuery {

 String? get search; String? get categoryId; double? get minPrice; double? get maxPrice; bool get availableOnly; CatalogSort get sort;
/// Create a copy of CatalogQuery
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CatalogQueryCopyWith<CatalogQuery> get copyWith => _$CatalogQueryCopyWithImpl<CatalogQuery>(this as CatalogQuery, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CatalogQuery&&(identical(other.search, search) || other.search == search)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.minPrice, minPrice) || other.minPrice == minPrice)&&(identical(other.maxPrice, maxPrice) || other.maxPrice == maxPrice)&&(identical(other.availableOnly, availableOnly) || other.availableOnly == availableOnly)&&(identical(other.sort, sort) || other.sort == sort));
}


@override
int get hashCode => Object.hash(runtimeType,search,categoryId,minPrice,maxPrice,availableOnly,sort);

@override
String toString() {
  return 'CatalogQuery(search: $search, categoryId: $categoryId, minPrice: $minPrice, maxPrice: $maxPrice, availableOnly: $availableOnly, sort: $sort)';
}


}

/// @nodoc
abstract mixin class $CatalogQueryCopyWith<$Res>  {
  factory $CatalogQueryCopyWith(CatalogQuery value, $Res Function(CatalogQuery) _then) = _$CatalogQueryCopyWithImpl;
@useResult
$Res call({
 String? search, String? categoryId, double? minPrice, double? maxPrice, bool availableOnly, CatalogSort sort
});




}
/// @nodoc
class _$CatalogQueryCopyWithImpl<$Res>
    implements $CatalogQueryCopyWith<$Res> {
  _$CatalogQueryCopyWithImpl(this._self, this._then);

  final CatalogQuery _self;
  final $Res Function(CatalogQuery) _then;

/// Create a copy of CatalogQuery
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? search = freezed,Object? categoryId = freezed,Object? minPrice = freezed,Object? maxPrice = freezed,Object? availableOnly = null,Object? sort = null,}) {
  return _then(_self.copyWith(
search: freezed == search ? _self.search : search // ignore: cast_nullable_to_non_nullable
as String?,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,minPrice: freezed == minPrice ? _self.minPrice : minPrice // ignore: cast_nullable_to_non_nullable
as double?,maxPrice: freezed == maxPrice ? _self.maxPrice : maxPrice // ignore: cast_nullable_to_non_nullable
as double?,availableOnly: null == availableOnly ? _self.availableOnly : availableOnly // ignore: cast_nullable_to_non_nullable
as bool,sort: null == sort ? _self.sort : sort // ignore: cast_nullable_to_non_nullable
as CatalogSort,
  ));
}

}


/// Adds pattern-matching-related methods to [CatalogQuery].
extension CatalogQueryPatterns on CatalogQuery {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CatalogQuery value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CatalogQuery() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CatalogQuery value)  $default,){
final _that = this;
switch (_that) {
case _CatalogQuery():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CatalogQuery value)?  $default,){
final _that = this;
switch (_that) {
case _CatalogQuery() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? search,  String? categoryId,  double? minPrice,  double? maxPrice,  bool availableOnly,  CatalogSort sort)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CatalogQuery() when $default != null:
return $default(_that.search,_that.categoryId,_that.minPrice,_that.maxPrice,_that.availableOnly,_that.sort);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? search,  String? categoryId,  double? minPrice,  double? maxPrice,  bool availableOnly,  CatalogSort sort)  $default,) {final _that = this;
switch (_that) {
case _CatalogQuery():
return $default(_that.search,_that.categoryId,_that.minPrice,_that.maxPrice,_that.availableOnly,_that.sort);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? search,  String? categoryId,  double? minPrice,  double? maxPrice,  bool availableOnly,  CatalogSort sort)?  $default,) {final _that = this;
switch (_that) {
case _CatalogQuery() when $default != null:
return $default(_that.search,_that.categoryId,_that.minPrice,_that.maxPrice,_that.availableOnly,_that.sort);case _:
  return null;

}
}

}

/// @nodoc


class _CatalogQuery extends CatalogQuery {
  const _CatalogQuery({this.search, this.categoryId, this.minPrice, this.maxPrice, this.availableOnly = false, this.sort = CatalogSort.newest}): super._();
  

@override final  String? search;
@override final  String? categoryId;
@override final  double? minPrice;
@override final  double? maxPrice;
@override@JsonKey() final  bool availableOnly;
@override@JsonKey() final  CatalogSort sort;

/// Create a copy of CatalogQuery
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CatalogQueryCopyWith<_CatalogQuery> get copyWith => __$CatalogQueryCopyWithImpl<_CatalogQuery>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CatalogQuery&&(identical(other.search, search) || other.search == search)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.minPrice, minPrice) || other.minPrice == minPrice)&&(identical(other.maxPrice, maxPrice) || other.maxPrice == maxPrice)&&(identical(other.availableOnly, availableOnly) || other.availableOnly == availableOnly)&&(identical(other.sort, sort) || other.sort == sort));
}


@override
int get hashCode => Object.hash(runtimeType,search,categoryId,minPrice,maxPrice,availableOnly,sort);

@override
String toString() {
  return 'CatalogQuery(search: $search, categoryId: $categoryId, minPrice: $minPrice, maxPrice: $maxPrice, availableOnly: $availableOnly, sort: $sort)';
}


}

/// @nodoc
abstract mixin class _$CatalogQueryCopyWith<$Res> implements $CatalogQueryCopyWith<$Res> {
  factory _$CatalogQueryCopyWith(_CatalogQuery value, $Res Function(_CatalogQuery) _then) = __$CatalogQueryCopyWithImpl;
@override @useResult
$Res call({
 String? search, String? categoryId, double? minPrice, double? maxPrice, bool availableOnly, CatalogSort sort
});




}
/// @nodoc
class __$CatalogQueryCopyWithImpl<$Res>
    implements _$CatalogQueryCopyWith<$Res> {
  __$CatalogQueryCopyWithImpl(this._self, this._then);

  final _CatalogQuery _self;
  final $Res Function(_CatalogQuery) _then;

/// Create a copy of CatalogQuery
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? search = freezed,Object? categoryId = freezed,Object? minPrice = freezed,Object? maxPrice = freezed,Object? availableOnly = null,Object? sort = null,}) {
  return _then(_CatalogQuery(
search: freezed == search ? _self.search : search // ignore: cast_nullable_to_non_nullable
as String?,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,minPrice: freezed == minPrice ? _self.minPrice : minPrice // ignore: cast_nullable_to_non_nullable
as double?,maxPrice: freezed == maxPrice ? _self.maxPrice : maxPrice // ignore: cast_nullable_to_non_nullable
as double?,availableOnly: null == availableOnly ? _self.availableOnly : availableOnly // ignore: cast_nullable_to_non_nullable
as bool,sort: null == sort ? _self.sort : sort // ignore: cast_nullable_to_non_nullable
as CatalogSort,
  ));
}


}

/// @nodoc
mixin _$CatalogPage {

 List<ProductPublic> get items; bool get hasMore; bool get loadingMore; bool get loadMoreFailed;
/// Create a copy of CatalogPage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CatalogPageCopyWith<CatalogPage> get copyWith => _$CatalogPageCopyWithImpl<CatalogPage>(this as CatalogPage, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CatalogPage&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore)&&(identical(other.loadingMore, loadingMore) || other.loadingMore == loadingMore)&&(identical(other.loadMoreFailed, loadMoreFailed) || other.loadMoreFailed == loadMoreFailed));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(items),hasMore,loadingMore,loadMoreFailed);

@override
String toString() {
  return 'CatalogPage(items: $items, hasMore: $hasMore, loadingMore: $loadingMore, loadMoreFailed: $loadMoreFailed)';
}


}

/// @nodoc
abstract mixin class $CatalogPageCopyWith<$Res>  {
  factory $CatalogPageCopyWith(CatalogPage value, $Res Function(CatalogPage) _then) = _$CatalogPageCopyWithImpl;
@useResult
$Res call({
 List<ProductPublic> items, bool hasMore, bool loadingMore, bool loadMoreFailed
});




}
/// @nodoc
class _$CatalogPageCopyWithImpl<$Res>
    implements $CatalogPageCopyWith<$Res> {
  _$CatalogPageCopyWithImpl(this._self, this._then);

  final CatalogPage _self;
  final $Res Function(CatalogPage) _then;

/// Create a copy of CatalogPage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? hasMore = null,Object? loadingMore = null,Object? loadMoreFailed = null,}) {
  return _then(_self.copyWith(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<ProductPublic>,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,loadingMore: null == loadingMore ? _self.loadingMore : loadingMore // ignore: cast_nullable_to_non_nullable
as bool,loadMoreFailed: null == loadMoreFailed ? _self.loadMoreFailed : loadMoreFailed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [CatalogPage].
extension CatalogPagePatterns on CatalogPage {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CatalogPage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CatalogPage() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CatalogPage value)  $default,){
final _that = this;
switch (_that) {
case _CatalogPage():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CatalogPage value)?  $default,){
final _that = this;
switch (_that) {
case _CatalogPage() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<ProductPublic> items,  bool hasMore,  bool loadingMore,  bool loadMoreFailed)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CatalogPage() when $default != null:
return $default(_that.items,_that.hasMore,_that.loadingMore,_that.loadMoreFailed);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<ProductPublic> items,  bool hasMore,  bool loadingMore,  bool loadMoreFailed)  $default,) {final _that = this;
switch (_that) {
case _CatalogPage():
return $default(_that.items,_that.hasMore,_that.loadingMore,_that.loadMoreFailed);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<ProductPublic> items,  bool hasMore,  bool loadingMore,  bool loadMoreFailed)?  $default,) {final _that = this;
switch (_that) {
case _CatalogPage() when $default != null:
return $default(_that.items,_that.hasMore,_that.loadingMore,_that.loadMoreFailed);case _:
  return null;

}
}

}

/// @nodoc


class _CatalogPage implements CatalogPage {
  const _CatalogPage({required final  List<ProductPublic> items, required this.hasMore, this.loadingMore = false, this.loadMoreFailed = false}): _items = items;
  

 final  List<ProductPublic> _items;
@override List<ProductPublic> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override final  bool hasMore;
@override@JsonKey() final  bool loadingMore;
@override@JsonKey() final  bool loadMoreFailed;

/// Create a copy of CatalogPage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CatalogPageCopyWith<_CatalogPage> get copyWith => __$CatalogPageCopyWithImpl<_CatalogPage>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CatalogPage&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore)&&(identical(other.loadingMore, loadingMore) || other.loadingMore == loadingMore)&&(identical(other.loadMoreFailed, loadMoreFailed) || other.loadMoreFailed == loadMoreFailed));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),hasMore,loadingMore,loadMoreFailed);

@override
String toString() {
  return 'CatalogPage(items: $items, hasMore: $hasMore, loadingMore: $loadingMore, loadMoreFailed: $loadMoreFailed)';
}


}

/// @nodoc
abstract mixin class _$CatalogPageCopyWith<$Res> implements $CatalogPageCopyWith<$Res> {
  factory _$CatalogPageCopyWith(_CatalogPage value, $Res Function(_CatalogPage) _then) = __$CatalogPageCopyWithImpl;
@override @useResult
$Res call({
 List<ProductPublic> items, bool hasMore, bool loadingMore, bool loadMoreFailed
});




}
/// @nodoc
class __$CatalogPageCopyWithImpl<$Res>
    implements _$CatalogPageCopyWith<$Res> {
  __$CatalogPageCopyWithImpl(this._self, this._then);

  final _CatalogPage _self;
  final $Res Function(_CatalogPage) _then;

/// Create a copy of CatalogPage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? hasMore = null,Object? loadingMore = null,Object? loadMoreFailed = null,}) {
  return _then(_CatalogPage(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<ProductPublic>,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,loadingMore: null == loadingMore ? _self.loadingMore : loadingMore // ignore: cast_nullable_to_non_nullable
as bool,loadMoreFailed: null == loadMoreFailed ? _self.loadMoreFailed : loadMoreFailed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
