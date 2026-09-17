// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'location_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$City {

 String get id; String get countryId; String get nameAr; String? get nameEn; GeoPoint get center; bool get isActive; int get sortOrder;
/// Create a copy of City
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CityCopyWith<City> get copyWith => _$CityCopyWithImpl<City>(this as City, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is City&&(identical(other.id, id) || other.id == id)&&(identical(other.countryId, countryId) || other.countryId == countryId)&&(identical(other.nameAr, nameAr) || other.nameAr == nameAr)&&(identical(other.nameEn, nameEn) || other.nameEn == nameEn)&&(identical(other.center, center) || other.center == center)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder));
}


@override
int get hashCode => Object.hash(runtimeType,id,countryId,nameAr,nameEn,center,isActive,sortOrder);

@override
String toString() {
  return 'City(id: $id, countryId: $countryId, nameAr: $nameAr, nameEn: $nameEn, center: $center, isActive: $isActive, sortOrder: $sortOrder)';
}


}

/// @nodoc
abstract mixin class $CityCopyWith<$Res>  {
  factory $CityCopyWith(City value, $Res Function(City) _then) = _$CityCopyWithImpl;
@useResult
$Res call({
 String id, String countryId, String nameAr, String? nameEn, GeoPoint center, bool isActive, int sortOrder
});




}
/// @nodoc
class _$CityCopyWithImpl<$Res>
    implements $CityCopyWith<$Res> {
  _$CityCopyWithImpl(this._self, this._then);

  final City _self;
  final $Res Function(City) _then;

/// Create a copy of City
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? countryId = null,Object? nameAr = null,Object? nameEn = freezed,Object? center = null,Object? isActive = null,Object? sortOrder = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,countryId: null == countryId ? _self.countryId : countryId // ignore: cast_nullable_to_non_nullable
as String,nameAr: null == nameAr ? _self.nameAr : nameAr // ignore: cast_nullable_to_non_nullable
as String,nameEn: freezed == nameEn ? _self.nameEn : nameEn // ignore: cast_nullable_to_non_nullable
as String?,center: null == center ? _self.center : center // ignore: cast_nullable_to_non_nullable
as GeoPoint,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [City].
extension CityPatterns on City {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _City value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _City() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _City value)  $default,){
final _that = this;
switch (_that) {
case _City():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _City value)?  $default,){
final _that = this;
switch (_that) {
case _City() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String countryId,  String nameAr,  String? nameEn,  GeoPoint center,  bool isActive,  int sortOrder)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _City() when $default != null:
return $default(_that.id,_that.countryId,_that.nameAr,_that.nameEn,_that.center,_that.isActive,_that.sortOrder);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String countryId,  String nameAr,  String? nameEn,  GeoPoint center,  bool isActive,  int sortOrder)  $default,) {final _that = this;
switch (_that) {
case _City():
return $default(_that.id,_that.countryId,_that.nameAr,_that.nameEn,_that.center,_that.isActive,_that.sortOrder);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String countryId,  String nameAr,  String? nameEn,  GeoPoint center,  bool isActive,  int sortOrder)?  $default,) {final _that = this;
switch (_that) {
case _City() when $default != null:
return $default(_that.id,_that.countryId,_that.nameAr,_that.nameEn,_that.center,_that.isActive,_that.sortOrder);case _:
  return null;

}
}

}

/// @nodoc


class _City implements City {
  const _City({required this.id, required this.countryId, required this.nameAr, this.nameEn, required this.center, required this.isActive, required this.sortOrder});
  

@override final  String id;
@override final  String countryId;
@override final  String nameAr;
@override final  String? nameEn;
@override final  GeoPoint center;
@override final  bool isActive;
@override final  int sortOrder;

/// Create a copy of City
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CityCopyWith<_City> get copyWith => __$CityCopyWithImpl<_City>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _City&&(identical(other.id, id) || other.id == id)&&(identical(other.countryId, countryId) || other.countryId == countryId)&&(identical(other.nameAr, nameAr) || other.nameAr == nameAr)&&(identical(other.nameEn, nameEn) || other.nameEn == nameEn)&&(identical(other.center, center) || other.center == center)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder));
}


@override
int get hashCode => Object.hash(runtimeType,id,countryId,nameAr,nameEn,center,isActive,sortOrder);

