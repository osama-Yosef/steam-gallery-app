// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'technician_option.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TechnicianOption {

 String get id; String get fullName; String get employeeCode;
/// Create a copy of TechnicianOption
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TechnicianOptionCopyWith<TechnicianOption> get copyWith => _$TechnicianOptionCopyWithImpl<TechnicianOption>(this as TechnicianOption, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TechnicianOption&&(identical(other.id, id) || other.id == id)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.employeeCode, employeeCode) || other.employeeCode == employeeCode));
}


@override
int get hashCode => Object.hash(runtimeType,id,fullName,employeeCode);

@override
String toString() {
  return 'TechnicianOption(id: $id, fullName: $fullName, employeeCode: $employeeCode)';
}


}

/// @nodoc
abstract mixin class $TechnicianOptionCopyWith<$Res>  {
  factory $TechnicianOptionCopyWith(TechnicianOption value, $Res Function(TechnicianOption) _then) = _$TechnicianOptionCopyWithImpl;
@useResult
$Res call({
 String id, String fullName, String employeeCode
});




}
/// @nodoc
class _$TechnicianOptionCopyWithImpl<$Res>
    implements $TechnicianOptionCopyWith<$Res> {
  _$TechnicianOptionCopyWithImpl(this._self, this._then);

  final TechnicianOption _self;
  final $Res Function(TechnicianOption) _then;

/// Create a copy of TechnicianOption
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? fullName = null,Object? employeeCode = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,employeeCode: null == employeeCode ? _self.employeeCode : employeeCode // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [TechnicianOption].
extension TechnicianOptionPatterns on TechnicianOption {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TechnicianOption value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TechnicianOption() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TechnicianOption value)  $default,){
final _that = this;
switch (_that) {
case _TechnicianOption():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TechnicianOption value)?  $default,){
final _that = this;
switch (_that) {
case _TechnicianOption() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String fullName,  String employeeCode)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TechnicianOption() when $default != null:
return $default(_that.id,_that.fullName,_that.employeeCode);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String fullName,  String employeeCode)  $default,) {final _that = this;
switch (_that) {
case _TechnicianOption():
return $default(_that.id,_that.fullName,_that.employeeCode);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String fullName,  String employeeCode)?  $default,) {final _that = this;
switch (_that) {
case _TechnicianOption() when $default != null:
return $default(_that.id,_that.fullName,_that.employeeCode);case _:
  return null;

}
}

}

/// @nodoc


class _TechnicianOption implements TechnicianOption {
  const _TechnicianOption({required this.id, required this.fullName, required this.employeeCode});
  

@override final  String id;
@override final  String fullName;
@override final  String employeeCode;

/// Create a copy of TechnicianOption
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TechnicianOptionCopyWith<_TechnicianOption> get copyWith => __$TechnicianOptionCopyWithImpl<_TechnicianOption>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TechnicianOption&&(identical(other.id, id) || other.id == id)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.employeeCode, employeeCode) || other.employeeCode == employeeCode));
}


@override
int get hashCode => Object.hash(runtimeType,id,fullName,employeeCode);

@override
String toString() {
  return 'TechnicianOption(id: $id, fullName: $fullName, employeeCode: $employeeCode)';
}


}

/// @nodoc
abstract mixin class _$TechnicianOptionCopyWith<$Res> implements $TechnicianOptionCopyWith<$Res> {
  factory _$TechnicianOptionCopyWith(_TechnicianOption value, $Res Function(_TechnicianOption) _then) = __$TechnicianOptionCopyWithImpl;
@override @useResult
$Res call({
 String id, String fullName, String employeeCode
});




}
/// @nodoc
class __$TechnicianOptionCopyWithImpl<$Res>
    implements _$TechnicianOptionCopyWith<$Res> {
  __$TechnicianOptionCopyWithImpl(this._self, this._then);

  final _TechnicianOption _self;
  final $Res Function(_TechnicianOption) _then;

/// Create a copy of TechnicianOption
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? fullName = null,Object? employeeCode = null,}) {
  return _then(_TechnicianOption(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,employeeCode: null == employeeCode ? _self.employeeCode : employeeCode // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
