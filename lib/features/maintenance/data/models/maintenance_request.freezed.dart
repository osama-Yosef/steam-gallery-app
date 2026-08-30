// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'maintenance_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MaintenanceRequest {

 String get id; int get ticketNumber; String get customerId; String get customerName; String get phone; String? get address; double? get latitude; double? get longitude; String? get deviceType; String get problemDescription; String? get notes; MaintenanceStatus get status; String? get assignedTechnicianId; DateTime get createdAt; DateTime? get assignedAt; DateTime? get startedAt; DateTime? get completedAt; DateTime? get cancelledAt; String? get cancelledReason;
/// Create a copy of MaintenanceRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MaintenanceRequestCopyWith<MaintenanceRequest> get copyWith => _$MaintenanceRequestCopyWithImpl<MaintenanceRequest>(this as MaintenanceRequest, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MaintenanceRequest&&(identical(other.id, id) || other.id == id)&&(identical(other.ticketNumber, ticketNumber) || other.ticketNumber == ticketNumber)&&(identical(other.customerId, customerId) || other.customerId == customerId)&&(identical(other.customerName, customerName) || other.customerName == customerName)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.address, address) || other.address == address)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.deviceType, deviceType) || other.deviceType == deviceType)&&(identical(other.problemDescription, problemDescription) || other.problemDescription == problemDescription)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.status, status) || other.status == status)&&(identical(other.assignedTechnicianId, assignedTechnicianId) || other.assignedTechnicianId == assignedTechnicianId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.assignedAt, assignedAt) || other.assignedAt == assignedAt)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.cancelledAt, cancelledAt) || other.cancelledAt == cancelledAt)&&(identical(other.cancelledReason, cancelledReason) || other.cancelledReason == cancelledReason));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,ticketNumber,customerId,customerName,phone,address,latitude,longitude,deviceType,problemDescription,notes,status,assignedTechnicianId,createdAt,assignedAt,startedAt,completedAt,cancelledAt,cancelledReason]);

@override
String toString() {
  return 'MaintenanceRequest(id: $id, ticketNumber: $ticketNumber, customerId: $customerId, customerName: $customerName, phone: $phone, address: $address, latitude: $latitude, longitude: $longitude, deviceType: $deviceType, problemDescription: $problemDescription, notes: $notes, status: $status, assignedTechnicianId: $assignedTechnicianId, createdAt: $createdAt, assignedAt: $assignedAt, startedAt: $startedAt, completedAt: $completedAt, cancelledAt: $cancelledAt, cancelledReason: $cancelledReason)';
}


}

