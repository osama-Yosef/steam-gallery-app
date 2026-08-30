// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'queue_position.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$QueuePosition {

 int get position; int get peopleAhead; int get totalActive;
/// Create a copy of QueuePosition
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QueuePositionCopyWith<QueuePosition> get copyWith => _$QueuePositionCopyWithImpl<QueuePosition>(this as QueuePosition, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QueuePosition&&(identical(other.position, position) || other.position == position)&&(identical(other.peopleAhead, peopleAhead) || other.peopleAhead == peopleAhead)&&(identical(other.totalActive, totalActive) || other.totalActive == totalActive));
}


@override
int get hashCode => Object.hash(runtimeType,position,peopleAhead,totalActive);

@override
String toString() {
  return 'QueuePosition(position: $position, peopleAhead: $peopleAhead, totalActive: $totalActive)';
}


}

/// @nodoc
abstract mixin class $QueuePositionCopyWith<$Res>  {
  factory $QueuePositionCopyWith(QueuePosition value, $Res Function(QueuePosition) _then) = _$QueuePositionCopyWithImpl;
@useResult
$Res call({
 int position, int peopleAhead, int totalActive
});




}
/// @nodoc
class _$QueuePositionCopyWithImpl<$Res>
    implements $QueuePositionCopyWith<$Res> {
  _$QueuePositionCopyWithImpl(this._self, this._then);

  final QueuePosition _self;
  final $Res Function(QueuePosition) _then;

/// Create a copy of QueuePosition
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? position = null,Object? peopleAhead = null,Object? totalActive = null,}) {
  return _then(_self.copyWith(
position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int,peopleAhead: null == peopleAhead ? _self.peopleAhead : peopleAhead // ignore: cast_nullable_to_non_nullable
as int,totalActive: null == totalActive ? _self.totalActive : totalActive // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [QueuePosition].
extension QueuePositionPatterns on QueuePosition {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _QueuePosition value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _QueuePosition() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _QueuePosition value)  $default,){
final _that = this;
switch (_that) {
case _QueuePosition():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _QueuePosition value)?  $default,){
final _that = this;
switch (_that) {
case _QueuePosition() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int position,  int peopleAhead,  int totalActive)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _QueuePosition() when $default != null:
return $default(_that.position,_that.peopleAhead,_that.totalActive);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int position,  int peopleAhead,  int totalActive)  $default,) {final _that = this;
switch (_that) {
case _QueuePosition():
return $default(_that.position,_that.peopleAhead,_that.totalActive);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int position,  int peopleAhead,  int totalActive)?  $default,) {final _that = this;
switch (_that) {
case _QueuePosition() when $default != null:
return $default(_that.position,_that.peopleAhead,_that.totalActive);case _:
  return null;

}
}

}

/// @nodoc


class _QueuePosition implements QueuePosition {
  const _QueuePosition({required this.position, required this.peopleAhead, required this.totalActive});
  

@override final  int position;
@override final  int peopleAhead;
@override final  int totalActive;

/// Create a copy of QueuePosition
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QueuePositionCopyWith<_QueuePosition> get copyWith => __$QueuePositionCopyWithImpl<_QueuePosition>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _QueuePosition&&(identical(other.position, position) || other.position == position)&&(identical(other.peopleAhead, peopleAhead) || other.peopleAhead == peopleAhead)&&(identical(other.totalActive, totalActive) || other.totalActive == totalActive));
}


@override
int get hashCode => Object.hash(runtimeType,position,peopleAhead,totalActive);

@override
String toString() {
  return 'QueuePosition(position: $position, peopleAhead: $peopleAhead, totalActive: $totalActive)';
}


}

/// @nodoc
abstract mixin class _$QueuePositionCopyWith<$Res> implements $QueuePositionCopyWith<$Res> {
  factory _$QueuePositionCopyWith(_QueuePosition value, $Res Function(_QueuePosition) _then) = __$QueuePositionCopyWithImpl;
@override @useResult
$Res call({
 int position, int peopleAhead, int totalActive
});




}
/// @nodoc
class __$QueuePositionCopyWithImpl<$Res>
    implements _$QueuePositionCopyWith<$Res> {
  __$QueuePositionCopyWithImpl(this._self, this._then);

  final _QueuePosition _self;
  final $Res Function(_QueuePosition) _then;

/// Create a copy of QueuePosition
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? position = null,Object? peopleAhead = null,Object? totalActive = null,}) {
  return _then(_QueuePosition(
position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int,peopleAhead: null == peopleAhead ? _self.peopleAhead : peopleAhead // ignore: cast_nullable_to_non_nullable
as int,totalActive: null == totalActive ? _self.totalActive : totalActive // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
