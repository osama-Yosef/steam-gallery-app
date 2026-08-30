// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'stock_movement.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$StockMovement {

 String get id; int get movementNumber; String get productId; String get productName; StockMovementType get movementType; int get quantity; String? get fromLocationType; String? get toLocationType; double get unitCost; double get totalCost; String? get notes; DateTime get createdAt;
/// Create a copy of StockMovement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StockMovementCopyWith<StockMovement> get copyWith => _$StockMovementCopyWithImpl<StockMovement>(this as StockMovement, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StockMovement&&(identical(other.id, id) || other.id == id)&&(identical(other.movementNumber, movementNumber) || other.movementNumber == movementNumber)&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.productName, productName) || other.productName == productName)&&(identical(other.movementType, movementType) || other.movementType == movementType)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.fromLocationType, fromLocationType) || other.fromLocationType == fromLocationType)&&(identical(other.toLocationType, toLocationType) || other.toLocationType == toLocationType)&&(identical(other.unitCost, unitCost) || other.unitCost == unitCost)&&(identical(other.totalCost, totalCost) || other.totalCost == totalCost)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,movementNumber,productId,productName,movementType,quantity,fromLocationType,toLocationType,unitCost,totalCost,notes,createdAt);

@override
String toString() {
  return 'StockMovement(id: $id, movementNumber: $movementNumber, productId: $productId, productName: $productName, movementType: $movementType, quantity: $quantity, fromLocationType: $fromLocationType, toLocationType: $toLocationType, unitCost: $unitCost, totalCost: $totalCost, notes: $notes, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $StockMovementCopyWith<$Res>  {
  factory $StockMovementCopyWith(StockMovement value, $Res Function(StockMovement) _then) = _$StockMovementCopyWithImpl;
@useResult
$Res call({
 String id, int movementNumber, String productId, String productName, StockMovementType movementType, int quantity, String? fromLocationType, String? toLocationType, double unitCost, double totalCost, String? notes, DateTime createdAt
});




}
/// @nodoc
class _$StockMovementCopyWithImpl<$Res>
    implements $StockMovementCopyWith<$Res> {
  _$StockMovementCopyWithImpl(this._self, this._then);

  final StockMovement _self;
  final $Res Function(StockMovement) _then;

/// Create a copy of StockMovement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? movementNumber = null,Object? productId = null,Object? productName = null,Object? movementType = null,Object? quantity = null,Object? fromLocationType = freezed,Object? toLocationType = freezed,Object? unitCost = null,Object? totalCost = null,Object? notes = freezed,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,movementNumber: null == movementNumber ? _self.movementNumber : movementNumber // ignore: cast_nullable_to_non_nullable
as int,productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String,productName: null == productName ? _self.productName : productName // ignore: cast_nullable_to_non_nullable
as String,movementType: null == movementType ? _self.movementType : movementType // ignore: cast_nullable_to_non_nullable
as StockMovementType,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,fromLocationType: freezed == fromLocationType ? _self.fromLocationType : fromLocationType // ignore: cast_nullable_to_non_nullable
as String?,toLocationType: freezed == toLocationType ? _self.toLocationType : toLocationType // ignore: cast_nullable_to_non_nullable
as String?,unitCost: null == unitCost ? _self.unitCost : unitCost // ignore: cast_nullable_to_non_nullable
as double,totalCost: null == totalCost ? _self.totalCost : totalCost // ignore: cast_nullable_to_non_nullable
as double,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [StockMovement].
extension StockMovementPatterns on StockMovement {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StockMovement value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StockMovement() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StockMovement value)  $default,){
final _that = this;
switch (_that) {
case _StockMovement():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StockMovement value)?  $default,){
final _that = this;
switch (_that) {
case _StockMovement() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  int movementNumber,  String productId,  String productName,  StockMovementType movementType,  int quantity,  String? fromLocationType,  String? toLocationType,  double unitCost,  double totalCost,  String? notes,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StockMovement() when $default != null:
return $default(_that.id,_that.movementNumber,_that.productId,_that.productName,_that.movementType,_that.quantity,_that.fromLocationType,_that.toLocationType,_that.unitCost,_that.totalCost,_that.notes,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  int movementNumber,  String productId,  String productName,  StockMovementType movementType,  int quantity,  String? fromLocationType,  String? toLocationType,  double unitCost,  double totalCost,  String? notes,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _StockMovement():
return $default(_that.id,_that.movementNumber,_that.productId,_that.productName,_that.movementType,_that.quantity,_that.fromLocationType,_that.toLocationType,_that.unitCost,_that.totalCost,_that.notes,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  int movementNumber,  String productId,  String productName,  StockMovementType movementType,  int quantity,  String? fromLocationType,  String? toLocationType,  double unitCost,  double totalCost,  String? notes,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _StockMovement() when $default != null:
return $default(_that.id,_that.movementNumber,_that.productId,_that.productName,_that.movementType,_that.quantity,_that.fromLocationType,_that.toLocationType,_that.unitCost,_that.totalCost,_that.notes,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc


class _StockMovement implements StockMovement {
  const _StockMovement({required this.id, required this.movementNumber, required this.productId, required this.productName, required this.movementType, required this.quantity, this.fromLocationType, this.toLocationType, required this.unitCost, required this.totalCost, this.notes, required this.createdAt});
  

@override final  String id;
@override final  int movementNumber;
@override final  String productId;
@override final  String productName;
@override final  StockMovementType movementType;
@override final  int quantity;
@override final  String? fromLocationType;
@override final  String? toLocationType;
@override final  double unitCost;
@override final  double totalCost;
@override final  String? notes;
@override final  DateTime createdAt;

/// Create a copy of StockMovement
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StockMovementCopyWith<_StockMovement> get copyWith => __$StockMovementCopyWithImpl<_StockMovement>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StockMovement&&(identical(other.id, id) || other.id == id)&&(identical(other.movementNumber, movementNumber) || other.movementNumber == movementNumber)&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.productName, productName) || other.productName == productName)&&(identical(other.movementType, movementType) || other.movementType == movementType)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.fromLocationType, fromLocationType) || other.fromLocationType == fromLocationType)&&(identical(other.toLocationType, toLocationType) || other.toLocationType == toLocationType)&&(identical(other.unitCost, unitCost) || other.unitCost == unitCost)&&(identical(other.totalCost, totalCost) || other.totalCost == totalCost)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,movementNumber,productId,productName,movementType,quantity,fromLocationType,toLocationType,unitCost,totalCost,notes,createdAt);

@override
String toString() {
  return 'StockMovement(id: $id, movementNumber: $movementNumber, productId: $productId, productName: $productName, movementType: $movementType, quantity: $quantity, fromLocationType: $fromLocationType, toLocationType: $toLocationType, unitCost: $unitCost, totalCost: $totalCost, notes: $notes, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$StockMovementCopyWith<$Res> implements $StockMovementCopyWith<$Res> {
  factory _$StockMovementCopyWith(_StockMovement value, $Res Function(_StockMovement) _then) = __$StockMovementCopyWithImpl;
@override @useResult
$Res call({
 String id, int movementNumber, String productId, String productName, StockMovementType movementType, int quantity, String? fromLocationType, String? toLocationType, double unitCost, double totalCost, String? notes, DateTime createdAt
});




}
/// @nodoc
class __$StockMovementCopyWithImpl<$Res>
    implements _$StockMovementCopyWith<$Res> {
  __$StockMovementCopyWithImpl(this._self, this._then);

  final _StockMovement _self;
  final $Res Function(_StockMovement) _then;

/// Create a copy of StockMovement
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? movementNumber = null,Object? productId = null,Object? productName = null,Object? movementType = null,Object? quantity = null,Object? fromLocationType = freezed,Object? toLocationType = freezed,Object? unitCost = null,Object? totalCost = null,Object? notes = freezed,Object? createdAt = null,}) {
  return _then(_StockMovement(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,movementNumber: null == movementNumber ? _self.movementNumber : movementNumber // ignore: cast_nullable_to_non_nullable
as int,productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String,productName: null == productName ? _self.productName : productName // ignore: cast_nullable_to_non_nullable
as String,movementType: null == movementType ? _self.movementType : movementType // ignore: cast_nullable_to_non_nullable
as StockMovementType,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,fromLocationType: freezed == fromLocationType ? _self.fromLocationType : fromLocationType // ignore: cast_nullable_to_non_nullable
as String?,toLocationType: freezed == toLocationType ? _self.toLocationType : toLocationType // ignore: cast_nullable_to_non_nullable
as String?,unitCost: null == unitCost ? _self.unitCost : unitCost // ignore: cast_nullable_to_non_nullable
as double,totalCost: null == totalCost ? _self.totalCost : totalCost // ignore: cast_nullable_to_non_nullable
as double,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
