// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'customer_account_transaction.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CustomerAccountTransaction {

 String get id; CustAccountTxnType get type; double get amount; String? get orderId; String? get notes; DateTime get createdAt;
/// Create a copy of CustomerAccountTransaction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CustomerAccountTransactionCopyWith<CustomerAccountTransaction> get copyWith => _$CustomerAccountTransactionCopyWithImpl<CustomerAccountTransaction>(this as CustomerAccountTransaction, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CustomerAccountTransaction&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,type,amount,orderId,notes,createdAt);

@override
String toString() {
  return 'CustomerAccountTransaction(id: $id, type: $type, amount: $amount, orderId: $orderId, notes: $notes, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $CustomerAccountTransactionCopyWith<$Res>  {
  factory $CustomerAccountTransactionCopyWith(CustomerAccountTransaction value, $Res Function(CustomerAccountTransaction) _then) = _$CustomerAccountTransactionCopyWithImpl;
@useResult
$Res call({
 String id, CustAccountTxnType type, double amount, String? orderId, String? notes, DateTime createdAt
});




}
/// @nodoc
class _$CustomerAccountTransactionCopyWithImpl<$Res>
    implements $CustomerAccountTransactionCopyWith<$Res> {
  _$CustomerAccountTransactionCopyWithImpl(this._self, this._then);

  final CustomerAccountTransaction _self;
  final $Res Function(CustomerAccountTransaction) _then;

/// Create a copy of CustomerAccountTransaction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? type = null,Object? amount = null,Object? orderId = freezed,Object? notes = freezed,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as CustAccountTxnType,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,orderId: freezed == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [CustomerAccountTransaction].
extension CustomerAccountTransactionPatterns on CustomerAccountTransaction {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CustomerAccountTransaction value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CustomerAccountTransaction() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CustomerAccountTransaction value)  $default,){
final _that = this;
switch (_that) {
case _CustomerAccountTransaction():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CustomerAccountTransaction value)?  $default,){
final _that = this;
switch (_that) {
case _CustomerAccountTransaction() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  CustAccountTxnType type,  double amount,  String? orderId,  String? notes,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CustomerAccountTransaction() when $default != null:
return $default(_that.id,_that.type,_that.amount,_that.orderId,_that.notes,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  CustAccountTxnType type,  double amount,  String? orderId,  String? notes,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _CustomerAccountTransaction():
return $default(_that.id,_that.type,_that.amount,_that.orderId,_that.notes,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  CustAccountTxnType type,  double amount,  String? orderId,  String? notes,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _CustomerAccountTransaction() when $default != null:
return $default(_that.id,_that.type,_that.amount,_that.orderId,_that.notes,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc


class _CustomerAccountTransaction implements CustomerAccountTransaction {
  const _CustomerAccountTransaction({required this.id, required this.type, required this.amount, this.orderId, this.notes, required this.createdAt});
  

@override final  String id;
@override final  CustAccountTxnType type;
@override final  double amount;
@override final  String? orderId;
@override final  String? notes;
@override final  DateTime createdAt;

/// Create a copy of CustomerAccountTransaction
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CustomerAccountTransactionCopyWith<_CustomerAccountTransaction> get copyWith => __$CustomerAccountTransactionCopyWithImpl<_CustomerAccountTransaction>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CustomerAccountTransaction&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,type,amount,orderId,notes,createdAt);

@override
String toString() {
  return 'CustomerAccountTransaction(id: $id, type: $type, amount: $amount, orderId: $orderId, notes: $notes, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$CustomerAccountTransactionCopyWith<$Res> implements $CustomerAccountTransactionCopyWith<$Res> {
  factory _$CustomerAccountTransactionCopyWith(_CustomerAccountTransaction value, $Res Function(_CustomerAccountTransaction) _then) = __$CustomerAccountTransactionCopyWithImpl;
@override @useResult
$Res call({
 String id, CustAccountTxnType type, double amount, String? orderId, String? notes, DateTime createdAt
});




}
/// @nodoc
class __$CustomerAccountTransactionCopyWithImpl<$Res>
    implements _$CustomerAccountTransactionCopyWith<$Res> {
  __$CustomerAccountTransactionCopyWithImpl(this._self, this._then);

  final _CustomerAccountTransaction _self;
  final $Res Function(_CustomerAccountTransaction) _then;

/// Create a copy of CustomerAccountTransaction
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? type = null,Object? amount = null,Object? orderId = freezed,Object? notes = freezed,Object? createdAt = null,}) {
  return _then(_CustomerAccountTransaction(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as CustAccountTxnType,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,orderId: freezed == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
