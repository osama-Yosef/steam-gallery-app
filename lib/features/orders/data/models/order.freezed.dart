// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'order.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Order {

 String get id; int get orderNumber; String get customerId; OrderStatus get status; double get subtotal; double get discount; double get total; double get paidAmount; String? get deliveryAddress; String? get notes; String? get cancelledReason; DateTime get createdAt;
/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrderCopyWith<Order> get copyWith => _$OrderCopyWithImpl<Order>(this as Order, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Order&&(identical(other.id, id) || other.id == id)&&(identical(other.orderNumber, orderNumber) || other.orderNumber == orderNumber)&&(identical(other.customerId, customerId) || other.customerId == customerId)&&(identical(other.status, status) || other.status == status)&&(identical(other.subtotal, subtotal) || other.subtotal == subtotal)&&(identical(other.discount, discount) || other.discount == discount)&&(identical(other.total, total) || other.total == total)&&(identical(other.paidAmount, paidAmount) || other.paidAmount == paidAmount)&&(identical(other.deliveryAddress, deliveryAddress) || other.deliveryAddress == deliveryAddress)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.cancelledReason, cancelledReason) || other.cancelledReason == cancelledReason)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,orderNumber,customerId,status,subtotal,discount,total,paidAmount,deliveryAddress,notes,cancelledReason,createdAt);

