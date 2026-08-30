// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'technician_account_summary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TechnicianAccountSummary {

 String get technicianId; String get technicianName; double get bagValue; double get totalSales; double get totalCollected; double get amountDue;
/// Create a copy of TechnicianAccountSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TechnicianAccountSummaryCopyWith<TechnicianAccountSummary> get copyWith => _$TechnicianAccountSummaryCopyWithImpl<TechnicianAccountSummary>(this as TechnicianAccountSummary, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TechnicianAccountSummary&&(identical(other.technicianId, technicianId) || other.technicianId == technicianId)&&(identical(other.technicianName, technicianName) || other.technicianName == technicianName)&&(identical(other.bagValue, bagValue) || other.bagValue == bagValue)&&(identical(other.totalSales, totalSales) || other.totalSales == totalSales)&&(identical(other.totalCollected, totalCollected) || other.totalCollected == totalCollected)&&(identical(other.amountDue, amountDue) || other.amountDue == amountDue));
}


@override
int get hashCode => Object.hash(runtimeType,technicianId,technicianName,bagValue,totalSales,totalCollected,amountDue);

@override
String toString() {
  return 'TechnicianAccountSummary(technicianId: $technicianId, technicianName: $technicianName, bagValue: $bagValue, totalSales: $totalSales, totalCollected: $totalCollected, amountDue: $amountDue)';
}


}

/// @nodoc
abstract mixin class $TechnicianAccountSummaryCopyWith<$Res>  {
  factory $TechnicianAccountSummaryCopyWith(TechnicianAccountSummary value, $Res Function(TechnicianAccountSummary) _then) = _$TechnicianAccountSummaryCopyWithImpl;
@useResult
$Res call({
 String technicianId, String technicianName, double bagValue, double totalSales, double totalCollected, double amountDue
});




}
/// @nodoc
class _$TechnicianAccountSummaryCopyWithImpl<$Res>
    implements $TechnicianAccountSummaryCopyWith<$Res> {
  _$TechnicianAccountSummaryCopyWithImpl(this._self, this._then);

  final TechnicianAccountSummary _self;
  final $Res Function(TechnicianAccountSummary) _then;

/// Create a copy of TechnicianAccountSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? technicianId = null,Object? technicianName = null,Object? bagValue = null,Object? totalSales = null,Object? totalCollected = null,Object? amountDue = null,}) {
  return _then(_self.copyWith(
technicianId: null == technicianId ? _self.technicianId : technicianId // ignore: cast_nullable_to_non_nullable
as String,technicianName: null == technicianName ? _self.technicianName : technicianName // ignore: cast_nullable_to_non_nullable
as String,bagValue: null == bagValue ? _self.bagValue : bagValue // ignore: cast_nullable_to_non_nullable
as double,totalSales: null == totalSales ? _self.totalSales : totalSales // ignore: cast_nullable_to_non_nullable
as double,totalCollected: null == totalCollected ? _self.totalCollected : totalCollected // ignore: cast_nullable_to_non_nullable
as double,amountDue: null == amountDue ? _self.amountDue : amountDue // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [TechnicianAccountSummary].
extension TechnicianAccountSummaryPatterns on TechnicianAccountSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TechnicianAccountSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TechnicianAccountSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TechnicianAccountSummary value)  $default,){
final _that = this;
switch (_that) {
case _TechnicianAccountSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TechnicianAccountSummary value)?  $default,){
final _that = this;
switch (_that) {
case _TechnicianAccountSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String technicianId,  String technicianName,  double bagValue,  double totalSales,  double totalCollected,  double amountDue)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TechnicianAccountSummary() when $default != null:
return $default(_that.technicianId,_that.technicianName,_that.bagValue,_that.totalSales,_that.totalCollected,_that.amountDue);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String technicianId,  String technicianName,  double bagValue,  double totalSales,  double totalCollected,  double amountDue)  $default,) {final _that = this;
switch (_that) {
case _TechnicianAccountSummary():
return $default(_that.technicianId,_that.technicianName,_that.bagValue,_that.totalSales,_that.totalCollected,_that.amountDue);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String technicianId,  String technicianName,  double bagValue,  double totalSales,  double totalCollected,  double amountDue)?  $default,) {final _that = this;
switch (_that) {
case _TechnicianAccountSummary() when $default != null:
return $default(_that.technicianId,_that.technicianName,_that.bagValue,_that.totalSales,_that.totalCollected,_that.amountDue);case _:
  return null;

}
}

}

