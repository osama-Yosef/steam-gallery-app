// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'technician_bag_stock_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TechnicianBagStockItem {

 String get productId; String get productName; String get sku; int get quantity; double get costPrice; double get sellingPrice;
/// Create a copy of TechnicianBagStockItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TechnicianBagStockItemCopyWith<TechnicianBagStockItem> get copyWith => _$TechnicianBagStockItemCopyWithImpl<TechnicianBagStockItem>(this as TechnicianBagStockItem, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TechnicianBagStockItem&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.productName, productName) || other.productName == productName)&&(identical(other.sku, sku) || other.sku == sku)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.costPrice, costPrice) || other.costPrice == costPrice)&&(identical(other.sellingPrice, sellingPrice) || other.sellingPrice == sellingPrice));
}


@override
int get hashCode => Object.hash(runtimeType,productId,productName,sku,quantity,costPrice,sellingPrice);

@override
String toString() {
  return 'TechnicianBagStockItem(productId: $productId, productName: $productName, sku: $sku, quantity: $quantity, costPrice: $costPrice, sellingPrice: $sellingPrice)';
}


}

/// @nodoc
abstract mixin class $TechnicianBagStockItemCopyWith<$Res>  {
  factory $TechnicianBagStockItemCopyWith(TechnicianBagStockItem value, $Res Function(TechnicianBagStockItem) _then) = _$TechnicianBagStockItemCopyWithImpl;
@useResult
$Res call({
 String productId, String productName, String sku, int quantity, double costPrice, double sellingPrice
});




}
/// @nodoc
class _$TechnicianBagStockItemCopyWithImpl<$Res>
    implements $TechnicianBagStockItemCopyWith<$Res> {
  _$TechnicianBagStockItemCopyWithImpl(this._self, this._then);

  final TechnicianBagStockItem _self;
  final $Res Function(TechnicianBagStockItem) _then;

/// Create a copy of TechnicianBagStockItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? productId = null,Object? productName = null,Object? sku = null,Object? quantity = null,Object? costPrice = null,Object? sellingPrice = null,}) {
  return _then(_self.copyWith(
productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String,productName: null == productName ? _self.productName : productName // ignore: cast_nullable_to_non_nullable
as String,sku: null == sku ? _self.sku : sku // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,costPrice: null == costPrice ? _self.costPrice : costPrice // ignore: cast_nullable_to_non_nullable
as double,sellingPrice: null == sellingPrice ? _self.sellingPrice : sellingPrice // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [TechnicianBagStockItem].
extension TechnicianBagStockItemPatterns on TechnicianBagStockItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TechnicianBagStockItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TechnicianBagStockItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TechnicianBagStockItem value)  $default,){
final _that = this;
switch (_that) {
case _TechnicianBagStockItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TechnicianBagStockItem value)?  $default,){
final _that = this;
switch (_that) {
case _TechnicianBagStockItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String productId,  String productName,  String sku,  int quantity,  double costPrice,  double sellingPrice)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TechnicianBagStockItem() when $default != null:
return $default(_that.productId,_that.productName,_that.sku,_that.quantity,_that.costPrice,_that.sellingPrice);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String productId,  String productName,  String sku,  int quantity,  double costPrice,  double sellingPrice)  $default,) {final _that = this;
switch (_that) {
case _TechnicianBagStockItem():
return $default(_that.productId,_that.productName,_that.sku,_that.quantity,_that.costPrice,_that.sellingPrice);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String productId,  String productName,  String sku,  int quantity,  double costPrice,  double sellingPrice)?  $default,) {final _that = this;
switch (_that) {
case _TechnicianBagStockItem() when $default != null:
return $default(_that.productId,_that.productName,_that.sku,_that.quantity,_that.costPrice,_that.sellingPrice);case _:
  return null;

}
}

}

/// @nodoc


class _TechnicianBagStockItem extends TechnicianBagStockItem {
  const _TechnicianBagStockItem({required this.productId, required this.productName, required this.sku, required this.quantity, required this.costPrice, required this.sellingPrice}): super._();
  

@override final  String productId;
@override final  String productName;
@override final  String sku;
@override final  int quantity;
@override final  double costPrice;
@override final  double sellingPrice;

/// Create a copy of TechnicianBagStockItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TechnicianBagStockItemCopyWith<_TechnicianBagStockItem> get copyWith => __$TechnicianBagStockItemCopyWithImpl<_TechnicianBagStockItem>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TechnicianBagStockItem&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.productName, productName) || other.productName == productName)&&(identical(other.sku, sku) || other.sku == sku)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.costPrice, costPrice) || other.costPrice == costPrice)&&(identical(other.sellingPrice, sellingPrice) || other.sellingPrice == sellingPrice));
}


@override
int get hashCode => Object.hash(runtimeType,productId,productName,sku,quantity,costPrice,sellingPrice);

@override
String toString() {
  return 'TechnicianBagStockItem(productId: $productId, productName: $productName, sku: $sku, quantity: $quantity, costPrice: $costPrice, sellingPrice: $sellingPrice)';
}


}

/// @nodoc
abstract mixin class _$TechnicianBagStockItemCopyWith<$Res> implements $TechnicianBagStockItemCopyWith<$Res> {
  factory _$TechnicianBagStockItemCopyWith(_TechnicianBagStockItem value, $Res Function(_TechnicianBagStockItem) _then) = __$TechnicianBagStockItemCopyWithImpl;
@override @useResult
$Res call({
 String productId, String productName, String sku, int quantity, double costPrice, double sellingPrice
});




}
/// @nodoc
class __$TechnicianBagStockItemCopyWithImpl<$Res>
    implements _$TechnicianBagStockItemCopyWith<$Res> {
  __$TechnicianBagStockItemCopyWithImpl(this._self, this._then);

  final _TechnicianBagStockItem _self;
  final $Res Function(_TechnicianBagStockItem) _then;

/// Create a copy of TechnicianBagStockItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? productId = null,Object? productName = null,Object? sku = null,Object? quantity = null,Object? costPrice = null,Object? sellingPrice = null,}) {
  return _then(_TechnicianBagStockItem(
productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String,productName: null == productName ? _self.productName : productName // ignore: cast_nullable_to_non_nullable
as String,sku: null == sku ? _self.sku : sku // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,costPrice: null == costPrice ? _self.costPrice : costPrice // ignore: cast_nullable_to_non_nullable
as double,sellingPrice: null == sellingPrice ? _self.sellingPrice : sellingPrice // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
