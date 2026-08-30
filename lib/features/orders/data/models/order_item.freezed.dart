// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'order_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OrderItem {

 String get id; String get orderId; String get productId; String get productNameSnapshot; int get quantity; double get unitPriceSnapshot; double get discount; double get lineTotal;
/// Create a copy of OrderItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrderItemCopyWith<OrderItem> get copyWith => _$OrderItemCopyWithImpl<OrderItem>(this as OrderItem, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrderItem&&(identical(other.id, id) || other.id == id)&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.productNameSnapshot, productNameSnapshot) || other.productNameSnapshot == productNameSnapshot)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.unitPriceSnapshot, unitPriceSnapshot) || other.unitPriceSnapshot == unitPriceSnapshot)&&(identical(other.discount, discount) || other.discount == discount)&&(identical(other.lineTotal, lineTotal) || other.lineTotal == lineTotal));
}


@override
int get hashCode => Object.hash(runtimeType,id,orderId,productId,productNameSnapshot,quantity,unitPriceSnapshot,discount,lineTotal);

@override
String toString() {
  return 'OrderItem(id: $id, orderId: $orderId, productId: $productId, productNameSnapshot: $productNameSnapshot, quantity: $quantity, unitPriceSnapshot: $unitPriceSnapshot, discount: $discount, lineTotal: $lineTotal)';
}


}

/// @nodoc
abstract mixin class $OrderItemCopyWith<$Res>  {
  factory $OrderItemCopyWith(OrderItem value, $Res Function(OrderItem) _then) = _$OrderItemCopyWithImpl;
@useResult
$Res call({
 String id, String orderId, String productId, String productNameSnapshot, int quantity, double unitPriceSnapshot, double discount, double lineTotal
});




}
/// @nodoc
class _$OrderItemCopyWithImpl<$Res>
    implements $OrderItemCopyWith<$Res> {
  _$OrderItemCopyWithImpl(this._self, this._then);

  final OrderItem _self;
  final $Res Function(OrderItem) _then;

/// Create a copy of OrderItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? orderId = null,Object? productId = null,Object? productNameSnapshot = null,Object? quantity = null,Object? unitPriceSnapshot = null,Object? discount = null,Object? lineTotal = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,orderId: null == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as String,productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String,productNameSnapshot: null == productNameSnapshot ? _self.productNameSnapshot : productNameSnapshot // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,unitPriceSnapshot: null == unitPriceSnapshot ? _self.unitPriceSnapshot : unitPriceSnapshot // ignore: cast_nullable_to_non_nullable
as double,discount: null == discount ? _self.discount : discount // ignore: cast_nullable_to_non_nullable
as double,lineTotal: null == lineTotal ? _self.lineTotal : lineTotal // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [OrderItem].
extension OrderItemPatterns on OrderItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OrderItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OrderItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OrderItem value)  $default,){
final _that = this;
switch (_that) {
case _OrderItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OrderItem value)?  $default,){
final _that = this;
switch (_that) {
case _OrderItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String orderId,  String productId,  String productNameSnapshot,  int quantity,  double unitPriceSnapshot,  double discount,  double lineTotal)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OrderItem() when $default != null:
return $default(_that.id,_that.orderId,_that.productId,_that.productNameSnapshot,_that.quantity,_that.unitPriceSnapshot,_that.discount,_that.lineTotal);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String orderId,  String productId,  String productNameSnapshot,  int quantity,  double unitPriceSnapshot,  double discount,  double lineTotal)  $default,) {final _that = this;
switch (_that) {
case _OrderItem():
return $default(_that.id,_that.orderId,_that.productId,_that.productNameSnapshot,_that.quantity,_that.unitPriceSnapshot,_that.discount,_that.lineTotal);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String orderId,  String productId,  String productNameSnapshot,  int quantity,  double unitPriceSnapshot,  double discount,  double lineTotal)?  $default,) {final _that = this;
switch (_that) {
case _OrderItem() when $default != null:
return $default(_that.id,_that.orderId,_that.productId,_that.productNameSnapshot,_that.quantity,_that.unitPriceSnapshot,_that.discount,_that.lineTotal);case _:
  return null;

}
}

}

/// @nodoc


class _OrderItem implements OrderItem {
  const _OrderItem({required this.id, required this.orderId, required this.productId, required this.productNameSnapshot, required this.quantity, required this.unitPriceSnapshot, required this.discount, required this.lineTotal});
  

@override final  String id;
@override final  String orderId;
@override final  String productId;
@override final  String productNameSnapshot;
@override final  int quantity;
@override final  double unitPriceSnapshot;
@override final  double discount;
@override final  double lineTotal;

/// Create a copy of OrderItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrderItemCopyWith<_OrderItem> get copyWith => __$OrderItemCopyWithImpl<_OrderItem>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OrderItem&&(identical(other.id, id) || other.id == id)&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.productNameSnapshot, productNameSnapshot) || other.productNameSnapshot == productNameSnapshot)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.unitPriceSnapshot, unitPriceSnapshot) || other.unitPriceSnapshot == unitPriceSnapshot)&&(identical(other.discount, discount) || other.discount == discount)&&(identical(other.lineTotal, lineTotal) || other.lineTotal == lineTotal));
}


@override
int get hashCode => Object.hash(runtimeType,id,orderId,productId,productNameSnapshot,quantity,unitPriceSnapshot,discount,lineTotal);

@override
String toString() {
  return 'OrderItem(id: $id, orderId: $orderId, productId: $productId, productNameSnapshot: $productNameSnapshot, quantity: $quantity, unitPriceSnapshot: $unitPriceSnapshot, discount: $discount, lineTotal: $lineTotal)';
}


}

/// @nodoc
abstract mixin class _$OrderItemCopyWith<$Res> implements $OrderItemCopyWith<$Res> {
  factory _$OrderItemCopyWith(_OrderItem value, $Res Function(_OrderItem) _then) = __$OrderItemCopyWithImpl;
@override @useResult
$Res call({
 String id, String orderId, String productId, String productNameSnapshot, int quantity, double unitPriceSnapshot, double discount, double lineTotal
});




}
/// @nodoc
class __$OrderItemCopyWithImpl<$Res>
    implements _$OrderItemCopyWith<$Res> {
  __$OrderItemCopyWithImpl(this._self, this._then);

  final _OrderItem _self;
  final $Res Function(_OrderItem) _then;

/// Create a copy of OrderItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? orderId = null,Object? productId = null,Object? productNameSnapshot = null,Object? quantity = null,Object? unitPriceSnapshot = null,Object? discount = null,Object? lineTotal = null,}) {
  return _then(_OrderItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,orderId: null == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as String,productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String,productNameSnapshot: null == productNameSnapshot ? _self.productNameSnapshot : productNameSnapshot // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,unitPriceSnapshot: null == unitPriceSnapshot ? _self.unitPriceSnapshot : unitPriceSnapshot // ignore: cast_nullable_to_non_nullable
as double,discount: null == discount ? _self.discount : discount // ignore: cast_nullable_to_non_nullable
as double,lineTotal: null == lineTotal ? _self.lineTotal : lineTotal // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