/// @nodoc
abstract mixin class $MaintenanceRequestCopyWith<$Res>  {
  factory $MaintenanceRequestCopyWith(MaintenanceRequest value, $Res Function(MaintenanceRequest) _then) = _$MaintenanceRequestCopyWithImpl;
@useResult
$Res call({
 String id, int ticketNumber, String customerId, String customerName, String phone, String? address, double? latitude, double? longitude, String? deviceType, String problemDescription, String? notes, MaintenanceStatus status, String? assignedTechnicianId, DateTime createdAt, DateTime? assignedAt, DateTime? startedAt, DateTime? completedAt, DateTime? cancelledAt, String? cancelledReason
});




}
/// @nodoc
class _$MaintenanceRequestCopyWithImpl<$Res>
    implements $MaintenanceRequestCopyWith<$Res> {
  _$MaintenanceRequestCopyWithImpl(this._self, this._then);

  final MaintenanceRequest _self;
  final $Res Function(MaintenanceRequest) _then;

/// Create a copy of MaintenanceRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? ticketNumber = null,Object? customerId = null,Object? customerName = null,Object? phone = null,Object? address = freezed,Object? latitude = freezed,Object? longitude = freezed,Object? deviceType = freezed,Object? problemDescription = null,Object? notes = freezed,Object? status = null,Object? assignedTechnicianId = freezed,Object? createdAt = null,Object? assignedAt = freezed,Object? startedAt = freezed,Object? completedAt = freezed,Object? cancelledAt = freezed,Object? cancelledReason = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,ticketNumber: null == ticketNumber ? _self.ticketNumber : ticketNumber // ignore: cast_nullable_to_non_nullable
as int,customerId: null == customerId ? _self.customerId : customerId // ignore: cast_nullable_to_non_nullable
as String,customerName: null == customerName ? _self.customerName : customerName // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,latitude: freezed == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double?,longitude: freezed == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double?,deviceType: freezed == deviceType ? _self.deviceType : deviceType // ignore: cast_nullable_to_non_nullable
as String?,problemDescription: null == problemDescription ? _self.problemDescription : problemDescription // ignore: cast_nullable_to_non_nullable
as String,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as MaintenanceStatus,assignedTechnicianId: freezed == assignedTechnicianId ? _self.assignedTechnicianId : assignedTechnicianId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,assignedAt: freezed == assignedAt ? _self.assignedAt : assignedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,cancelledAt: freezed == cancelledAt ? _self.cancelledAt : cancelledAt // ignore: cast_nullable_to_non_nullable
as DateTime?,cancelledReason: freezed == cancelledReason ? _self.cancelledReason : cancelledReason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [MaintenanceRequest].
extension MaintenanceRequestPatterns on MaintenanceRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MaintenanceRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MaintenanceRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MaintenanceRequest value)  $default,){
final _that = this;
switch (_that) {
case _MaintenanceRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MaintenanceRequest value)?  $default,){
final _that = this;
switch (_that) {
case _MaintenanceRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  int ticketNumber,  String customerId,  String customerName,  String phone,  String? address,  double? latitude,  double? longitude,  String? deviceType,  String problemDescription,  String? notes,  MaintenanceStatus status,  String? assignedTechnicianId,  DateTime createdAt,  DateTime? assignedAt,  DateTime? startedAt,  DateTime? completedAt,  DateTime? cancelledAt,  String? cancelledReason)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MaintenanceRequest() when $default != null:
return $default(_that.id,_that.ticketNumber,_that.customerId,_that.customerName,_that.phone,_that.address,_that.latitude,_that.longitude,_that.deviceType,_that.problemDescription,_that.notes,_that.status,_that.assignedTechnicianId,_that.createdAt,_that.assignedAt,_that.startedAt,_that.completedAt,_that.cancelledAt,_that.cancelledReason);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  int ticketNumber,  String customerId,  String customerName,  String phone,  String? address,  double? latitude,  double? longitude,  String? deviceType,  String problemDescription,  String? notes,  MaintenanceStatus status,  String? assignedTechnicianId,  DateTime createdAt,  DateTime? assignedAt,  DateTime? startedAt,  DateTime? completedAt,  DateTime? cancelledAt,  String? cancelledReason)  $default,) {final _that = this;
switch (_that) {
case _MaintenanceRequest():
return $default(_that.id,_that.ticketNumber,_that.customerId,_that.customerName,_that.phone,_that.address,_that.latitude,_that.longitude,_that.deviceType,_that.problemDescription,_that.notes,_that.status,_that.assignedTechnicianId,_that.createdAt,_that.assignedAt,_that.startedAt,_that.completedAt,_that.cancelledAt,_that.cancelledReason);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  int ticketNumber,  String customerId,  String customerName,  String phone,  String? address,  double? latitude,  double? longitude,  String? deviceType,  String problemDescription,  String? notes,  MaintenanceStatus status,  String? assignedTechnicianId,  DateTime createdAt,  DateTime? assignedAt,  DateTime? startedAt,  DateTime? completedAt,  DateTime? cancelledAt,  String? cancelledReason)?  $default,) {final _that = this;
switch (_that) {
case _MaintenanceRequest() when $default != null:
return $default(_that.id,_that.ticketNumber,_that.customerId,_that.customerName,_that.phone,_that.address,_that.latitude,_that.longitude,_that.deviceType,_that.problemDescription,_that.notes,_that.status,_that.assignedTechnicianId,_that.createdAt,_that.assignedAt,_that.startedAt,_that.completedAt,_that.cancelledAt,_that.cancelledReason);case _:
  return null;

}
}

}

/// @nodoc