@override
String toString() {
  return 'City(id: $id, countryId: $countryId, nameAr: $nameAr, nameEn: $nameEn, center: $center, isActive: $isActive, sortOrder: $sortOrder)';
}


}

/// @nodoc
abstract mixin class _$CityCopyWith<$Res> implements $CityCopyWith<$Res> {
  factory _$CityCopyWith(_City value, $Res Function(_City) _then) = __$CityCopyWithImpl;
@override @useResult
$Res call({
 String id, String countryId, String nameAr, String? nameEn, GeoPoint center, bool isActive, int sortOrder
});




}
/// @nodoc
class __$CityCopyWithImpl<$Res>
    implements _$CityCopyWith<$Res> {
  __$CityCopyWithImpl(this._self, this._then);

  final _City _self;
  final $Res Function(_City) _then;

/// Create a copy of City
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? countryId = null,Object? nameAr = null,Object? nameEn = freezed,Object? center = null,Object? isActive = null,Object? sortOrder = null,}) {
  return _then(_City(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,countryId: null == countryId ? _self.countryId : countryId // ignore: cast_nullable_to_non_nullable
as String,nameAr: null == nameAr ? _self.nameAr : nameAr // ignore: cast_nullable_to_non_nullable
as String,nameEn: freezed == nameEn ? _self.nameEn : nameEn // ignore: cast_nullable_to_non_nullable
as String?,center: null == center ? _self.center : center // ignore: cast_nullable_to_non_nullable
as GeoPoint,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$ServiceArea {

 String get id; String get cityId; String get nameAr; GeoPoint get center; double get radiusKm; bool get isActive; String? get notes;
/// Create a copy of ServiceArea
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ServiceAreaCopyWith<ServiceArea> get copyWith => _$ServiceAreaCopyWithImpl<ServiceArea>(this as ServiceArea, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ServiceArea&&(identical(other.id, id) || other.id == id)&&(identical(other.cityId, cityId) || other.cityId == cityId)&&(identical(other.nameAr, nameAr) || other.nameAr == nameAr)&&(identical(other.center, center) || other.center == center)&&(identical(other.radiusKm, radiusKm) || other.radiusKm == radiusKm)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.notes, notes) || other.notes == notes));
}


@override
int get hashCode => Object.hash(runtimeType,id,cityId,nameAr,center,radiusKm,isActive,notes);

@override
String toString() {
  return 'ServiceArea(id: $id, cityId: $cityId, nameAr: $nameAr, center: $center, radiusKm: $radiusKm, isActive: $isActive, notes: $notes)';
}


}

