// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'technician_account_transaction.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TechnicianAccountTransaction {

 String get id; TechAccountTxnType get type; double get amount; String? get notes; DateTime get createdAt;
/// Create a copy of TechnicianAccountTransaction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TechnicianAccountTransactionCopyWith<TechnicianAccountTransaction> get copyWith => _$TechnicianAccountTransactionCopyWithImpl<TechnicianAccountTransaction>(this as TechnicianAccountTransaction, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TechnicianAccountTransaction&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,type,amount,notes,createdAt);

@override
String toString() {
  return 'TechnicianAccountTransaction(id: $id, type: $type, amount: $amount, notes: $notes, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $TechnicianAccountTransactionCopyWith<$Res>  {
  factory $TechnicianAccountTransactionCopyWith(TechnicianAccountTransaction value, $Res Function(TechnicianAccountTransaction) _then) = _$TechnicianAccountTransactionCopyWithImpl;
@useResult
$Res call({
 String id, TechAccountTxnType type, double amount, String? notes, DateTime createdAt
});




}
/// @nodoc
class _$TechnicianAccountTransactionCopyWithImpl<$Res>
    implements $TechnicianAccountTransactionCopyWith<$Res> {
  _$TechnicianAccountTransactionCopyWithImpl(this._self, this._then);

  final TechnicianAccountTransaction _self;
  final $Res Function(TechnicianAccountTransaction) _then;

/// Create a copy of TechnicianAccountTransaction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? type = null,Object? amount = null,Object? notes = freezed,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as TechAccountTxnType,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [TechnicianAccountTransaction].
extension TechnicianAccountTransactionPatterns on TechnicianAccountTransaction {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TechnicianAccountTransaction value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TechnicianAccountTransaction() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TechnicianAccountTransaction value)  $default,){
final _that = this;
switch (_that) {
case _TechnicianAccountTransaction():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TechnicianAccountTransaction value)?  $default,){
final _that = this;
switch (_that) {
case _TechnicianAccountTransaction() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  TechAccountTxnType type,  double amount,  String? notes,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TechnicianAccountTransaction() when $default != null:
return $default(_that.id,_that.type,_that.amount,_that.notes,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  TechAccountTxnType type,  double amount,  String? notes,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _TechnicianAccountTransaction():
return $default(_that.id,_that.type,_that.amount,_that.notes,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  TechAccountTxnType type,  double amount,  String? notes,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _TechnicianAccountTransaction() when $default != null:
return $default(_that.id,_that.type,_that.amount,_that.notes,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc


class _TechnicianAccountTransaction implements TechnicianAccountTransaction {
  const _TechnicianAccountTransaction({required this.id, required this.type, required this.amount, this.notes, required this.createdAt});
  

@override final  String id;
@override final  TechAccountTxnType type;
@override final  double amount;
@override final  String? notes;
@override final  DateTime createdAt;

/// Create a copy of TechnicianAccountTransaction
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TechnicianAccountTransactionCopyWith<_TechnicianAccountTransaction> get copyWith => __$TechnicianAccountTransactionCopyWithImpl<_TechnicianAccountTransaction>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TechnicianAccountTransaction&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,type,amount,notes,createdAt);

@override
String toString() {
  return 'TechnicianAccountTransaction(id: $id, type: $type, amount: $amount, notes: $notes, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$TechnicianAccountTransactionCopyWith<$Res> implements $TechnicianAccountTransactionCopyWith<$Res> {
  factory _$TechnicianAccountTransactionCopyWith(_TechnicianAccountTransaction value, $Res Function(_TechnicianAccountTransaction) _then) = __$TechnicianAccountTransactionCopyWithImpl;
@override @useResult
$Res call({
 String id, TechAccountTxnType type, double amount, String? notes, DateTime createdAt
});




}
/// @nodoc
class __$TechnicianAccountTransactionCopyWithImpl<$Res>
    implements _$TechnicianAccountTransactionCopyWith<$Res> {
  __$TechnicianAccountTransactionCopyWithImpl(this._self, this._then);

  final _TechnicianAccountTransaction _self;
  final $Res Function(_TechnicianAccountTransaction) _then;

/// Create a copy of TechnicianAccountTransaction
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? type = null,Object? amount = null,Object? notes = freezed,Object? createdAt = null,}) {
  return _then(_TechnicianAccountTransaction(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as TechAccountTxnType,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