@override
String toString() {
  return 'Order(id: $id, orderNumber: $orderNumber, customerId: $customerId, status: $status, subtotal: $subtotal, discount: $discount, total: $total, paidAmount: $paidAmount, deliveryAddress: $deliveryAddress, notes: $notes, cancelledReason: $cancelledReason, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $OrderCopyWith<$Res>  {
  factory $OrderCopyWith(Order value, $Res Function(Order) _then) = _$OrderCopyWithImpl;
@useResult
$Res call({
 String id, int orderNumber, String customerId, OrderStatus status, double subtotal, double discount, double total, double paidAmount, String? deliveryAddress, String? notes, String? cancelledReason, DateTime createdAt
});




}
/// @nodoc
class _$OrderCopyWithImpl<$Res>
    implements $OrderCopyWith<$Res> {
  _$OrderCopyWithImpl(this._self, this._then);

  final Order _self;
  final $Res Function(Order) _then;

/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? orderNumber = null,Object? customerId = null,Object? status = null,Object? subtotal = null,Object? discount = null,Object? total = null,Object? paidAmount = null,Object? deliveryAddress = freezed,Object? notes = freezed,Object? cancelledReason = freezed,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,orderNumber: null == orderNumber ? _self.orderNumber : orderNumber // ignore: cast_nullable_to_non_nullable
as int,customerId: null == customerId ? _self.customerId : customerId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as OrderStatus,subtotal: null == subtotal ? _self.subtotal : subtotal // ignore: cast_nullable_to_non_nullable
as double,discount: null == discount ? _self.discount : discount // ignore: cast_nullable_to_non_nullable
as double,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as double,paidAmount: null == paidAmount ? _self.paidAmount : paidAmount // ignore: cast_nullable_to_non_nullable
as double,deliveryAddress: freezed == deliveryAddress ? _self.deliveryAddress : deliveryAddress // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,cancelledReason: freezed == cancelledReason ? _self.cancelledReason : cancelledReason // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [Order].
extension OrderPatterns on Order {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Order value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Order() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Order value)  $default,){
final _that = this;
switch (_that) {
case _Order():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Order value)?  $default,){
final _that = this;
switch (_that) {
case _Order() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  int orderNumber,  String customerId,  OrderStatus status,  double subtotal,  double discount,  double total,  double paidAmount,  String? deliveryAddress,  String? notes,  String? cancelledReason,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Order() when $default != null:
return $default(_that.id,_that.orderNumber,_that.customerId,_that.status,_that.subtotal,_that.discount,_that.total,_that.paidAmount,_that.deliveryAddress,_that.notes,_that.cancelledReason,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  int orderNumber,  String customerId,  OrderStatus status,  double subtotal,  double discount,  double total,  double paidAmount,  String? deliveryAddress,  String? notes,  String? cancelledReason,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _Order():
return $default(_that.id,_that.orderNumber,_that.customerId,_that.status,_that.subtotal,_that.discount,_that.total,_that.paidAmount,_that.deliveryAddress,_that.notes,_that.cancelledReason,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  int orderNumber,  String customerId,  OrderStatus status,  double subtotal,  double discount,  double total,  double paidAmount,  String? deliveryAddress,  String? notes,  String? cancelledReason,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _Order() when $default != null:
return $default(_that.id,_that.orderNumber,_that.customerId,_that.status,_that.subtotal,_that.discount,_that.total,_that.paidAmount,_that.deliveryAddress,_that.notes,_that.cancelledReason,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc


class _Order extends Order {
  const _Order({required this.id, required this.orderNumber, required this.customerId, required this.status, required this.subtotal, required this.discount, required this.total, required this.paidAmount, this.deliveryAddress, this.notes, this.cancelledReason, required this.createdAt}): super._();
  

@override final  String id;
@override final  int orderNumber;
@override final  String customerId;
@override final  OrderStatus status;
@override final  double subtotal;
@override final  double discount;
@override final  double total;
@override final  double paidAmount;
@override final  String? deliveryAddress;
@override final  String? notes;
@override final  String? cancelledReason;
@override final  DateTime createdAt;

/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrderCopyWith<_Order> get copyWith => __$OrderCopyWithImpl<_Order>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Order&&(identical(other.id, id) || other.id == id)&&(identical(other.orderNumber, orderNumber) || other.orderNumber == orderNumber)&&(identical(other.customerId, customerId) || other.customerId == customerId)&&(identical(other.status, status) || other.status == status)&&(identical(other.subtotal, subtotal) || other.subtotal == subtotal)&&(identical(other.discount, discount) || other.discount == discount)&&(identical(other.total, total) || other.total == total)&&(identical(other.paidAmount, paidAmount) || other.paidAmount == paidAmount)&&(identical(other.deliveryAddress, deliveryAddress) || other.deliveryAddress == deliveryAddress)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.cancelledReason, cancelledReason) || other.cancelledReason == cancelledReason)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,orderNumber,customerId,status,subtotal,discount,total,paidAmount,deliveryAddress,notes,cancelledReason,createdAt);

@override
String toString() {
  return 'Order(id: $id, orderNumber: $orderNumber, customerId: $customerId, status: $status, subtotal: $subtotal, discount: $discount, total: $total, paidAmount: $paidAmount, deliveryAddress: $deliveryAddress, notes: $notes, cancelledReason: $cancelledReason, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$OrderCopyWith<$Res> implements $OrderCopyWith<$Res> {
  factory _$OrderCopyWith(_Order value, $Res Function(_Order) _then) = __$OrderCopyWithImpl;
@override @useResult
$Res call({
 String id, int orderNumber, String customerId, OrderStatus status, double subtotal, double discount, double total, double paidAmount, String? deliveryAddress, String? notes, String? cancelledReason, DateTime createdAt
});




}
/// @nodoc
class __$OrderCopyWithImpl<$Res>
    implements _$OrderCopyWith<$Res> {
  __$OrderCopyWithImpl(this._self, this._then);

  final _Order _self;
  final $Res Function(_Order) _then;

/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? orderNumber = null,Object? customerId = null,Object? status = null,Object? subtotal = null,Object? discount = null,Object? total = null,Object? paidAmount = null,Object? deliveryAddress = freezed,Object? notes = freezed,Object? cancelledReason = freezed,Object? createdAt = null,}) {
  return _then(_Order(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,orderNumber: null == orderNumber ? _self.orderNumber : orderNumber // ignore: cast_nullable_to_non_nullable
as int,customerId: null == customerId ? _self.customerId : customerId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as OrderStatus,subtotal: null == subtotal ? _self.subtotal : subtotal // ignore: cast_nullable_to_non_nullable
as double,discount: null == discount ? _self.discount : discount // ignore: cast_nullable_to_non_nullable
as double,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as double,paidAmount: null == paidAmount ? _self.paidAmount : paidAmount // ignore: cast_nullable_to_non_nullable
as double,deliveryAddress: freezed == deliveryAddress ? _self.deliveryAddress : deliveryAddress // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,cancelledReason: freezed == cancelledReason ? _self.cancelledReason : cancelledReason // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
