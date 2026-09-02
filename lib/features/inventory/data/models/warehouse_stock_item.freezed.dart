// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'warehouse_stock_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$WarehouseStockItem {

 String get productId; String get productName; String get sku; int get quantity; double get costPrice; double get sellingPrice; int get minStock;
/// Create a copy of WarehouseStockItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WarehouseStockItemCopyWith<WarehouseStockItem> get copyWith => _$WarehouseStockItemCopyWithImpl<WarehouseStockItem>(this as WarehouseStockItem, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WarehouseStockItem&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.productName, productName) || other.productName == productName)&&(identical(other.sku, sku) || other.sku == sku)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.costPrice, costPrice) || other.costPrice == costPrice)&&(identical(other.sellingPrice, sellingPrice) || other.sellingPrice == sellingPrice)&&(identical(other.minStock, minStock) || other.minStock == minStock));
}


@override
int get hashCode => Object.hash(runtimeType,productId,productName,sku,quantity,costPrice,sellingPrice,minStock);

@override
String toString() {
  return 'WarehouseStockItem(productId: $productId, productName: $productName, sku: $sku, quantity: $quantity, costPrice: $costPrice, sellingPrice: $sellingPrice, minStock: $minStock)';
}


}

/// @nodoc
abstract mixin class $WarehouseStockItemCopyWith<$Res>  {
  factory $WarehouseStockItemCopyWith(WarehouseStockItem value, $Res Function(WarehouseStockItem) _then) = _$WarehouseStockItemCopyWithImpl;
@useResult
$Res call({
 String productId, String productName, String sku, int quantity, double costPrice, double sellingPrice, int minStock
});




}
/// @nodoc
class _$WarehouseStockItemCopyWithImpl<$Res>
    implements $WarehouseStockItemCopyWith<$Res> {
  _$WarehouseStockItemCopyWithImpl(this._self, this._then);

  final WarehouseStockItem _self;
  final $Res Function(WarehouseStockItem) _then;

/// Create a copy of WarehouseStockItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? productId = null,Object? productName = null,Object? sku = null,Object? quantity = null,Object? costPrice = null,Object? sellingPrice = null,Object? minStock = null,}) {
  return _then(_self.copyWith(
productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String,productName: null == productName ? _self.productName : productName // ignore: cast_nullable_to_non_nullable
as String,sku: null == sku ? _self.sku : sku // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,costPrice: null == costPrice ? _self.costPrice : costPrice // ignore: cast_nullable_to_non_nullable
as double,sellingPrice: null == sellingPrice ? _self.sellingPrice : sellingPrice // ignore: cast_nullable_to_non_nullable
as double,minStock: null == minStock ? _self.minStock : minStock // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [WarehouseStockItem].
extension WarehouseStockItemPatterns on WarehouseStockItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WarehouseStockItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WarehouseStockItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WarehouseStockItem value)  $default,){
final _that = this;
switch (_that) {
case _WarehouseStockItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WarehouseStockItem value)?  $default,){
final _that = this;
switch (_that) {
case _WarehouseStockItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String productId,  String productName,  String sku,  int quantity,  double costPrice,  double sellingPrice,  int minStock)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WarehouseStockItem() when $default != null:
return $default(_that.productId,_that.productName,_that.sku,_that.quantity,_that.costPrice,_that.sellingPrice,_that.minStock);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String productId,  String productName,  String sku,  int quantity,  double costPrice,  double sellingPrice,  int minStock)  $default,) {final _that = this;
switch (_that) {
case _WarehouseStockItem():
return $default(_that.productId,_that.productName,_that.sku,_that.quantity,_that.costPrice,_that.sellingPrice,_that.minStock);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String productId,  String productName,  String sku,  int quantity,  double costPrice,  double sellingPrice,  int minStock)?  $default,) {final _that = this;
switch (_that) {
case _WarehouseStockItem() when $default != null:
return $default(_that.productId,_that.productName,_that.sku,_that.quantity,_that.costPrice,_that.sellingPrice,_that.minStock);case _:
  return null;

}
}

}

/// @nodoc


class _WarehouseStockItem extends WarehouseStockItem {
  const _WarehouseStockItem({required this.productId, required this.productName, required this.sku, required this.quantity, required this.costPrice, required this.sellingPrice, required this.minStock}): super._();
  

@override final  String productId;
@override final  String productName;
@override final  String sku;
@override final  int quantity;
@override final  double costPrice;
@override final  double sellingPrice;
@override final  int minStock;

/// Create a copy of WarehouseStockItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WarehouseStockItemCopyWith<_WarehouseStockItem> get copyWith => __$WarehouseStockItemCopyWithImpl<_WarehouseStockItem>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WarehouseStockItem&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.productName, productName) || other.productName == productName)&&(identical(other.sku, sku) || other.sku == sku)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.costPrice, costPrice) || other.costPrice == costPrice)&&(identical(other.sellingPrice, sellingPrice) || other.sellingPrice == sellingPrice)&&(identical(other.minStock, minStock) || other.minStock == minStock));
}


@override
int get hashCode => Object.hash(runtimeType,productId,productName,sku,quantity,costPrice,sellingPrice,minStock);

@override
String toString() {
  return 'WarehouseStockItem(productId: $productId, productName: $productName, sku: $sku, quantity: $quantity, costPrice: $costPrice, sellingPrice: $sellingPrice, minStock: $minStock)';
}


}

/// @nodoc
abstract mixin class _$WarehouseStockItemCopyWith<$Res> implements $WarehouseStockItemCopyWith<$Res> {
  factory _$WarehouseStockItemCopyWith(_WarehouseStockItem value, $Res Function(_WarehouseStockItem) _then) = __$WarehouseStockItemCopyWithImpl;
@override @useResult
$Res call({
 String productId, String productName, String sku, int quantity, double costPrice, double sellingPrice, int minStock
});




}
/// @nodoc
class __$WarehouseStockItemCopyWithImpl<$Res>
    implements _$WarehouseStockItemCopyWith<$Res> {
  __$WarehouseStockItemCopyWithImpl(this._self, this._then);

  final _WarehouseStockItem _self;
  final $Res Function(_WarehouseStockItem) _then;

/// Create a copy of WarehouseStockItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? productId = null,Object? productName = null,Object? sku = null,Object? quantity = null,Object? costPrice = null,Object? sellingPrice = null,Object? minStock = null,}) {
  return _then(_WarehouseStockItem(
productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String,productName: null == productName ? _self.productName : productName // ignore: cast_nullable_to_non_nullable
as String,sku: null == sku ? _self.sku : sku // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,costPrice: null == costPrice ? _self.costPrice : costPrice // ignore: cast_nullable_to_non_nullable
as double,sellingPrice: null == sellingPrice ? _self.sellingPrice : sellingPrice // ignore: cast_nullable_to_non_nullable
as double,minStock: null == minStock ? _self.minStock : minStock // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