/// @nodoc
abstract mixin class $ServiceAreaCopyWith<$Res>  {
  factory $ServiceAreaCopyWith(ServiceArea value, $Res Function(ServiceArea) _then) = _$ServiceAreaCopyWithImpl;
@useResult
$Res call({
 String id, String cityId, String nameAr, GeoPoint center, double radiusKm, bool isActive, String? notes
});




}
/// @nodoc
class _$ServiceAreaCopyWithImpl<$Res>
    implements $ServiceAreaCopyWith<$Res> {
  _$ServiceAreaCopyWithImpl(this._self, this._then);

  final ServiceArea _self;
  final $Res Function(ServiceArea) _then;

/// Create a copy of ServiceArea
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? cityId = null,Object? nameAr = null,Object? center = null,Object? radiusKm = null,Object? isActive = null,Object? notes = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,cityId: null == cityId ? _self.cityId : cityId // ignore: cast_nullable_to_non_nullable
as String,nameAr: null == nameAr ? _self.nameAr : nameAr // ignore: cast_nullable_to_non_nullable
as String,center: null == center ? _self.center : center // ignore: cast_nullable_to_non_nullable
as GeoPoint,radiusKm: null == radiusKm ? _self.radiusKm : radiusKm // ignore: cast_nullable_to_non_nullable
as double,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ServiceArea].
extension ServiceAreaPatterns on ServiceArea {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ServiceArea value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ServiceArea() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ServiceArea value)  $default,){
final _that = this;
switch (_that) {
case _ServiceArea():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ServiceArea value)?  $default,){
final _that = this;
switch (_that) {
case _ServiceArea() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String cityId,  String nameAr,  GeoPoint center,  double radiusKm,  bool isActive,  String? notes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ServiceArea() when $default != null:
return $default(_that.id,_that.cityId,_that.nameAr,_that.center,_that.radiusKm,_that.isActive,_that.notes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String cityId,  String nameAr,  GeoPoint center,  double radiusKm,  bool isActive,  String? notes)  $default,) {final _that = this;
switch (_that) {
case _ServiceArea():
return $default(_that.id,_that.cityId,_that.nameAr,_that.center,_that.radiusKm,_that.isActive,_that.notes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String cityId,  String nameAr,  GeoPoint center,  double radiusKm,  bool isActive,  String? notes)?  $default,) {final _that = this;
switch (_that) {
case _ServiceArea() when $default != null:
return $default(_that.id,_that.cityId,_that.nameAr,_that.center,_that.radiusKm,_that.isActive,_that.notes);case _:
  return null;

}
}

}

/// @nodoc


class _ServiceArea extends ServiceArea {
  const _ServiceArea({required this.id, required this.cityId, required this.nameAr, required this.center, required this.radiusKm, required this.isActive, this.notes}): super._();
  

@override final  String id;
@override final  String cityId;
@override final  String nameAr;
@override final  GeoPoint center;
@override final  double radiusKm;
@override final  bool isActive;
@override final  String? notes;

/// Create a copy of ServiceArea
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ServiceAreaCopyWith<_ServiceArea> get copyWith => __$ServiceAreaCopyWithImpl<_ServiceArea>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ServiceArea&&(identical(other.id, id) || other.id == id)&&(identical(other.cityId, cityId) || other.cityId == cityId)&&(identical(other.nameAr, nameAr) || other.nameAr == nameAr)&&(identical(other.center, center) || other.center == center)&&(identical(other.radiusKm, radiusKm) || other.radiusKm == radiusKm)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.notes, notes) || other.notes == notes));
}


@override
int get hashCode => Object.hash(runtimeType,id,cityId,nameAr,center,radiusKm,isActive,notes);

@override
String toString() {
  return 'ServiceArea(id: $id, cityId: $cityId, nameAr: $nameAr, center: $center, radiusKm: $radiusKm, isActive: $isActive, notes: $notes)';
}


}