/// @nodoc


class _TechnicianAccountSummary implements TechnicianAccountSummary {
  const _TechnicianAccountSummary({required this.technicianId, required this.technicianName, required this.bagValue, required this.totalSales, required this.totalCollected, required this.amountDue});
  

@override final  String technicianId;
@override final  String technicianName;
@override final  double bagValue;
@override final  double totalSales;
@override final  double totalCollected;
@override final  double amountDue;

/// Create a copy of TechnicianAccountSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TechnicianAccountSummaryCopyWith<_TechnicianAccountSummary> get copyWith => __$TechnicianAccountSummaryCopyWithImpl<_TechnicianAccountSummary>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TechnicianAccountSummary&&(identical(other.technicianId, technicianId) || other.technicianId == technicianId)&&(identical(other.technicianName, technicianName) || other.technicianName == technicianName)&&(identical(other.bagValue, bagValue) || other.bagValue == bagValue)&&(identical(other.totalSales, totalSales) || other.totalSales == totalSales)&&(identical(other.totalCollected, totalCollected) || other.totalCollected == totalCollected)&&(identical(other.amountDue, amountDue) || other.amountDue == amountDue));
}


@override
int get hashCode => Object.hash(runtimeType,technicianId,technicianName,bagValue,totalSales,totalCollected,amountDue);

@override
String toString() {
  return 'TechnicianAccountSummary(technicianId: $technicianId, technicianName: $technicianName, bagValue: $bagValue, totalSales: $totalSales, totalCollected: $totalCollected, amountDue: $amountDue)';
}


}

/// @nodoc
abstract mixin class _$TechnicianAccountSummaryCopyWith<$Res> implements $TechnicianAccountSummaryCopyWith<$Res> {
  factory _$TechnicianAccountSummaryCopyWith(_TechnicianAccountSummary value, $Res Function(_TechnicianAccountSummary) _then) = __$TechnicianAccountSummaryCopyWithImpl;
@override @useResult
$Res call({
 String technicianId, String technicianName, double bagValue, double totalSales, double totalCollected, double amountDue
});




}
/// @nodoc
class __$TechnicianAccountSummaryCopyWithImpl<$Res>
    implements _$TechnicianAccountSummaryCopyWith<$Res> {
  __$TechnicianAccountSummaryCopyWithImpl(this._self, this._then);

  final _TechnicianAccountSummary _self;
  final $Res Function(_TechnicianAccountSummary) _then;

/// Create a copy of TechnicianAccountSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? technicianId = null,Object? technicianName = null,Object? bagValue = null,Object? totalSales = null,Object? totalCollected = null,Object? amountDue = null,}) {
  return _then(_TechnicianAccountSummary(
technicianId: null == technicianId ? _self.technicianId : technicianId // ignore: cast_nullable_to_non_nullable
as String,technicianName: null == technicianName ? _self.technicianName : technicianName // ignore: cast_nullable_to_non_nullable
as String,bagValue: null == bagValue ? _self.bagValue : bagValue // ignore: cast_nullable_to_non_nullable
as double,totalSales: null == totalSales ? _self.totalSales : totalSales // ignore: cast_nullable_to_non_nullable
as double,totalCollected: null == totalCollected ? _self.totalCollected : totalCollected // ignore: cast_nullable_to_non_nullable
as double,amountDue: null == amountDue ? _self.amountDue : amountDue // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
