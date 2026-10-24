// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'inventory_count.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$InventoryCount {

 String get id; int get countNumber; InventoryCountStatus get status; DateTime get startedAt; DateTime? get completedAt; String? get notes; bool get isBag;/// The warehouse's or bag's id.
 String? get locationId;/// The bag's technician (0089) — filled in by the repository, null for
/// the warehouse.
 String? get technicianName;/// The technician sent his own bag count for review (0089); it's
/// read-only for him from then on.
 DateTime? get submittedAt;
/// Create a copy of InventoryCount
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InventoryCountCopyWith<InventoryCount> get copyWith => _$InventoryCountCopyWithImpl<InventoryCount>(this as InventoryCount, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InventoryCount&&(identical(other.id, id) || other.id == id)&&(identical(other.countNumber, countNumber) || other.countNumber == countNumber)&&(identical(other.status, status) || other.status == status)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.isBag, isBag) || other.isBag == isBag)&&(identical(other.locationId, locationId) || other.locationId == locationId)&&(identical(other.technicianName, technicianName) || other.technicianName == technicianName)&&(identical(other.submittedAt, submittedAt) || other.submittedAt == submittedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,countNumber,status,startedAt,completedAt,notes,isBag,locationId,technicianName,submittedAt);

@override
String toString() {
  return 'InventoryCount(id: $id, countNumber: $countNumber, status: $status, startedAt: $startedAt, completedAt: $completedAt, notes: $notes, isBag: $isBag, locationId: $locationId, technicianName: $technicianName, submittedAt: $submittedAt)';
}


}

/// @nodoc
abstract mixin class $InventoryCountCopyWith<$Res>  {
  factory $InventoryCountCopyWith(InventoryCount value, $Res Function(InventoryCount) _then) = _$InventoryCountCopyWithImpl;
@useResult
$Res call({
 String id, int countNumber, InventoryCountStatus status, DateTime startedAt, DateTime? completedAt, String? notes, bool isBag, String? locationId, String? technicianName, DateTime? submittedAt
});




}
/// @nodoc
class _$InventoryCountCopyWithImpl<$Res>
    implements $InventoryCountCopyWith<$Res> {
  _$InventoryCountCopyWithImpl(this._self, this._then);

  final InventoryCount _self;
  final $Res Function(InventoryCount) _then;

/// Create a copy of InventoryCount
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? countNumber = null,Object? status = null,Object? startedAt = null,Object? completedAt = freezed,Object? notes = freezed,Object? isBag = null,Object? locationId = freezed,Object? technicianName = freezed,Object? submittedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,countNumber: null == countNumber ? _self.countNumber : countNumber // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as InventoryCountStatus,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,isBag: null == isBag ? _self.isBag : isBag // ignore: cast_nullable_to_non_nullable
as bool,locationId: freezed == locationId ? _self.locationId : locationId // ignore: cast_nullable_to_non_nullable
as String?,technicianName: freezed == technicianName ? _self.technicianName : technicianName // ignore: cast_nullable_to_non_nullable
as String?,submittedAt: freezed == submittedAt ? _self.submittedAt : submittedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [InventoryCount].
extension InventoryCountPatterns on InventoryCount {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InventoryCount value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InventoryCount() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InventoryCount value)  $default,){
final _that = this;
switch (_that) {
case _InventoryCount():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InventoryCount value)?  $default,){
final _that = this;
switch (_that) {
case _InventoryCount() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  int countNumber,  InventoryCountStatus status,  DateTime startedAt,  DateTime? completedAt,  String? notes,  bool isBag,  String? locationId,  String? technicianName,  DateTime? submittedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InventoryCount() when $default != null:
return $default(_that.id,_that.countNumber,_that.status,_that.startedAt,_that.completedAt,_that.notes,_that.isBag,_that.locationId,_that.technicianName,_that.submittedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  int countNumber,  InventoryCountStatus status,  DateTime startedAt,  DateTime? completedAt,  String? notes,  bool isBag,  String? locationId,  String? technicianName,  DateTime? submittedAt)  $default,) {final _that = this;
switch (_that) {
case _InventoryCount():
return $default(_that.id,_that.countNumber,_that.status,_that.startedAt,_that.completedAt,_that.notes,_that.isBag,_that.locationId,_that.technicianName,_that.submittedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  int countNumber,  InventoryCountStatus status,  DateTime startedAt,  DateTime? completedAt,  String? notes,  bool isBag,  String? locationId,  String? technicianName,  DateTime? submittedAt)?  $default,) {final _that = this;
switch (_that) {
case _InventoryCount() when $default != null:
return $default(_that.id,_that.countNumber,_that.status,_that.startedAt,_that.completedAt,_that.notes,_that.isBag,_that.locationId,_that.technicianName,_that.submittedAt);case _:
  return null;

}
}

}

/// @nodoc


class _InventoryCount extends InventoryCount {
  const _InventoryCount({required this.id, required this.countNumber, required this.status, required this.startedAt, this.completedAt, this.notes, this.isBag = false, this.locationId, this.technicianName, this.submittedAt}): super._();
  

@override final  String id;
@override final  int countNumber;
@override final  InventoryCountStatus status;
@override final  DateTime startedAt;
@override final  DateTime? completedAt;
@override final  String? notes;
@override@JsonKey() final  bool isBag;
/// The warehouse's or bag's id.
@override final  String? locationId;
/// The bag's technician (0089) — filled in by the repository, null for
/// the warehouse.
@override final  String? technicianName;
/// The technician sent his own bag count for review (0089); it's
/// read-only for him from then on.
@override final  DateTime? submittedAt;

/// Create a copy of InventoryCount
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InventoryCountCopyWith<_InventoryCount> get copyWith => __$InventoryCountCopyWithImpl<_InventoryCount>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InventoryCount&&(identical(other.id, id) || other.id == id)&&(identical(other.countNumber, countNumber) || other.countNumber == countNumber)&&(identical(other.status, status) || other.status == status)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.isBag, isBag) || other.isBag == isBag)&&(identical(other.locationId, locationId) || other.locationId == locationId)&&(identical(other.technicianName, technicianName) || other.technicianName == technicianName)&&(identical(other.submittedAt, submittedAt) || other.submittedAt == submittedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,countNumber,status,startedAt,completedAt,notes,isBag,locationId,technicianName,submittedAt);