/// @nodoc
abstract mixin class _$ServiceAreaCopyWith<$Res> implements $ServiceAreaCopyWith<$Res> {
  factory _$ServiceAreaCopyWith(_ServiceArea value, $Res Function(_ServiceArea) _then) = __$ServiceAreaCopyWithImpl;
@override @useResult
$Res call({
 String id, String cityId, String nameAr, GeoPoint center, double radiusKm, bool isActive, String? notes
});




}
/// @nodoc
class __$ServiceAreaCopyWithImpl<$Res>
    implements _$ServiceAreaCopyWith<$Res> {
  __$ServiceAreaCopyWithImpl(this._self, this._then);

  final _ServiceArea _self;
  final $Res Function(_ServiceArea) _then;

/// Create a copy of ServiceArea
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? cityId = null,Object? nameAr = null,Object? center = null,Object? radiusKm = null,Object? isActive = null,Object? notes = freezed,}) {
  return _then(_ServiceArea(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,cityId: null == cityId ? _self.cityId : cityId // ignore: cast_nullable_to_non_nullable
as String,nameAr: null == nameAr ? _self.nameAr : nameAr // ignore: cast_nullable_to_non_nullable
as String,center: null == center ? _self.center : center // ignore: cast_nullable_to_non_nullable
as GeoPoint,radiusKm: null == radiusKm ? _self.radiusKm : radiusKm // ignore: cast_nullable_to_non_nullable
as double,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$ServiceAvailability {

 bool get available; String? get serviceAreaId; String? get serviceAreaName;
/// Create a copy of ServiceAvailability
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ServiceAvailabilityCopyWith<ServiceAvailability> get copyWith => _$ServiceAvailabilityCopyWithImpl<ServiceAvailability>(this as ServiceAvailability, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ServiceAvailability&&(identical(other.available, available) || other.available == available)&&(identical(other.serviceAreaId, serviceAreaId) || other.serviceAreaId == serviceAreaId)&&(identical(other.serviceAreaName, serviceAreaName) || other.serviceAreaName == serviceAreaName));
}


@override
int get hashCode => Object.hash(runtimeType,available,serviceAreaId,serviceAreaName);

@override
String toString() {
  return 'ServiceAvailability(available: $available, serviceAreaId: $serviceAreaId, serviceAreaName: $serviceAreaName)';
}


}

/// @nodoc
abstract mixin class $ServiceAvailabilityCopyWith<$Res>  {
  factory $ServiceAvailabilityCopyWith(ServiceAvailability value, $Res Function(ServiceAvailability) _then) = _$ServiceAvailabilityCopyWithImpl;
@useResult
$Res call({
 bool available, String? serviceAreaId, String? serviceAreaName
});




}
/// @nodoc
class _$ServiceAvailabilityCopyWithImpl<$Res>
    implements $ServiceAvailabilityCopyWith<$Res> {
  _$ServiceAvailabilityCopyWithImpl(this._self, this._then);

  final ServiceAvailability _self;
  final $Res Function(ServiceAvailability) _then;

/// Create a copy of ServiceAvailability
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? available = null,Object? serviceAreaId = freezed,Object? serviceAreaName = freezed,}) {
  return _then(_self.copyWith(
available: null == available ? _self.available : available // ignore: cast_nullable_to_non_nullable
as bool,serviceAreaId: freezed == serviceAreaId ? _self.serviceAreaId : serviceAreaId // ignore: cast_nullable_to_non_nullable
as String?,serviceAreaName: freezed == serviceAreaName ? _self.serviceAreaName : serviceAreaName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ServiceAvailability].
extension ServiceAvailabilityPatterns on ServiceAvailability {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ServiceAvailability value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ServiceAvailability() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ServiceAvailability value)  $default,){
final _that = this;
switch (_that) {
case _ServiceAvailability():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ServiceAvailability value)?  $default,){
final _that = this;
switch (_that) {
case _ServiceAvailability() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool available,  String? serviceAreaId,  String? serviceAreaName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ServiceAvailability() when $default != null:
return $default(_that.available,_that.serviceAreaId,_that.serviceAreaName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool available,  String? serviceAreaId,  String? serviceAreaName)  $default,) {final _that = this;
switch (_that) {
case _ServiceAvailability():
return $default(_that.available,_that.serviceAreaId,_that.serviceAreaName);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool available,  String? serviceAreaId,  String? serviceAreaName)?  $default,) {final _that = this;
switch (_that) {
case _ServiceAvailability() when $default != null:
return $default(_that.available,_that.serviceAreaId,_that.serviceAreaName);case _:
  return null;

}
}

}

/// @nodoc


class _ServiceAvailability implements ServiceAvailability {
  const _ServiceAvailability({required this.available, this.serviceAreaId, this.serviceAreaName});
  

@override final  bool available;
@override final  String? serviceAreaId;
@override final  String? serviceAreaName;

/// Create a copy of ServiceAvailability
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ServiceAvailabilityCopyWith<_ServiceAvailability> get copyWith => __$ServiceAvailabilityCopyWithImpl<_ServiceAvailability>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ServiceAvailability&&(identical(other.available, available) || other.available == available)&&(identical(other.serviceAreaId, serviceAreaId) || other.serviceAreaId == serviceAreaId)&&(identical(other.serviceAreaName, serviceAreaName) || other.serviceAreaName == serviceAreaName));
}


@override
int get hashCode => Object.hash(runtimeType,available,serviceAreaId,serviceAreaName);

@override
String toString() {
  return 'ServiceAvailability(available: $available, serviceAreaId: $serviceAreaId, serviceAreaName: $serviceAreaName)';
}


}

