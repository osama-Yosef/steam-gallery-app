// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'customer_account_summary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CustomerAccountSummary {

 String get customerId; String get customerName; double get totalPurchases; double get totalPaid; double get remainingBalance;
/// Create a copy of CustomerAccountSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CustomerAccountSummaryCopyWith<CustomerAccountSummary> get copyWith => _$CustomerAccountSummaryCopyWithImpl<CustomerAccountSummary>(this as CustomerAccountSummary, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CustomerAccountSummary&&(identical(other.customerId, customerId) || other.customerId == customerId)&&(identical(other.customerName, customerName) || other.customerName == customerName)&&(identical(other.totalPurchases, totalPurchases) || other.totalPurchases == totalPurchases)&&(identical(other.totalPaid, totalPaid) || other.totalPaid == totalPaid)&&(identical(other.remainingBalance, remainingBalance) || other.remainingBalance == remainingBalance));
}


@override
int get hashCode => Object.hash(runtimeType,customerId,customerName,totalPurchases,totalPaid,remainingBalance);

@override
String toString() {
  return 'CustomerAccountSummary(customerId: $customerId, customerName: $customerName, totalPurchases: $totalPurchases, totalPaid: $totalPaid, remainingBalance: $remainingBalance)';
}


}

/// @nodoc
abstract mixin class $CustomerAccountSummaryCopyWith<$Res>  {
  factory $CustomerAccountSummaryCopyWith(CustomerAccountSummary value, $Res Function(CustomerAccountSummary) _then) = _$CustomerAccountSummaryCopyWithImpl;
@useResult
$Res call({
 String customerId, String customerName, double totalPurchases, double totalPaid, double remainingBalance
});




}
/// @nodoc
class _$CustomerAccountSummaryCopyWithImpl<$Res>
    implements $CustomerAccountSummaryCopyWith<$Res> {
  _$CustomerAccountSummaryCopyWithImpl(this._self, this._then);

  final CustomerAccountSummary _self;
  final $Res Function(CustomerAccountSummary) _then;

/// Create a copy of CustomerAccountSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? customerId = null,Object? customerName = null,Object? totalPurchases = null,Object? totalPaid = null,Object? remainingBalance = null,}) {
  return _then(_self.copyWith(
customerId: null == customerId ? _self.customerId : customerId // ignore: cast_nullable_to_non_nullable
as String,customerName: null == customerName ? _self.customerName : customerName // ignore: cast_nullable_to_non_nullable
as String,totalPurchases: null == totalPurchases ? _self.totalPurchases : totalPurchases // ignore: cast_nullable_to_non_nullable
as double,totalPaid: null == totalPaid ? _self.totalPaid : totalPaid // ignore: cast_nullable_to_non_nullable
as double,remainingBalance: null == remainingBalance ? _self.remainingBalance : remainingBalance // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [CustomerAccountSummary].
extension CustomerAccountSummaryPatterns on CustomerAccountSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CustomerAccountSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CustomerAccountSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CustomerAccountSummary value)  $default,){
final _that = this;
switch (_that) {
case _CustomerAccountSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CustomerAccountSummary value)?  $default,){
final _that = this;
switch (_that) {
case _CustomerAccountSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String customerId,  String customerName,  double totalPurchases,  double totalPaid,  double remainingBalance)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CustomerAccountSummary() when $default != null:
return $default(_that.customerId,_that.customerName,_that.totalPurchases,_that.totalPaid,_that.remainingBalance);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String customerId,  String customerName,  double totalPurchases,  double totalPaid,  double remainingBalance)  $default,) {final _that = this;
switch (_that) {
case _CustomerAccountSummary():
return $default(_that.customerId,_that.customerName,_that.totalPurchases,_that.totalPaid,_that.remainingBalance);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String customerId,  String customerName,  double totalPurchases,  double totalPaid,  double remainingBalance)?  $default,) {final _that = this;
switch (_that) {
case _CustomerAccountSummary() when $default != null:
return $default(_that.customerId,_that.customerName,_that.totalPurchases,_that.totalPaid,_that.remainingBalance);case _:
  return null;

}
}

}

/// @nodoc


class _CustomerAccountSummary implements CustomerAccountSummary {
  const _CustomerAccountSummary({required this.customerId, required this.customerName, required this.totalPurchases, required this.totalPaid, required this.remainingBalance});
  

@override final  String customerId;
@override final  String customerName;
@override final  double totalPurchases;
@override final  double totalPaid;
@override final  double remainingBalance;

/// Create a copy of CustomerAccountSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CustomerAccountSummaryCopyWith<_CustomerAccountSummary> get copyWith => __$CustomerAccountSummaryCopyWithImpl<_CustomerAccountSummary>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CustomerAccountSummary&&(identical(other.customerId, customerId) || other.customerId == customerId)&&(identical(other.customerName, customerName) || other.customerName == customerName)&&(identical(other.totalPurchases, totalPurchases) || other.totalPurchases == totalPurchases)&&(identical(other.totalPaid, totalPaid) || other.totalPaid == totalPaid)&&(identical(other.remainingBalance, remainingBalance) || other.remainingBalance == remainingBalance));
}


@override
int get hashCode => Object.hash(runtimeType,customerId,customerName,totalPurchases,totalPaid,remainingBalance);

@override
String toString() {
  return 'CustomerAccountSummary(customerId: $customerId, customerName: $customerName, totalPurchases: $totalPurchases, totalPaid: $totalPaid, remainingBalance: $remainingBalance)';
}


}

/// @nodoc
abstract mixin class _$CustomerAccountSummaryCopyWith<$Res> implements $CustomerAccountSummaryCopyWith<$Res> {
  factory _$CustomerAccountSummaryCopyWith(_CustomerAccountSummary value, $Res Function(_CustomerAccountSummary) _then) = __$CustomerAccountSummaryCopyWithImpl;
@override @useResult
$Res call({
 String customerId, String customerName, double totalPurchases, double totalPaid, double remainingBalance
});




}
/// @nodoc
class __$CustomerAccountSummaryCopyWithImpl<$Res>
    implements _$CustomerAccountSummaryCopyWith<$Res> {
  __$CustomerAccountSummaryCopyWithImpl(this._self, this._then);

  final _CustomerAccountSummary _self;
  final $Res Function(_CustomerAccountSummary) _then;

/// Create a copy of CustomerAccountSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? customerId = null,Object? customerName = null,Object? totalPurchases = null,Object? totalPaid = null,Object? remainingBalance = null,}) {
  return _then(_CustomerAccountSummary(
customerId: null == customerId ? _self.customerId : customerId // ignore: cast_nullable_to_non_nullable
as String,customerName: null == customerName ? _self.customerName : customerName // ignore: cast_nullable_to_non_nullable
as String,totalPurchases: null == totalPurchases ? _self.totalPurchases : totalPurchases // ignore: cast_nullable_to_non_nullable
as double,totalPaid: null == totalPaid ? _self.totalPaid : totalPaid // ignore: cast_nullable_to_non_nullable
as double,remainingBalance: null == remainingBalance ? _self.remainingBalance : remainingBalance // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
