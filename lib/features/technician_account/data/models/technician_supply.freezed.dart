// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'technician_supply.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TechnicianSupply {

 String get id; int get supplyNumber; String get technicianId; double get amount; SupplyStatus get status; String? get notes; String? get rejectionReason; DateTime get createdAt;
/// Create a copy of TechnicianSupply
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TechnicianSupplyCopyWith<TechnicianSupply> get copyWith => _$TechnicianSupplyCopyWithImpl<TechnicianSupply>(this as TechnicianSupply, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TechnicianSupply&&(identical(other.id, id) || other.id == id)&&(identical(other.supplyNumber, supplyNumber) || other.supplyNumber == supplyNumber)&&(identical(other.technicianId, technicianId) || other.technicianId == technicianId)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.status, status) || other.status == status)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.rejectionReason, rejectionReason) || other.rejectionReason == rejectionReason)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,supplyNumber,technicianId,amount,status,notes,rejectionReason,createdAt);

@override
String toString() {
  return 'TechnicianSupply(id: $id, supplyNumber: $supplyNumber, technicianId: $technicianId, amount: $amount, status: $status, notes: $notes, rejectionReason: $rejectionReason, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $TechnicianSupplyCopyWith<$Res>  {
  factory $TechnicianSupplyCopyWith(TechnicianSupply value, $Res Function(TechnicianSupply) _then) = _$TechnicianSupplyCopyWithImpl;
@useResult
$Res call({
 String id, int supplyNumber, String technicianId, double amount, SupplyStatus status, String? notes, String? rejectionReason, DateTime createdAt
});




}
/// @nodoc
class _$TechnicianSupplyCopyWithImpl<$Res>
    implements $TechnicianSupplyCopyWith<$Res> {
  _$TechnicianSupplyCopyWithImpl(this._self, this._then);

  final TechnicianSupply _self;
  final $Res Function(TechnicianSupply) _then;

/// Create a copy of TechnicianSupply
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? supplyNumber = null,Object? technicianId = null,Object? amount = null,Object? status = null,Object? notes = freezed,Object? rejectionReason = freezed,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,supplyNumber: null == supplyNumber ? _self.supplyNumber : supplyNumber // ignore: cast_nullable_to_non_nullable
as int,technicianId: null == technicianId ? _self.technicianId : technicianId // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SupplyStatus,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,rejectionReason: freezed == rejectionReason ? _self.rejectionReason : rejectionReason // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [TechnicianSupply].
extension TechnicianSupplyPatterns on TechnicianSupply {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TechnicianSupply value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TechnicianSupply() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TechnicianSupply value)  $default,){
final _that = this;
switch (_that) {
case _TechnicianSupply():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TechnicianSupply value)?  $default,){
final _that = this;
switch (_that) {
case _TechnicianSupply() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  int supplyNumber,  String technicianId,  double amount,  SupplyStatus status,  String? notes,  String? rejectionReason,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TechnicianSupply() when $default != null:
return $default(_that.id,_that.supplyNumber,_that.technicianId,_that.amount,_that.status,_that.notes,_that.rejectionReason,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  int supplyNumber,  String technicianId,  double amount,  SupplyStatus status,  String? notes,  String? rejectionReason,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _TechnicianSupply():
return $default(_that.id,_that.supplyNumber,_that.technicianId,_that.amount,_that.status,_that.notes,_that.rejectionReason,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  int supplyNumber,  String technicianId,  double amount,  SupplyStatus status,  String? notes,  String? rejectionReason,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _TechnicianSupply() when $default != null:
return $default(_that.id,_that.supplyNumber,_that.technicianId,_that.amount,_that.status,_that.notes,_that.rejectionReason,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc


class _TechnicianSupply implements TechnicianSupply {
  const _TechnicianSupply({required this.id, required this.supplyNumber, required this.technicianId, required this.amount, required this.status, this.notes, this.rejectionReason, required this.createdAt});
  

@override final  String id;
@override final  int supplyNumber;
@override final  String technicianId;
@override final  double amount;
@override final  SupplyStatus status;
@override final  String? notes;
@override final  String? rejectionReason;
@override final  DateTime createdAt;

/// Create a copy of TechnicianSupply
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TechnicianSupplyCopyWith<_TechnicianSupply> get copyWith => __$TechnicianSupplyCopyWithImpl<_TechnicianSupply>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TechnicianSupply&&(identical(other.id, id) || other.id == id)&&(identical(other.supplyNumber, supplyNumber) || other.supplyNumber == supplyNumber)&&(identical(other.technicianId, technicianId) || other.technicianId == technicianId)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.status, status) || other.status == status)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.rejectionReason, rejectionReason) || other.rejectionReason == rejectionReason)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,supplyNumber,technicianId,amount,status,notes,rejectionReason,createdAt);

@override
String toString() {
  return 'TechnicianSupply(id: $id, supplyNumber: $supplyNumber, technicianId: $technicianId, amount: $amount, status: $status, notes: $notes, rejectionReason: $rejectionReason, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$TechnicianSupplyCopyWith<$Res> implements $TechnicianSupplyCopyWith<$Res> {
  factory _$TechnicianSupplyCopyWith(_TechnicianSupply value, $Res Function(_TechnicianSupply) _then) = __$TechnicianSupplyCopyWithImpl;
@override @useResult
$Res call({
 String id, int supplyNumber, String technicianId, double amount, SupplyStatus status, String? notes, String? rejectionReason, DateTime createdAt
});




}
/// @nodoc
class __$TechnicianSupplyCopyWithImpl<$Res>
    implements _$TechnicianSupplyCopyWith<$Res> {
  __$TechnicianSupplyCopyWithImpl(this._self, this._then);

  final _TechnicianSupply _self;
  final $Res Function(_TechnicianSupply) _then;

/// Create a copy of TechnicianSupply
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? supplyNumber = null,Object? technicianId = null,Object? amount = null,Object? status = null,Object? notes = freezed,Object? rejectionReason = freezed,Object? createdAt = null,}) {
  return _then(_TechnicianSupply(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,supplyNumber: null == supplyNumber ? _self.supplyNumber : supplyNumber // ignore: cast_nullable_to_non_nullable
as int,technicianId: null == technicianId ? _self.technicianId : technicianId // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SupplyStatus,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,rejectionReason: freezed == rejectionReason ? _self.rejectionReason : rejectionReason // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