/// @nodoc
abstract mixin class _$ServiceAvailabilityCopyWith<$Res> implements $ServiceAvailabilityCopyWith<$Res> {
  factory _$ServiceAvailabilityCopyWith(_ServiceAvailability value, $Res Function(_ServiceAvailability) _then) = __$ServiceAvailabilityCopyWithImpl;
@override @useResult
$Res call({
 bool available, String? serviceAreaId, String? serviceAreaName
});




}
/// @nodoc
class __$ServiceAvailabilityCopyWithImpl<$Res>
    implements _$ServiceAvailabilityCopyWith<$Res> {
  __$ServiceAvailabilityCopyWithImpl(this._self, this._then);

  final _ServiceAvailability _self;
  final $Res Function(_ServiceAvailability) _then;

/// Create a copy of ServiceAvailability
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? available = null,Object? serviceAreaId = freezed,Object? serviceAreaName = freezed,}) {
  return _then(_ServiceAvailability(
available: null == available ? _self.available : available // ignore: cast_nullable_to_non_nullable
as bool,serviceAreaId: freezed == serviceAreaId ? _self.serviceAreaId : serviceAreaId // ignore: cast_nullable_to_non_nullable
as String?,serviceAreaName: freezed == serviceAreaName ? _self.serviceAreaName : serviceAreaName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$CustomerAddress {

 String get id; String get cityId; String? get cityName; String? get serviceAreaId; String? get serviceAreaName; String get label; String? get recipientName; String? get phone; String get addressLine; String? get building; String? get floor; String? get apartment; String? get landmark; GeoPoint get location; bool get isDefault;
/// Create a copy of CustomerAddress
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CustomerAddressCopyWith<CustomerAddress> get copyWith => _$CustomerAddressCopyWithImpl<CustomerAddress>(this as CustomerAddress, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CustomerAddress&&(identical(other.id, id) || other.id == id)&&(identical(other.cityId, cityId) || other.cityId == cityId)&&(identical(other.cityName, cityName) || other.cityName == cityName)&&(identical(other.serviceAreaId, serviceAreaId) || other.serviceAreaId == serviceAreaId)&&(identical(other.serviceAreaName, serviceAreaName) || other.serviceAreaName == serviceAreaName)&&(identical(other.label, label) || other.label == label)&&(identical(other.recipientName, recipientName) || other.recipientName == recipientName)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.addressLine, addressLine) || other.addressLine == addressLine)&&(identical(other.building, building) || other.building == building)&&(identical(other.floor, floor) || other.floor == floor)&&(identical(other.apartment, apartment) || other.apartment == apartment)&&(identical(other.landmark, landmark) || other.landmark == landmark)&&(identical(other.location, location) || other.location == location)&&(identical(other.isDefault, isDefault) || other.isDefault == isDefault));
}


@override
int get hashCode => Object.hash(runtimeType,id,cityId,cityName,serviceAreaId,serviceAreaName,label,recipientName,phone,addressLine,building,floor,apartment,landmark,location,isDefault);

@override
String toString() {
  return 'CustomerAddress(id: $id, cityId: $cityId, cityName: $cityName, serviceAreaId: $serviceAreaId, serviceAreaName: $serviceAreaName, label: $label, recipientName: $recipientName, phone: $phone, addressLine: $addressLine, building: $building, floor: $floor, apartment: $apartment, landmark: $landmark, location: $location, isDefault: $isDefault)';
}


}