@override
String toString() {
  return 'InventoryCount(id: $id, countNumber: $countNumber, status: $status, startedAt: $startedAt, completedAt: $completedAt, notes: $notes, isBag: $isBag, locationId: $locationId, technicianName: $technicianName, submittedAt: $submittedAt)';
}


}

/// @nodoc
abstract mixin class _$InventoryCountCopyWith<$Res> implements $InventoryCountCopyWith<$Res> {
  factory _$InventoryCountCopyWith(_InventoryCount value, $Res Function(_InventoryCount) _then) = __$InventoryCountCopyWithImpl;
@override @useResult
$Res call({
 String id, int countNumber, InventoryCountStatus status, DateTime startedAt, DateTime? completedAt, String? notes, bool isBag, String? locationId, String? technicianName, DateTime? submittedAt
});




}
/// @nodoc
class __$InventoryCountCopyWithImpl<$Res>
    implements _$InventoryCountCopyWith<$Res> {
  __$InventoryCountCopyWithImpl(this._self, this._then);

  final _InventoryCount _self;
  final $Res Function(_InventoryCount) _then;

/// Create a copy of InventoryCount
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? countNumber = null,Object? status = null,Object? startedAt = null,Object? completedAt = freezed,Object? notes = freezed,Object? isBag = null,Object? locationId = freezed,Object? technicianName = freezed,Object? submittedAt = freezed,}) {
  return _then(_InventoryCount(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,countNumber: null == countNumber ? _self.countNumber : countNumber // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as InventoryCountStatus,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,isBag: null == isBag ? _self.isBag : isBag // ignore: cast_nullable_to_non_nullable
as bool,locationId: freezed == locationId ? _self.locationId : locationId // ignore: cast_nullable_to_non_nullable
as String?,technicianName: freezed == technicianName ? _self.technicianName : technicianName // ignore: cast_nullable_to_non_nullable
as String?,submittedAt: freezed == submittedAt ? _self.submittedAt : submittedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