class _MaintenanceRequest implements MaintenanceRequest {
  const _MaintenanceRequest({required this.id, required this.ticketNumber, required this.customerId, required this.customerName, required this.phone, this.address, this.latitude, this.longitude, this.deviceType, required this.problemDescription, this.notes, required this.status, this.assignedTechnicianId, required this.createdAt, this.assignedAt, this.startedAt, this.completedAt, this.cancelledAt, this.cancelledReason});
  

@override final  String id;
@override final  int ticketNumber;
@override final  String customerId;
@override final  String customerName;
@override final  String phone;
@override final  String? address;
@override final  double? latitude;
@override final  double? longitude;
@override final  String? deviceType;
@override final  String problemDescription;
@override final  String? notes;
@override final  MaintenanceStatus status;
@override final  String? assignedTechnicianId;
@override final  DateTime createdAt;
@override final  DateTime? assignedAt;
@override final  DateTime? startedAt;
@override final  DateTime? completedAt;
@override final  DateTime? cancelledAt;
@override final  String? cancelledReason;

/// Create a copy of MaintenanceRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MaintenanceRequestCopyWith<_MaintenanceRequest> get copyWith => __$MaintenanceRequestCopyWithImpl<_MaintenanceRequest>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MaintenanceRequest&&(identical(other.id, id) || other.id == id)&&(identical(other.ticketNumber, ticketNumber) || other.ticketNumber == ticketNumber)&&(identical(other.customerId, customerId) || other.customerId == customerId)&&(identical(other.customerName, customerName) || other.customerName == customerName)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.address, address) || other.address == address)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.deviceType, deviceType) || other.deviceType == deviceType)&&(identical(other.problemDescription, problemDescription) || other.problemDescription == problemDescription)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.status, status) || other.status == status)&&(identical(other.assignedTechnicianId, assignedTechnicianId) || other.assignedTechnicianId == assignedTechnicianId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.assignedAt, assignedAt) || other.assignedAt == assignedAt)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.cancelledAt, cancelledAt) || other.cancelledAt == cancelledAt)&&(identical(other.cancelledReason, cancelledReason) || other.cancelledReason == cancelledReason));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,ticketNumber,customerId,customerName,phone,address,latitude,longitude,deviceType,problemDescription,notes,status,assignedTechnicianId,createdAt,assignedAt,startedAt,completedAt,cancelledAt,cancelledReason]);

@override
String toString() {
  return 'MaintenanceRequest(id: $id, ticketNumber: $ticketNumber, customerId: $customerId, customerName: $customerName, phone: $phone, address: $address, latitude: $latitude, longitude: $longitude, deviceType: $deviceType, problemDescription: $problemDescription, notes: $notes, status: $status, assignedTechnicianId: $assignedTechnicianId, createdAt: $createdAt, assignedAt: $assignedAt, startedAt: $startedAt, completedAt: $completedAt, cancelledAt: $cancelledAt, cancelledReason: $cancelledReason)';
}


}

/// @nodoc
abstract mixin class _$MaintenanceRequestCopyWith<$Res> implements $MaintenanceRequestCopyWith<$Res> {
  factory _$MaintenanceRequestCopyWith(_MaintenanceRequest value, $Res Function(_MaintenanceRequest) _then) = __$MaintenanceRequestCopyWithImpl;
@override @useResult
$Res call({
 String id, int ticketNumber, String customerId, String customerName, String phone, String? address, double? latitude, double? longitude, String? deviceType, String problemDescription, String? notes, MaintenanceStatus status, String? assignedTechnicianId, DateTime createdAt, DateTime? assignedAt, DateTime? startedAt, DateTime? completedAt, DateTime? cancelledAt, String? cancelledReason
});




}
/// @nodoc
class __$MaintenanceRequestCopyWithImpl<$Res>
    implements _$MaintenanceRequestCopyWith<$Res> {
  __$MaintenanceRequestCopyWithImpl(this._self, this._then);

  final _MaintenanceRequest _self;
  final $Res Function(_MaintenanceRequest) _then;

/// Create a copy of MaintenanceRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? ticketNumber = null,Object? customerId = null,Object? customerName = null,Object? phone = null,Object? address = freezed,Object? latitude = freezed,Object? longitude = freezed,Object? deviceType = freezed,Object? problemDescription = null,Object? notes = freezed,Object? status = null,Object? assignedTechnicianId = freezed,Object? createdAt = null,Object? assignedAt = freezed,Object? startedAt = freezed,Object? completedAt = freezed,Object? cancelledAt = freezed,Object? cancelledReason = freezed,}) {
  return _then(_MaintenanceRequest(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,ticketNumber: null == ticketNumber ? _self.ticketNumber : ticketNumber // ignore: cast_nullable_to_non_nullable
as int,customerId: null == customerId ? _self.customerId : customerId // ignore: cast_nullable_to_non_nullable
as String,customerName: null == customerName ? _self.customerName : customerName // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,latitude: freezed == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double?,longitude: freezed == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double?,deviceType: freezed == deviceType ? _self.deviceType : deviceType // ignore: cast_nullable_to_non_nullable
as String?,problemDescription: null == problemDescription ? _self.problemDescription : problemDescription // ignore: cast_nullable_to_non_nullable
as String,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as MaintenanceStatus,assignedTechnicianId: freezed == assignedTechnicianId ? _self.assignedTechnicianId : assignedTechnicianId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,assignedAt: freezed == assignedAt ? _self.assignedAt : assignedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,cancelledAt: freezed == cancelledAt ? _self.cancelledAt : cancelledAt // ignore: cast_nullable_to_non_nullable
as DateTime?,cancelledReason: freezed == cancelledReason ? _self.cancelledReason : cancelledReason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