/// @nodoc
abstract mixin class $CustomerAddressCopyWith<$Res>  {
  factory $CustomerAddressCopyWith(CustomerAddress value, $Res Function(CustomerAddress) _then) = _$CustomerAddressCopyWithImpl;
@useResult
$Res call({
 String id, String cityId, String? cityName, String? serviceAreaId, String? serviceAreaName, String label, String? recipientName, String? phone, String addressLine, String? building, String? floor, String? apartment, String? landmark, GeoPoint location, bool isDefault
});




}
/// @nodoc
class _$CustomerAddressCopyWithImpl<$Res>
    implements $CustomerAddressCopyWith<$Res> {
  _$CustomerAddressCopyWithImpl(this._self, this._then);

  final CustomerAddress _self;
  final $Res Function(CustomerAddress) _then;

/// Create a copy of CustomerAddress
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? cityId = null,Object? cityName = freezed,Object? serviceAreaId = freezed,Object? serviceAreaName = freezed,Object? label = null,Object? recipientName = freezed,Object? phone = freezed,Object? addressLine = null,Object? building = freezed,Object? floor = freezed,Object? apartment = freezed,Object? landmark = freezed,Object? location = null,Object? isDefault = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,cityId: null == cityId ? _self.cityId : cityId // ignore: cast_nullable_to_non_nullable
as String,cityName: freezed == cityName ? _self.cityName : cityName // ignore: cast_nullable_to_non_nullable
as String?,serviceAreaId: freezed == serviceAreaId ? _self.serviceAreaId : serviceAreaId // ignore: cast_nullable_to_non_nullable
as String?,serviceAreaName: freezed == serviceAreaName ? _self.serviceAreaName : serviceAreaName // ignore: cast_nullable_to_non_nullable
as String?,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,recipientName: freezed == recipientName ? _self.recipientName : recipientName // ignore: cast_nullable_to_non_nullable
as String?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,addressLine: null == addressLine ? _self.addressLine : addressLine // ignore: cast_nullable_to_non_nullable
as String,building: freezed == building ? _self.building : building // ignore: cast_nullable_to_non_nullable
as String?,floor: freezed == floor ? _self.floor : floor // ignore: cast_nullable_to_non_nullable
as String?,apartment: freezed == apartment ? _self.apartment : apartment // ignore: cast_nullable_to_non_nullable
as String?,landmark: freezed == landmark ? _self.landmark : landmark // ignore: cast_nullable_to_non_nullable
as String?,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as GeoPoint,isDefault: null == isDefault ? _self.isDefault : isDefault // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [CustomerAddress].
extension CustomerAddressPatterns on CustomerAddress {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CustomerAddress value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CustomerAddress() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CustomerAddress value)  $default,){
final _that = this;
switch (_that) {
case _CustomerAddress():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CustomerAddress value)?  $default,){
final _that = this;
switch (_that) {
case _CustomerAddress() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String cityId,  String? cityName,  String? serviceAreaId,  String? serviceAreaName,  String label,  String? recipientName,  String? phone,  String addressLine,  String? building,  String? floor,  String? apartment,  String? landmark,  GeoPoint location,  bool isDefault)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CustomerAddress() when $default != null:
return $default(_that.id,_that.cityId,_that.cityName,_that.serviceAreaId,_that.serviceAreaName,_that.label,_that.recipientName,_that.phone,_that.addressLine,_that.building,_that.floor,_that.apartment,_that.landmark,_that.location,_that.isDefault);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String cityId,  String? cityName,  String? serviceAreaId,  String? serviceAreaName,  String label,  String? recipientName,  String? phone,  String addressLine,  String? building,  String? floor,  String? apartment,  String? landmark,  GeoPoint location,  bool isDefault)  $default,) {final _that = this;
switch (_that) {
case _CustomerAddress():
return $default(_that.id,_that.cityId,_that.cityName,_that.serviceAreaId,_that.serviceAreaName,_that.label,_that.recipientName,_that.phone,_that.addressLine,_that.building,_that.floor,_that.apartment,_that.landmark,_that.location,_that.isDefault);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String cityId,  String? cityName,  String? serviceAreaId,  String? serviceAreaName,  String label,  String? recipientName,  String? phone,  String addressLine,  String? building,  String? floor,  String? apartment,  String? landmark,  GeoPoint location,  bool isDefault)?  $default,) {final _that = this;
switch (_that) {
case _CustomerAddress() when $default != null:
return $default(_that.id,_that.cityId,_that.cityName,_that.serviceAreaId,_that.serviceAreaName,_that.label,_that.recipientName,_that.phone,_that.addressLine,_that.building,_that.floor,_that.apartment,_that.landmark,_that.location,_that.isDefault);case _:
  return null;

}
}

}

/// @nodoc


class _CustomerAddress extends CustomerAddress {
  const _CustomerAddress({required this.id, required this.cityId, this.cityName, this.serviceAreaId, this.serviceAreaName, required this.label, this.recipientName, this.phone, required this.addressLine, this.building, this.floor, this.apartment, this.landmark, required this.location, required this.isDefault}): super._();
  

@override final  String id;
@override final  String cityId;
@override final  String? cityName;
@override final  String? serviceAreaId;
@override final  String? serviceAreaName;
@override final  String label;
@override final  String? recipientName;
@override final  String? phone;
@override final  String addressLine;
@override final  String? building;
@override final  String? floor;
@override final  String? apartment;
@override final  String? landmark;
@override final  GeoPoint location;
@override final  bool isDefault;

/// Create a copy of CustomerAddress
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CustomerAddressCopyWith<_CustomerAddress> get copyWith => __$CustomerAddressCopyWithImpl<_CustomerAddress>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CustomerAddress&&(identical(other.id, id) || other.id == id)&&(identical(other.cityId, cityId) || other.cityId == cityId)&&(identical(other.cityName, cityName) || other.cityName == cityName)&&(identical(other.serviceAreaId, serviceAreaId) || other.serviceAreaId == serviceAreaId)&&(identical(other.serviceAreaName, serviceAreaName) || other.serviceAreaName == serviceAreaName)&&(identical(other.label, label) || other.label == label)&&(identical(other.recipientName, recipientName) || other.recipientName == recipientName)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.addressLine, addressLine) || other.addressLine == addressLine)&&(identical(other.building, building) || other.building == building)&&(identical(other.floor, floor) || other.floor == floor)&&(identical(other.apartment, apartment) || other.apartment == apartment)&&(identical(other.landmark, landmark) || other.landmark == landmark)&&(identical(other.location, location) || other.location == location)&&(identical(other.isDefault, isDefault) || other.isDefault == isDefault));
}


