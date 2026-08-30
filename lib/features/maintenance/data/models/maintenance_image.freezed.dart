// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'maintenance_image.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MaintenanceImage {

 String get id; String get maintenanceRequestId; String get imageUrl;
/// Create a copy of MaintenanceImage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MaintenanceImageCopyWith<MaintenanceImage> get copyWith => _$MaintenanceImageCopyWithImpl<MaintenanceImage>(this as MaintenanceImage, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MaintenanceImage&&(identical(other.id, id) || other.id == id)&&(identical(other.maintenanceRequestId, maintenanceRequestId) || other.maintenanceRequestId == maintenanceRequestId)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl));
}


@override
int get hashCode => Object.hash(runtimeType,id,maintenanceRequestId,imageUrl);

@override
String toString() {
  return 'MaintenanceImage(id: $id, maintenanceRequestId: $maintenanceRequestId, imageUrl: $imageUrl)';
}


}

/// @nodoc
abstract mixin class $MaintenanceImageCopyWith<$Res>  {
  factory $MaintenanceImageCopyWith(MaintenanceImage value, $Res Function(MaintenanceImage) _then) = _$MaintenanceImageCopyWithImpl;
@useResult
$Res call({
 String id, String maintenanceRequestId, String imageUrl
});




}
/// @nodoc
class _$MaintenanceImageCopyWithImpl<$Res>
    implements $MaintenanceImageCopyWith<$Res> {
  _$MaintenanceImageCopyWithImpl(this._self, this._then);

  final MaintenanceImage _self;
  final $Res Function(MaintenanceImage) _then;

/// Create a copy of MaintenanceImage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? maintenanceRequestId = null,Object? imageUrl = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,maintenanceRequestId: null == maintenanceRequestId ? _self.maintenanceRequestId : maintenanceRequestId // ignore: cast_nullable_to_non_nullable
as String,imageUrl: null == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [MaintenanceImage].
extension MaintenanceImagePatterns on MaintenanceImage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MaintenanceImage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MaintenanceImage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MaintenanceImage value)  $default,){
final _that = this;
switch (_that) {
case _MaintenanceImage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MaintenanceImage value)?  $default,){
final _that = this;
switch (_that) {
case _MaintenanceImage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String maintenanceRequestId,  String imageUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MaintenanceImage() when $default != null:
return $default(_that.id,_that.maintenanceRequestId,_that.imageUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String maintenanceRequestId,  String imageUrl)  $default,) {final _that = this;
switch (_that) {
case _MaintenanceImage():
return $default(_that.id,_that.maintenanceRequestId,_that.imageUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String maintenanceRequestId,  String imageUrl)?  $default,) {final _that = this;
switch (_that) {
case _MaintenanceImage() when $default != null:
return $default(_that.id,_that.maintenanceRequestId,_that.imageUrl);case _:
  return null;

}
}

}

/// @nodoc


class _MaintenanceImage implements MaintenanceImage {
  const _MaintenanceImage({required this.id, required this.maintenanceRequestId, required this.imageUrl});
  

@override final  String id;
@override final  String maintenanceRequestId;
@override final  String imageUrl;

/// Create a copy of MaintenanceImage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MaintenanceImageCopyWith<_MaintenanceImage> get copyWith => __$MaintenanceImageCopyWithImpl<_MaintenanceImage>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MaintenanceImage&&(identical(other.id, id) || other.id == id)&&(identical(other.maintenanceRequestId, maintenanceRequestId) || other.maintenanceRequestId == maintenanceRequestId)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl));
}


@override
int get hashCode => Object.hash(runtimeType,id,maintenanceRequestId,imageUrl);

@override
String toString() {
  return 'MaintenanceImage(id: $id, maintenanceRequestId: $maintenanceRequestId, imageUrl: $imageUrl)';
}


}

/// @nodoc
abstract mixin class _$MaintenanceImageCopyWith<$Res> implements $MaintenanceImageCopyWith<$Res> {
  factory _$MaintenanceImageCopyWith(_MaintenanceImage value, $Res Function(_MaintenanceImage) _then) = __$MaintenanceImageCopyWithImpl;
@override @useResult
$Res call({
 String id, String maintenanceRequestId, String imageUrl
});




}
/// @nodoc
class __$MaintenanceImageCopyWithImpl<$Res>
    implements _$MaintenanceImageCopyWith<$Res> {
  __$MaintenanceImageCopyWithImpl(this._self, this._then);

  final _MaintenanceImage _self;
  final $Res Function(_MaintenanceImage) _then;

/// Create a copy of MaintenanceImage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? maintenanceRequestId = null,Object? imageUrl = null,}) {
  return _then(_MaintenanceImage(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,maintenanceRequestId: null == maintenanceRequestId ? _self.maintenanceRequestId : maintenanceRequestId // ignore: cast_nullable_to_non_nullable
as String,imageUrl: null == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
