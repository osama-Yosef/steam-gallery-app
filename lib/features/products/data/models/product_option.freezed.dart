// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'product_option.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ProductOption {

 String get id; String get productId; String get name; double get extraPrice; int get sortOrder;
/// Create a copy of ProductOption
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductOptionCopyWith<ProductOption> get copyWith => _$ProductOptionCopyWithImpl<ProductOption>(this as ProductOption, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProductOption&&(identical(other.id, id) || other.id == id)&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.name, name) || other.name == name)&&(identical(other.extraPrice, extraPrice) || other.extraPrice == extraPrice)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder));
}


@override
int get hashCode => Object.hash(runtimeType,id,productId,name,extraPrice,sortOrder);

@override
String toString() {
  return 'ProductOption(id: $id, productId: $productId, name: $name, extraPrice: $extraPrice, sortOrder: $sortOrder)';
}


}

/// @nodoc
abstract mixin class $ProductOptionCopyWith<$Res>  {
  factory $ProductOptionCopyWith(ProductOption value, $Res Function(ProductOption) _then) = _$ProductOptionCopyWithImpl;
@useResult
$Res call({
 String id, String productId, String name, double extraPrice, int sortOrder
});




}
/// @nodoc
class _$ProductOptionCopyWithImpl<$Res>
    implements $ProductOptionCopyWith<$Res> {
  _$ProductOptionCopyWithImpl(this._self, this._then);

  final ProductOption _self;
  final $Res Function(ProductOption) _then;

/// Create a copy of ProductOption
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? productId = null,Object? name = null,Object? extraPrice = null,Object? sortOrder = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,extraPrice: null == extraPrice ? _self.extraPrice : extraPrice // ignore: cast_nullable_to_non_nullable
as double,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ProductOption].
extension ProductOptionPatterns on ProductOption {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProductOption value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProductOption() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProductOption value)  $default,){
final _that = this;
switch (_that) {
case _ProductOption():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProductOption value)?  $default,){
final _that = this;
switch (_that) {
case _ProductOption() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String productId,  String name,  double extraPrice,  int sortOrder)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProductOption() when $default != null:
return $default(_that.id,_that.productId,_that.name,_that.extraPrice,_that.sortOrder);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String productId,  String name,  double extraPrice,  int sortOrder)  $default,) {final _that = this;
switch (_that) {
case _ProductOption():
return $default(_that.id,_that.productId,_that.name,_that.extraPrice,_that.sortOrder);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String productId,  String name,  double extraPrice,  int sortOrder)?  $default,) {final _that = this;
switch (_that) {
case _ProductOption() when $default != null:
return $default(_that.id,_that.productId,_that.name,_that.extraPrice,_that.sortOrder);case _:
  return null;

}
}

}

/// @nodoc


class _ProductOption implements ProductOption {
  const _ProductOption({required this.id, required this.productId, required this.name, required this.extraPrice, required this.sortOrder});
  

@override final  String id;
@override final  String productId;
@override final  String name;
@override final  double extraPrice;
@override final  int sortOrder;

/// Create a copy of ProductOption
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProductOptionCopyWith<_ProductOption> get copyWith => __$ProductOptionCopyWithImpl<_ProductOption>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProductOption&&(identical(other.id, id) || other.id == id)&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.name, name) || other.name == name)&&(identical(other.extraPrice, extraPrice) || other.extraPrice == extraPrice)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder));
}


@override
int get hashCode => Object.hash(runtimeType,id,productId,name,extraPrice,sortOrder);

@override
String toString() {
  return 'ProductOption(id: $id, productId: $productId, name: $name, extraPrice: $extraPrice, sortOrder: $sortOrder)';
}


}

/// @nodoc
abstract mixin class _$ProductOptionCopyWith<$Res> implements $ProductOptionCopyWith<$Res> {
  factory _$ProductOptionCopyWith(_ProductOption value, $Res Function(_ProductOption) _then) = __$ProductOptionCopyWithImpl;
@override @useResult
$Res call({
 String id, String productId, String name, double extraPrice, int sortOrder
});




}
/// @nodoc
class __$ProductOptionCopyWithImpl<$Res>
    implements _$ProductOptionCopyWith<$Res> {
  __$ProductOptionCopyWithImpl(this._self, this._then);

  final _ProductOption _self;
  final $Res Function(_ProductOption) _then;

/// Create a copy of ProductOption
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? productId = null,Object? name = null,Object? extraPrice = null,Object? sortOrder = null,}) {
  return _then(_ProductOption(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,extraPrice: null == extraPrice ? _self.extraPrice : extraPrice // ignore: cast_nullable_to_non_nullable
as double,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