@override
int get hashCode => Object.hash(runtimeType,id,cityId,cityName,serviceAreaId,serviceAreaName,label,recipientName,phone,addressLine,building,floor,apartment,landmark,location,isDefault);

@override
String toString() {
  return 'CustomerAddress(id: $id, cityId: $cityId, cityName: $cityName, serviceAreaId: $serviceAreaId, serviceAreaName: $serviceAreaName, label: $label, recipientName: $recipientName, phone: $phone, addressLine: $addressLine, building: $building, floor: $floor, apartment: $apartment, landmark: $landmark, location: $location, isDefault: $isDefault)';
}


}

/// @nodoc
abstract mixin class _$CustomerAddressCopyWith<$Res> implements $CustomerAddressCopyWith<$Res> {
  factory _$CustomerAddressCopyWith(_CustomerAddress value, $Res Function(_CustomerAddress) _then) = __$CustomerAddressCopyWithImpl;
@override @useResult
$Res call({
 String id, String cityId, String? cityName, String? serviceAreaId, String? serviceAreaName, String label, String? recipientName, String? phone, String addressLine, String? building, String? floor, String? apartment, String? landmark, GeoPoint location, bool isDefault
});




}
/// @nodoc
class __$CustomerAddressCopyWithImpl<$Res>
    implements _$CustomerAddressCopyWith<$Res> {
  __$CustomerAddressCopyWithImpl(this._self, this._then);

  final _CustomerAddress _self;
  final $Res Function(_CustomerAddress) _then;

/// Create a copy of CustomerAddress
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? cityId = null,Object? cityName = freezed,Object? serviceAreaId = freezed,Object? serviceAreaName = freezed,Object? label = null,Object? recipientName = freezed,Object? phone = freezed,Object? addressLine = null,Object? building = freezed,Object? floor = freezed,Object? apartment = freezed,Object? landmark = freezed,Object? location = null,Object? isDefault = null,}) {
  return _then(_CustomerAddress(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,cityId: null == cityId ? _self.cityId : cityId // ignore: cast_nullable_to_non_nullable
as String,cityName: freezed == cityName ? _self.cityName : cityName // ignore: cast_nullable_to_non_nullable
as String?,serviceAreaId: freezed == serviceAreaId ? _self.serviceAreaId : serviceAreaId // ignore: cast_nullable_to_non_nullable
as String?,serviceAreaName: freezed == serviceAreaName ? _self.serviceAreaName : serviceAreaName // ignore: cast_nullable_to_non_nullable
as String?,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,recipientName: freezed == recipientName ? _self.recipientName : recipientName // ignore: cast_nullable_to_non_nullable
as String?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,addressLine: null == addressLine ? _self.addressLine : addressLine // ignore: cast_nullable_to_non_nullable
as String,building: freezed == building ? _self.building : building // ignore: cast_nullable_to_non_nullable
as String?,floor: freezed == floor ? _self.floor : floor // ignore: cast_nullable_to_non_nullable
as String?,apartment: freezed == apartment ? _self.apartment : apartment // ignore: cast_nullable_to_non_nullable
as String?,landmark: freezed == landmark ? _self.landmark : landmark // ignore: cast_nullable_to_non_nullable
as String?,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as GeoPoint,isDefault: null == isDefault ? _self.isDefault : isDefault // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$Country {

 String get id; String get isoCode; String get nameAr; bool get isActive;
/// Create a copy of Country
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CountryCopyWith<Country> get copyWith => _$CountryCopyWithImpl<Country>(this as Country, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Country&&(identical(other.id, id) || other.id == id)&&(identical(other.isoCode, isoCode) || other.isoCode == isoCode)&&(identical(other.nameAr, nameAr) || other.nameAr == nameAr)&&(identical(other.isActive, isActive) || other.isActive == isActive));
}


@override
int get hashCode => Object.hash(runtimeType,id,isoCode,nameAr,isActive);

@override
String toString() {
  return 'Country(id: $id, isoCode: $isoCode, nameAr: $nameAr, isActive: $isActive)';
}


}

/// @nodoc
abstract mixin class $CountryCopyWith<$Res>  {
  factory $CountryCopyWith(Country value, $Res Function(Country) _then) = _$CountryCopyWithImpl;
@useResult
$Res call({
 String id, String isoCode, String nameAr, bool isActive
});




}
/// @nodoc
class _$CountryCopyWithImpl<$Res>
    implements $CountryCopyWith<$Res> {
  _$CountryCopyWithImpl(this._self, this._then);

  final Country _self;
  final $Res Function(Country) _then;

/// Create a copy of Country
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? isoCode = null,Object? nameAr = null,Object? isActive = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,isoCode: null == isoCode ? _self.isoCode : isoCode // ignore: cast_nullable_to_non_nullable
as String,nameAr: null == nameAr ? _self.nameAr : nameAr // ignore: cast_nullable_to_non_nullable
as String,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Country].
extension CountryPatterns on Country {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Country value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Country() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Country value)  $default,){
final _that = this;
switch (_that) {
case _Country():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Country value)?  $default,){
final _that = this;
switch (_that) {
case _Country() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String isoCode,  String nameAr,  bool isActive)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Country() when $default != null:
return $default(_that.id,_that.isoCode,_that.nameAr,_that.isActive);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String isoCode,  String nameAr,  bool isActive)  $default,) {final _that = this;
switch (_that) {
case _Country():
return $default(_that.id,_that.isoCode,_that.nameAr,_that.isActive);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String isoCode,  String nameAr,  bool isActive)?  $default,) {final _that = this;
switch (_that) {
case _Country() when $default != null:
return $default(_that.id,_that.isoCode,_that.nameAr,_that.isActive);case _:
  return null;

}
}

}

