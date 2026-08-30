// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'cashbox_balance.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CashboxBalance {

 String get cashboxId; String get name; double get balance;
/// Create a copy of CashboxBalance
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CashboxBalanceCopyWith<CashboxBalance> get copyWith => _$CashboxBalanceCopyWithImpl<CashboxBalance>(this as CashboxBalance, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CashboxBalance&&(identical(other.cashboxId, cashboxId) || other.cashboxId == cashboxId)&&(identical(other.name, name) || other.name == name)&&(identical(other.balance, balance) || other.balance == balance));
}


@override
int get hashCode => Object.hash(runtimeType,cashboxId,name,balance);

@override
String toString() {
  return 'CashboxBalance(cashboxId: $cashboxId, name: $name, balance: $balance)';
}


}

/// @nodoc
abstract mixin class $CashboxBalanceCopyWith<$Res>  {
  factory $CashboxBalanceCopyWith(CashboxBalance value, $Res Function(CashboxBalance) _then) = _$CashboxBalanceCopyWithImpl;
@useResult
$Res call({
 String cashboxId, String name, double balance
});




}
/// @nodoc
class _$CashboxBalanceCopyWithImpl<$Res>
    implements $CashboxBalanceCopyWith<$Res> {
  _$CashboxBalanceCopyWithImpl(this._self, this._then);

  final CashboxBalance _self;
  final $Res Function(CashboxBalance) _then;

/// Create a copy of CashboxBalance
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? cashboxId = null,Object? name = null,Object? balance = null,}) {
  return _then(_self.copyWith(
cashboxId: null == cashboxId ? _self.cashboxId : cashboxId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,balance: null == balance ? _self.balance : balance // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [CashboxBalance].
extension CashboxBalancePatterns on CashboxBalance {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CashboxBalance value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CashboxBalance() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CashboxBalance value)  $default,){
final _that = this;
switch (_that) {
case _CashboxBalance():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CashboxBalance value)?  $default,){
final _that = this;
switch (_that) {
case _CashboxBalance() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String cashboxId,  String name,  double balance)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CashboxBalance() when $default != null:
return $default(_that.cashboxId,_that.name,_that.balance);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String cashboxId,  String name,  double balance)  $default,) {final _that = this;
switch (_that) {
case _CashboxBalance():
return $default(_that.cashboxId,_that.name,_that.balance);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String cashboxId,  String name,  double balance)?  $default,) {final _that = this;
switch (_that) {
case _CashboxBalance() when $default != null:
return $default(_that.cashboxId,_that.name,_that.balance);case _:
  return null;

}
}

}

/// @nodoc


class _CashboxBalance implements CashboxBalance {
  const _CashboxBalance({required this.cashboxId, required this.name, required this.balance});
  

@override final  String cashboxId;
@override final  String name;
@override final  double balance;

/// Create a copy of CashboxBalance
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CashboxBalanceCopyWith<_CashboxBalance> get copyWith => __$CashboxBalanceCopyWithImpl<_CashboxBalance>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CashboxBalance&&(identical(other.cashboxId, cashboxId) || other.cashboxId == cashboxId)&&(identical(other.name, name) || other.name == name)&&(identical(other.balance, balance) || other.balance == balance));
}


@override
int get hashCode => Object.hash(runtimeType,cashboxId,name,balance);

@override
String toString() {
  return 'CashboxBalance(cashboxId: $cashboxId, name: $name, balance: $balance)';
}


}

/// @nodoc
abstract mixin class _$CashboxBalanceCopyWith<$Res> implements $CashboxBalanceCopyWith<$Res> {
  factory _$CashboxBalanceCopyWith(_CashboxBalance value, $Res Function(_CashboxBalance) _then) = __$CashboxBalanceCopyWithImpl;
@override @useResult
$Res call({
 String cashboxId, String name, double balance
});




}
/// @nodoc
class __$CashboxBalanceCopyWithImpl<$Res>
    implements _$CashboxBalanceCopyWith<$Res> {
  __$CashboxBalanceCopyWithImpl(this._self, this._then);

  final _CashboxBalance _self;
  final $Res Function(_CashboxBalance) _then;

/// Create a copy of CashboxBalance
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? cashboxId = null,Object? name = null,Object? balance = null,}) {
  return _then(_CashboxBalance(
cashboxId: null == cashboxId ? _self.cashboxId : cashboxId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,balance: null == balance ? _self.balance : balance // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