/// @nodoc


class _Country implements Country {
  const _Country({required this.id, required this.isoCode, required this.nameAr, required this.isActive});
  

@override final  String id;
@override final  String isoCode;
@override final  String nameAr;
@override final  bool isActive;

/// Create a copy of Country
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CountryCopyWith<_Country> get copyWith => __$CountryCopyWithImpl<_Country>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Country&&(identical(other.id, id) || other.id == id)&&(identical(other.isoCode, isoCode) || other.isoCode == isoCode)&&(identical(other.nameAr, nameAr) || other.nameAr == nameAr)&&(identical(other.isActive, isActive) || other.isActive == isActive));
}


@override
int get hashCode => Object.hash(runtimeType,id,isoCode,nameAr,isActive);

@override
String toString() {
  return 'Country(id: $id, isoCode: $isoCode, nameAr: $nameAr, isActive: $isActive)';
}


}

/// @nodoc
abstract mixin class _$CountryCopyWith<$Res> implements $CountryCopyWith<$Res> {
  factory _$CountryCopyWith(_Country value, $Res Function(_Country) _then) = __$CountryCopyWithImpl;
@override @useResult
$Res call({
 String id, String isoCode, String nameAr, bool isActive
});




}
/// @nodoc
class __$CountryCopyWithImpl<$Res>
    implements _$CountryCopyWith<$Res> {
  __$CountryCopyWithImpl(this._self, this._then);

  final _Country _self;
  final $Res Function(_Country) _then;

/// Create a copy of Country
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? isoCode = null,Object? nameAr = null,Object? isActive = null,}) {
  return _then(_Country(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,isoCode: null == isoCode ? _self.isoCode : isoCode // ignore: cast_nullable_to_non_nullable
as String,nameAr: null == nameAr ? _self.nameAr : nameAr // ignore: cast_nullable_to_non_nullable
as String,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
