// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'employee_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Employee {

 String get id; String get fullName; String? get phone; String? get jobTitle; double get monthlySalary; DateTime? get hireDate; String? get notes; bool get isActive;/// Advances given minus advances already deducted from salaries — what
/// the employee still owes the shop.
 double get advanceBalance; DateTime? get lastPaidMonth;
/// Create a copy of Employee
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EmployeeCopyWith<Employee> get copyWith => _$EmployeeCopyWithImpl<Employee>(this as Employee, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Employee&&(identical(other.id, id) || other.id == id)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.jobTitle, jobTitle) || other.jobTitle == jobTitle)&&(identical(other.monthlySalary, monthlySalary) || other.monthlySalary == monthlySalary)&&(identical(other.hireDate, hireDate) || other.hireDate == hireDate)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.advanceBalance, advanceBalance) || other.advanceBalance == advanceBalance)&&(identical(other.lastPaidMonth, lastPaidMonth) || other.lastPaidMonth == lastPaidMonth));
}


@override
int get hashCode => Object.hash(runtimeType,id,fullName,phone,jobTitle,monthlySalary,hireDate,notes,isActive,advanceBalance,lastPaidMonth);

@override
String toString() {
  return 'Employee(id: $id, fullName: $fullName, phone: $phone, jobTitle: $jobTitle, monthlySalary: $monthlySalary, hireDate: $hireDate, notes: $notes, isActive: $isActive, advanceBalance: $advanceBalance, lastPaidMonth: $lastPaidMonth)';
}


}

/// @nodoc
abstract mixin class $EmployeeCopyWith<$Res>  {
  factory $EmployeeCopyWith(Employee value, $Res Function(Employee) _then) = _$EmployeeCopyWithImpl;
@useResult
$Res call({
 String id, String fullName, String? phone, String? jobTitle, double monthlySalary, DateTime? hireDate, String? notes, bool isActive, double advanceBalance, DateTime? lastPaidMonth
});




}
/// @nodoc
class _$EmployeeCopyWithImpl<$Res>
    implements $EmployeeCopyWith<$Res> {
  _$EmployeeCopyWithImpl(this._self, this._then);

  final Employee _self;
  final $Res Function(Employee) _then;

/// Create a copy of Employee
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? fullName = null,Object? phone = freezed,Object? jobTitle = freezed,Object? monthlySalary = null,Object? hireDate = freezed,Object? notes = freezed,Object? isActive = null,Object? advanceBalance = null,Object? lastPaidMonth = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,jobTitle: freezed == jobTitle ? _self.jobTitle : jobTitle // ignore: cast_nullable_to_non_nullable
as String?,monthlySalary: null == monthlySalary ? _self.monthlySalary : monthlySalary // ignore: cast_nullable_to_non_nullable
as double,hireDate: freezed == hireDate ? _self.hireDate : hireDate // ignore: cast_nullable_to_non_nullable
as DateTime?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,advanceBalance: null == advanceBalance ? _self.advanceBalance : advanceBalance // ignore: cast_nullable_to_non_nullable
as double,lastPaidMonth: freezed == lastPaidMonth ? _self.lastPaidMonth : lastPaidMonth // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Employee].
extension EmployeePatterns on Employee {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Employee value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Employee() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Employee value)  $default,){
final _that = this;
switch (_that) {
case _Employee():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Employee value)?  $default,){
final _that = this;
switch (_that) {
case _Employee() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String fullName,  String? phone,  String? jobTitle,  double monthlySalary,  DateTime? hireDate,  String? notes,  bool isActive,  double advanceBalance,  DateTime? lastPaidMonth)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Employee() when $default != null:
return $default(_that.id,_that.fullName,_that.phone,_that.jobTitle,_that.monthlySalary,_that.hireDate,_that.notes,_that.isActive,_that.advanceBalance,_that.lastPaidMonth);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String fullName,  String? phone,  String? jobTitle,  double monthlySalary,  DateTime? hireDate,  String? notes,  bool isActive,  double advanceBalance,  DateTime? lastPaidMonth)  $default,) {final _that = this;
switch (_that) {
case _Employee():
return $default(_that.id,_that.fullName,_that.phone,_that.jobTitle,_that.monthlySalary,_that.hireDate,_that.notes,_that.isActive,_that.advanceBalance,_that.lastPaidMonth);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String fullName,  String? phone,  String? jobTitle,  double monthlySalary,  DateTime? hireDate,  String? notes,  bool isActive,  double advanceBalance,  DateTime? lastPaidMonth)?  $default,) {final _that = this;
switch (_that) {
case _Employee() when $default != null:
return $default(_that.id,_that.fullName,_that.phone,_that.jobTitle,_that.monthlySalary,_that.hireDate,_that.notes,_that.isActive,_that.advanceBalance,_that.lastPaidMonth);case _:
  return null;

}
}

}

/// @nodoc


class _Employee implements Employee {
  const _Employee({required this.id, required this.fullName, this.phone, this.jobTitle, required this.monthlySalary, this.hireDate, this.notes, required this.isActive, this.advanceBalance = 0, this.lastPaidMonth});
  

@override final  String id;
@override final  String fullName;
@override final  String? phone;
@override final  String? jobTitle;
@override final  double monthlySalary;
@override final  DateTime? hireDate;
@override final  String? notes;
@override final  bool isActive;
/// Advances given minus advances already deducted from salaries — what
/// the employee still owes the shop.
@override@JsonKey() final  double advanceBalance;
@override final  DateTime? lastPaidMonth;

/// Create a copy of Employee
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EmployeeCopyWith<_Employee> get copyWith => __$EmployeeCopyWithImpl<_Employee>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Employee&&(identical(other.id, id) || other.id == id)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.jobTitle, jobTitle) || other.jobTitle == jobTitle)&&(identical(other.monthlySalary, monthlySalary) || other.monthlySalary == monthlySalary)&&(identical(other.hireDate, hireDate) || other.hireDate == hireDate)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.advanceBalance, advanceBalance) || other.advanceBalance == advanceBalance)&&(identical(other.lastPaidMonth, lastPaidMonth) || other.lastPaidMonth == lastPaidMonth));
}


@override
int get hashCode => Object.hash(runtimeType,id,fullName,phone,jobTitle,monthlySalary,hireDate,notes,isActive,advanceBalance,lastPaidMonth);

@override
String toString() {
  return 'Employee(id: $id, fullName: $fullName, phone: $phone, jobTitle: $jobTitle, monthlySalary: $monthlySalary, hireDate: $hireDate, notes: $notes, isActive: $isActive, advanceBalance: $advanceBalance, lastPaidMonth: $lastPaidMonth)';
}


}

/// @nodoc
abstract mixin class _$EmployeeCopyWith<$Res> implements $EmployeeCopyWith<$Res> {
  factory _$EmployeeCopyWith(_Employee value, $Res Function(_Employee) _then) = __$EmployeeCopyWithImpl;
@override @useResult
$Res call({
 String id, String fullName, String? phone, String? jobTitle, double monthlySalary, DateTime? hireDate, String? notes, bool isActive, double advanceBalance, DateTime? lastPaidMonth
});




}
/// @nodoc
class __$EmployeeCopyWithImpl<$Res>
    implements _$EmployeeCopyWith<$Res> {
  __$EmployeeCopyWithImpl(this._self, this._then);

  final _Employee _self;
  final $Res Function(_Employee) _then;

/// Create a copy of Employee
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? fullName = null,Object? phone = freezed,Object? jobTitle = freezed,Object? monthlySalary = null,Object? hireDate = freezed,Object? notes = freezed,Object? isActive = null,Object? advanceBalance = null,Object? lastPaidMonth = freezed,}) {
  return _then(_Employee(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,jobTitle: freezed == jobTitle ? _self.jobTitle : jobTitle // ignore: cast_nullable_to_non_nullable
as String?,monthlySalary: null == monthlySalary ? _self.monthlySalary : monthlySalary // ignore: cast_nullable_to_non_nullable
as double,hireDate: freezed == hireDate ? _self.hireDate : hireDate // ignore: cast_nullable_to_non_nullable
as DateTime?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,advanceBalance: null == advanceBalance ? _self.advanceBalance : advanceBalance // ignore: cast_nullable_to_non_nullable
as double,lastPaidMonth: freezed == lastPaidMonth ? _self.lastPaidMonth : lastPaidMonth // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

/// @nodoc
mixin _$AttendanceRecord {

 String get employeeId; DateTime get workDate; AttendanceStatus get status; String? get notes;
/// Create a copy of AttendanceRecord
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AttendanceRecordCopyWith<AttendanceRecord> get copyWith => _$AttendanceRecordCopyWithImpl<AttendanceRecord>(this as AttendanceRecord, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AttendanceRecord&&(identical(other.employeeId, employeeId) || other.employeeId == employeeId)&&(identical(other.workDate, workDate) || other.workDate == workDate)&&(identical(other.status, status) || other.status == status)&&(identical(other.notes, notes) || other.notes == notes));
}


@override
int get hashCode => Object.hash(runtimeType,employeeId,workDate,status,notes);

@override
String toString() {
  return 'AttendanceRecord(employeeId: $employeeId, workDate: $workDate, status: $status, notes: $notes)';
}


}

/// @nodoc
abstract mixin class $AttendanceRecordCopyWith<$Res>  {
  factory $AttendanceRecordCopyWith(AttendanceRecord value, $Res Function(AttendanceRecord) _then) = _$AttendanceRecordCopyWithImpl;
@useResult
$Res call({
 String employeeId, DateTime workDate, AttendanceStatus status, String? notes
});




}
/// @nodoc
class _$AttendanceRecordCopyWithImpl<$Res>
    implements $AttendanceRecordCopyWith<$Res> {
  _$AttendanceRecordCopyWithImpl(this._self, this._then);

  final AttendanceRecord _self;
  final $Res Function(AttendanceRecord) _then;

/// Create a copy of AttendanceRecord
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? employeeId = null,Object? workDate = null,Object? status = null,Object? notes = freezed,}) {
  return _then(_self.copyWith(
employeeId: null == employeeId ? _self.employeeId : employeeId // ignore: cast_nullable_to_non_nullable
as String,workDate: null == workDate ? _self.workDate : workDate // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as AttendanceStatus,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AttendanceRecord].
extension AttendanceRecordPatterns on AttendanceRecord {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AttendanceRecord value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AttendanceRecord() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AttendanceRecord value)  $default,){
final _that = this;
switch (_that) {
case _AttendanceRecord():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AttendanceRecord value)?  $default,){
final _that = this;
switch (_that) {
case _AttendanceRecord() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String employeeId,  DateTime workDate,  AttendanceStatus status,  String? notes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AttendanceRecord() when $default != null:
return $default(_that.employeeId,_that.workDate,_that.status,_that.notes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String employeeId,  DateTime workDate,  AttendanceStatus status,  String? notes)  $default,) {final _that = this;
switch (_that) {
case _AttendanceRecord():
return $default(_that.employeeId,_that.workDate,_that.status,_that.notes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String employeeId,  DateTime workDate,  AttendanceStatus status,  String? notes)?  $default,) {final _that = this;
switch (_that) {
case _AttendanceRecord() when $default != null:
return $default(_that.employeeId,_that.workDate,_that.status,_that.notes);case _:
  return null;

}
}

}

/// @nodoc


class _AttendanceRecord implements AttendanceRecord {
  const _AttendanceRecord({required this.employeeId, required this.workDate, required this.status, this.notes});
  

@override final  String employeeId;
@override final  DateTime workDate;
@override final  AttendanceStatus status;
@override final  String? notes;

/// Create a copy of AttendanceRecord
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AttendanceRecordCopyWith<_AttendanceRecord> get copyWith => __$AttendanceRecordCopyWithImpl<_AttendanceRecord>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AttendanceRecord&&(identical(other.employeeId, employeeId) || other.employeeId == employeeId)&&(identical(other.workDate, workDate) || other.workDate == workDate)&&(identical(other.status, status) || other.status == status)&&(identical(other.notes, notes) || other.notes == notes));
}


@override
int get hashCode => Object.hash(runtimeType,employeeId,workDate,status,notes);

@override
String toString() {
  return 'AttendanceRecord(employeeId: $employeeId, workDate: $workDate, status: $status, notes: $notes)';
}


}

/// @nodoc
abstract mixin class _$AttendanceRecordCopyWith<$Res> implements $AttendanceRecordCopyWith<$Res> {
  factory _$AttendanceRecordCopyWith(_AttendanceRecord value, $Res Function(_AttendanceRecord) _then) = __$AttendanceRecordCopyWithImpl;
@override @useResult
$Res call({
 String employeeId, DateTime workDate, AttendanceStatus status, String? notes
});




}
/// @nodoc
class __$AttendanceRecordCopyWithImpl<$Res>
    implements _$AttendanceRecordCopyWith<$Res> {
  __$AttendanceRecordCopyWithImpl(this._self, this._then);

  final _AttendanceRecord _self;
  final $Res Function(_AttendanceRecord) _then;

/// Create a copy of AttendanceRecord
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? employeeId = null,Object? workDate = null,Object? status = null,Object? notes = freezed,}) {
  return _then(_AttendanceRecord(
employeeId: null == employeeId ? _self.employeeId : employeeId // ignore: cast_nullable_to_non_nullable
as String,workDate: null == workDate ? _self.workDate : workDate // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as AttendanceStatus,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$EmployeeAdvance {

 String get id; int get advanceNumber; double get amount; DateTime get advanceDate; CashboxKind get kind; String? get notes;
/// Create a copy of EmployeeAdvance
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EmployeeAdvanceCopyWith<EmployeeAdvance> get copyWith => _$EmployeeAdvanceCopyWithImpl<EmployeeAdvance>(this as EmployeeAdvance, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EmployeeAdvance&&(identical(other.id, id) || other.id == id)&&(identical(other.advanceNumber, advanceNumber) || other.advanceNumber == advanceNumber)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.advanceDate, advanceDate) || other.advanceDate == advanceDate)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.notes, notes) || other.notes == notes));
}


@override
int get hashCode => Object.hash(runtimeType,id,advanceNumber,amount,advanceDate,kind,notes);

@override
String toString() {
  return 'EmployeeAdvance(id: $id, advanceNumber: $advanceNumber, amount: $amount, advanceDate: $advanceDate, kind: $kind, notes: $notes)';
}


}

/// @nodoc
abstract mixin class $EmployeeAdvanceCopyWith<$Res>  {
  factory $EmployeeAdvanceCopyWith(EmployeeAdvance value, $Res Function(EmployeeAdvance) _then) = _$EmployeeAdvanceCopyWithImpl;
@useResult
$Res call({
 String id, int advanceNumber, double amount, DateTime advanceDate, CashboxKind kind, String? notes
});




}
/// @nodoc
class _$EmployeeAdvanceCopyWithImpl<$Res>
    implements $EmployeeAdvanceCopyWith<$Res> {
  _$EmployeeAdvanceCopyWithImpl(this._self, this._then);

  final EmployeeAdvance _self;
  final $Res Function(EmployeeAdvance) _then;

/// Create a copy of EmployeeAdvance
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? advanceNumber = null,Object? amount = null,Object? advanceDate = null,Object? kind = null,Object? notes = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,advanceNumber: null == advanceNumber ? _self.advanceNumber : advanceNumber // ignore: cast_nullable_to_non_nullable
as int,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,advanceDate: null == advanceDate ? _self.advanceDate : advanceDate // ignore: cast_nullable_to_non_nullable
as DateTime,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as CashboxKind,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [EmployeeAdvance].
extension EmployeeAdvancePatterns on EmployeeAdvance {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EmployeeAdvance value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EmployeeAdvance() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EmployeeAdvance value)  $default,){
final _that = this;
switch (_that) {
case _EmployeeAdvance():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EmployeeAdvance value)?  $default,){
final _that = this;
switch (_that) {
case _EmployeeAdvance() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  int advanceNumber,  double amount,  DateTime advanceDate,  CashboxKind kind,  String? notes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EmployeeAdvance() when $default != null:
return $default(_that.id,_that.advanceNumber,_that.amount,_that.advanceDate,_that.kind,_that.notes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  int advanceNumber,  double amount,  DateTime advanceDate,  CashboxKind kind,  String? notes)  $default,) {final _that = this;
switch (_that) {
case _EmployeeAdvance():
return $default(_that.id,_that.advanceNumber,_that.amount,_that.advanceDate,_that.kind,_that.notes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  int advanceNumber,  double amount,  DateTime advanceDate,  CashboxKind kind,  String? notes)?  $default,) {final _that = this;
switch (_that) {
case _EmployeeAdvance() when $default != null:
return $default(_that.id,_that.advanceNumber,_that.amount,_that.advanceDate,_that.kind,_that.notes);case _:
  return null;

}
}

}

/// @nodoc


class _EmployeeAdvance implements EmployeeAdvance {
  const _EmployeeAdvance({required this.id, required this.advanceNumber, required this.amount, required this.advanceDate, required this.kind, this.notes});
  

@override final  String id;
@override final  int advanceNumber;
@override final  double amount;
@override final  DateTime advanceDate;
@override final  CashboxKind kind;
@override final  String? notes;

/// Create a copy of EmployeeAdvance
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EmployeeAdvanceCopyWith<_EmployeeAdvance> get copyWith => __$EmployeeAdvanceCopyWithImpl<_EmployeeAdvance>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EmployeeAdvance&&(identical(other.id, id) || other.id == id)&&(identical(other.advanceNumber, advanceNumber) || other.advanceNumber == advanceNumber)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.advanceDate, advanceDate) || other.advanceDate == advanceDate)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.notes, notes) || other.notes == notes));
}


@override
int get hashCode => Object.hash(runtimeType,id,advanceNumber,amount,advanceDate,kind,notes);

@override
String toString() {
  return 'EmployeeAdvance(id: $id, advanceNumber: $advanceNumber, amount: $amount, advanceDate: $advanceDate, kind: $kind, notes: $notes)';
}


}

/// @nodoc
abstract mixin class _$EmployeeAdvanceCopyWith<$Res> implements $EmployeeAdvanceCopyWith<$Res> {
  factory _$EmployeeAdvanceCopyWith(_EmployeeAdvance value, $Res Function(_EmployeeAdvance) _then) = __$EmployeeAdvanceCopyWithImpl;
@override @useResult
$Res call({
 String id, int advanceNumber, double amount, DateTime advanceDate, CashboxKind kind, String? notes
});




}
/// @nodoc
class __$EmployeeAdvanceCopyWithImpl<$Res>
    implements _$EmployeeAdvanceCopyWith<$Res> {
  __$EmployeeAdvanceCopyWithImpl(this._self, this._then);

  final _EmployeeAdvance _self;
  final $Res Function(_EmployeeAdvance) _then;

/// Create a copy of EmployeeAdvance
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? advanceNumber = null,Object? amount = null,Object? advanceDate = null,Object? kind = null,Object? notes = freezed,}) {
  return _then(_EmployeeAdvance(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,advanceNumber: null == advanceNumber ? _self.advanceNumber : advanceNumber // ignore: cast_nullable_to_non_nullable
as int,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,advanceDate: null == advanceDate ? _self.advanceDate : advanceDate // ignore: cast_nullable_to_non_nullable
as DateTime,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as CashboxKind,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$EmployeePayroll {

 String get id; int get payrollNumber; DateTime get periodMonth; double get baseSalary; int get absentDays; double get absenceDeduction; double get bonus; double get advanceDeduction; double get netAmount; CashboxKind get kind; String? get notes; DateTime get createdAt;
/// Create a copy of EmployeePayroll
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EmployeePayrollCopyWith<EmployeePayroll> get copyWith => _$EmployeePayrollCopyWithImpl<EmployeePayroll>(this as EmployeePayroll, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EmployeePayroll&&(identical(other.id, id) || other.id == id)&&(identical(other.payrollNumber, payrollNumber) || other.payrollNumber == payrollNumber)&&(identical(other.periodMonth, periodMonth) || other.periodMonth == periodMonth)&&(identical(other.baseSalary, baseSalary) || other.baseSalary == baseSalary)&&(identical(other.absentDays, absentDays) || other.absentDays == absentDays)&&(identical(other.absenceDeduction, absenceDeduction) || other.absenceDeduction == absenceDeduction)&&(identical(other.bonus, bonus) || other.bonus == bonus)&&(identical(other.advanceDeduction, advanceDeduction) || other.advanceDeduction == advanceDeduction)&&(identical(other.netAmount, netAmount) || other.netAmount == netAmount)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,payrollNumber,periodMonth,baseSalary,absentDays,absenceDeduction,bonus,advanceDeduction,netAmount,kind,notes,createdAt);

@override
String toString() {
  return 'EmployeePayroll(id: $id, payrollNumber: $payrollNumber, periodMonth: $periodMonth, baseSalary: $baseSalary, absentDays: $absentDays, absenceDeduction: $absenceDeduction, bonus: $bonus, advanceDeduction: $advanceDeduction, netAmount: $netAmount, kind: $kind, notes: $notes, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $EmployeePayrollCopyWith<$Res>  {
  factory $EmployeePayrollCopyWith(EmployeePayroll value, $Res Function(EmployeePayroll) _then) = _$EmployeePayrollCopyWithImpl;
@useResult
$Res call({
 String id, int payrollNumber, DateTime periodMonth, double baseSalary, int absentDays, double absenceDeduction, double bonus, double advanceDeduction, double netAmount, CashboxKind kind, String? notes, DateTime createdAt
});




}
/// @nodoc
class _$EmployeePayrollCopyWithImpl<$Res>
    implements $EmployeePayrollCopyWith<$Res> {
  _$EmployeePayrollCopyWithImpl(this._self, this._then);

  final EmployeePayroll _self;
  final $Res Function(EmployeePayroll) _then;

/// Create a copy of EmployeePayroll
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? payrollNumber = null,Object? periodMonth = null,Object? baseSalary = null,Object? absentDays = null,Object? absenceDeduction = null,Object? bonus = null,Object? advanceDeduction = null,Object? netAmount = null,Object? kind = null,Object? notes = freezed,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,payrollNumber: null == payrollNumber ? _self.payrollNumber : payrollNumber // ignore: cast_nullable_to_non_nullable
as int,periodMonth: null == periodMonth ? _self.periodMonth : periodMonth // ignore: cast_nullable_to_non_nullable
as DateTime,baseSalary: null == baseSalary ? _self.baseSalary : baseSalary // ignore: cast_nullable_to_non_nullable
as double,absentDays: null == absentDays ? _self.absentDays : absentDays // ignore: cast_nullable_to_non_nullable
as int,absenceDeduction: null == absenceDeduction ? _self.absenceDeduction : absenceDeduction // ignore: cast_nullable_to_non_nullable
as double,bonus: null == bonus ? _self.bonus : bonus // ignore: cast_nullable_to_non_nullable
as double,advanceDeduction: null == advanceDeduction ? _self.advanceDeduction : advanceDeduction // ignore: cast_nullable_to_non_nullable
as double,netAmount: null == netAmount ? _self.netAmount : netAmount // ignore: cast_nullable_to_non_nullable
as double,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as CashboxKind,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [EmployeePayroll].
extension EmployeePayrollPatterns on EmployeePayroll {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EmployeePayroll value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EmployeePayroll() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EmployeePayroll value)  $default,){
final _that = this;
switch (_that) {
case _EmployeePayroll():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EmployeePayroll value)?  $default,){
final _that = this;
switch (_that) {
case _EmployeePayroll() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  int payrollNumber,  DateTime periodMonth,  double baseSalary,  int absentDays,  double absenceDeduction,  double bonus,  double advanceDeduction,  double netAmount,  CashboxKind kind,  String? notes,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EmployeePayroll() when $default != null:
return $default(_that.id,_that.payrollNumber,_that.periodMonth,_that.baseSalary,_that.absentDays,_that.absenceDeduction,_that.bonus,_that.advanceDeduction,_that.netAmount,_that.kind,_that.notes,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  int payrollNumber,  DateTime periodMonth,  double baseSalary,  int absentDays,  double absenceDeduction,  double bonus,  double advanceDeduction,  double netAmount,  CashboxKind kind,  String? notes,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _EmployeePayroll():
return $default(_that.id,_that.payrollNumber,_that.periodMonth,_that.baseSalary,_that.absentDays,_that.absenceDeduction,_that.bonus,_that.advanceDeduction,_that.netAmount,_that.kind,_that.notes,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  int payrollNumber,  DateTime periodMonth,  double baseSalary,  int absentDays,  double absenceDeduction,  double bonus,  double advanceDeduction,  double netAmount,  CashboxKind kind,  String? notes,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _EmployeePayroll() when $default != null:
return $default(_that.id,_that.payrollNumber,_that.periodMonth,_that.baseSalary,_that.absentDays,_that.absenceDeduction,_that.bonus,_that.advanceDeduction,_that.netAmount,_that.kind,_that.notes,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc


class _EmployeePayroll extends EmployeePayroll {
  const _EmployeePayroll({required this.id, required this.payrollNumber, required this.periodMonth, required this.baseSalary, required this.absentDays, required this.absenceDeduction, required this.bonus, required this.advanceDeduction, required this.netAmount, required this.kind, this.notes, required this.createdAt}): super._();
  

@override final  String id;
@override final  int payrollNumber;
@override final  DateTime periodMonth;
@override final  double baseSalary;
@override final  int absentDays;
@override final  double absenceDeduction;
@override final  double bonus;
@override final  double advanceDeduction;
@override final  double netAmount;
@override final  CashboxKind kind;
@override final  String? notes;
@override final  DateTime createdAt;

/// Create a copy of EmployeePayroll
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EmployeePayrollCopyWith<_EmployeePayroll> get copyWith => __$EmployeePayrollCopyWithImpl<_EmployeePayroll>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EmployeePayroll&&(identical(other.id, id) || other.id == id)&&(identical(other.payrollNumber, payrollNumber) || other.payrollNumber == payrollNumber)&&(identical(other.periodMonth, periodMonth) || other.periodMonth == periodMonth)&&(identical(other.baseSalary, baseSalary) || other.baseSalary == baseSalary)&&(identical(other.absentDays, absentDays) || other.absentDays == absentDays)&&(identical(other.absenceDeduction, absenceDeduction) || other.absenceDeduction == absenceDeduction)&&(identical(other.bonus, bonus) || other.bonus == bonus)&&(identical(other.advanceDeduction, advanceDeduction) || other.advanceDeduction == advanceDeduction)&&(identical(other.netAmount, netAmount) || other.netAmount == netAmount)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,payrollNumber,periodMonth,baseSalary,absentDays,absenceDeduction,bonus,advanceDeduction,netAmount,kind,notes,createdAt);

@override
String toString() {
  return 'EmployeePayroll(id: $id, payrollNumber: $payrollNumber, periodMonth: $periodMonth, baseSalary: $baseSalary, absentDays: $absentDays, absenceDeduction: $absenceDeduction, bonus: $bonus, advanceDeduction: $advanceDeduction, netAmount: $netAmount, kind: $kind, notes: $notes, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$EmployeePayrollCopyWith<$Res> implements $EmployeePayrollCopyWith<$Res> {
  factory _$EmployeePayrollCopyWith(_EmployeePayroll value, $Res Function(_EmployeePayroll) _then) = __$EmployeePayrollCopyWithImpl;
@override @useResult
$Res call({
 String id, int payrollNumber, DateTime periodMonth, double baseSalary, int absentDays, double absenceDeduction, double bonus, double advanceDeduction, double netAmount, CashboxKind kind, String? notes, DateTime createdAt
});




}
/// @nodoc
class __$EmployeePayrollCopyWithImpl<$Res>
    implements _$EmployeePayrollCopyWith<$Res> {
  __$EmployeePayrollCopyWithImpl(this._self, this._then);

  final _EmployeePayroll _self;
  final $Res Function(_EmployeePayroll) _then;

/// Create a copy of EmployeePayroll
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? payrollNumber = null,Object? periodMonth = null,Object? baseSalary = null,Object? absentDays = null,Object? absenceDeduction = null,Object? bonus = null,Object? advanceDeduction = null,Object? netAmount = null,Object? kind = null,Object? notes = freezed,Object? createdAt = null,}) {
  return _then(_EmployeePayroll(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,payrollNumber: null == payrollNumber ? _self.payrollNumber : payrollNumber // ignore: cast_nullable_to_non_nullable
as int,periodMonth: null == periodMonth ? _self.periodMonth : periodMonth // ignore: cast_nullable_to_non_nullable
as DateTime,baseSalary: null == baseSalary ? _self.baseSalary : baseSalary // ignore: cast_nullable_to_non_nullable
as double,absentDays: null == absentDays ? _self.absentDays : absentDays // ignore: cast_nullable_to_non_nullable
as int,absenceDeduction: null == absenceDeduction ? _self.absenceDeduction : absenceDeduction // ignore: cast_nullable_to_non_nullable
as double,bonus: null == bonus ? _self.bonus : bonus // ignore: cast_nullable_to_non_nullable
as double,advanceDeduction: null == advanceDeduction ? _self.advanceDeduction : advanceDeduction // ignore: cast_nullable_to_non_nullable
as double,netAmount: null == netAmount ? _self.netAmount : netAmount // ignore: cast_nullable_to_non_nullable
as double,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as CashboxKind,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

/// @nodoc
mixin _$PayrollPreview {

 DateTime get periodMonth; double get baseSalary; int get presentDays; int get absentDays; int get lateDays; int get leaveDays; double get dailyRate; double get absenceDeduction; double get advanceBalance; bool get alreadyPaid;
/// Create a copy of PayrollPreview
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PayrollPreviewCopyWith<PayrollPreview> get copyWith => _$PayrollPreviewCopyWithImpl<PayrollPreview>(this as PayrollPreview, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PayrollPreview&&(identical(other.periodMonth, periodMonth) || other.periodMonth == periodMonth)&&(identical(other.baseSalary, baseSalary) || other.baseSalary == baseSalary)&&(identical(other.presentDays, presentDays) || other.presentDays == presentDays)&&(identical(other.absentDays, absentDays) || other.absentDays == absentDays)&&(identical(other.lateDays, lateDays) || other.lateDays == lateDays)&&(identical(other.leaveDays, leaveDays) || other.leaveDays == leaveDays)&&(identical(other.dailyRate, dailyRate) || other.dailyRate == dailyRate)&&(identical(other.absenceDeduction, absenceDeduction) || other.absenceDeduction == absenceDeduction)&&(identical(other.advanceBalance, advanceBalance) || other.advanceBalance == advanceBalance)&&(identical(other.alreadyPaid, alreadyPaid) || other.alreadyPaid == alreadyPaid));
}


@override
int get hashCode => Object.hash(runtimeType,periodMonth,baseSalary,presentDays,absentDays,lateDays,leaveDays,dailyRate,absenceDeduction,advanceBalance,alreadyPaid);

@override
String toString() {
  return 'PayrollPreview(periodMonth: $periodMonth, baseSalary: $baseSalary, presentDays: $presentDays, absentDays: $absentDays, lateDays: $lateDays, leaveDays: $leaveDays, dailyRate: $dailyRate, absenceDeduction: $absenceDeduction, advanceBalance: $advanceBalance, alreadyPaid: $alreadyPaid)';
}


}

/// @nodoc
abstract mixin class $PayrollPreviewCopyWith<$Res>  {
  factory $PayrollPreviewCopyWith(PayrollPreview value, $Res Function(PayrollPreview) _then) = _$PayrollPreviewCopyWithImpl;
@useResult
$Res call({
 DateTime periodMonth, double baseSalary, int presentDays, int absentDays, int lateDays, int leaveDays, double dailyRate, double absenceDeduction, double advanceBalance, bool alreadyPaid
});




}
/// @nodoc
class _$PayrollPreviewCopyWithImpl<$Res>
    implements $PayrollPreviewCopyWith<$Res> {
  _$PayrollPreviewCopyWithImpl(this._self, this._then);

  final PayrollPreview _self;
  final $Res Function(PayrollPreview) _then;

/// Create a copy of PayrollPreview
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? periodMonth = null,Object? baseSalary = null,Object? presentDays = null,Object? absentDays = null,Object? lateDays = null,Object? leaveDays = null,Object? dailyRate = null,Object? absenceDeduction = null,Object? advanceBalance = null,Object? alreadyPaid = null,}) {
  return _then(_self.copyWith(
periodMonth: null == periodMonth ? _self.periodMonth : periodMonth // ignore: cast_nullable_to_non_nullable
as DateTime,baseSalary: null == baseSalary ? _self.baseSalary : baseSalary // ignore: cast_nullable_to_non_nullable
as double,presentDays: null == presentDays ? _self.presentDays : presentDays // ignore: cast_nullable_to_non_nullable
as int,absentDays: null == absentDays ? _self.absentDays : absentDays // ignore: cast_nullable_to_non_nullable
as int,lateDays: null == lateDays ? _self.lateDays : lateDays // ignore: cast_nullable_to_non_nullable
as int,leaveDays: null == leaveDays ? _self.leaveDays : leaveDays // ignore: cast_nullable_to_non_nullable
as int,dailyRate: null == dailyRate ? _self.dailyRate : dailyRate // ignore: cast_nullable_to_non_nullable
as double,absenceDeduction: null == absenceDeduction ? _self.absenceDeduction : absenceDeduction // ignore: cast_nullable_to_non_nullable
as double,advanceBalance: null == advanceBalance ? _self.advanceBalance : advanceBalance // ignore: cast_nullable_to_non_nullable
as double,alreadyPaid: null == alreadyPaid ? _self.alreadyPaid : alreadyPaid // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [PayrollPreview].
extension PayrollPreviewPatterns on PayrollPreview {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PayrollPreview value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PayrollPreview() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PayrollPreview value)  $default,){
final _that = this;
switch (_that) {
case _PayrollPreview():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PayrollPreview value)?  $default,){
final _that = this;
switch (_that) {
case _PayrollPreview() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime periodMonth,  double baseSalary,  int presentDays,  int absentDays,  int lateDays,  int leaveDays,  double dailyRate,  double absenceDeduction,  double advanceBalance,  bool alreadyPaid)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PayrollPreview() when $default != null:
return $default(_that.periodMonth,_that.baseSalary,_that.presentDays,_that.absentDays,_that.lateDays,_that.leaveDays,_that.dailyRate,_that.absenceDeduction,_that.advanceBalance,_that.alreadyPaid);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime periodMonth,  double baseSalary,  int presentDays,  int absentDays,  int lateDays,  int leaveDays,  double dailyRate,  double absenceDeduction,  double advanceBalance,  bool alreadyPaid)  $default,) {final _that = this;
switch (_that) {
case _PayrollPreview():
return $default(_that.periodMonth,_that.baseSalary,_that.presentDays,_that.absentDays,_that.lateDays,_that.leaveDays,_that.dailyRate,_that.absenceDeduction,_that.advanceBalance,_that.alreadyPaid);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime periodMonth,  double baseSalary,  int presentDays,  int absentDays,  int lateDays,  int leaveDays,  double dailyRate,  double absenceDeduction,  double advanceBalance,  bool alreadyPaid)?  $default,) {final _that = this;
switch (_that) {
case _PayrollPreview() when $default != null:
return $default(_that.periodMonth,_that.baseSalary,_that.presentDays,_that.absentDays,_that.lateDays,_that.leaveDays,_that.dailyRate,_that.absenceDeduction,_that.advanceBalance,_that.alreadyPaid);case _:
  return null;

}
}

}

/// @nodoc


class _PayrollPreview implements PayrollPreview {
  const _PayrollPreview({required this.periodMonth, required this.baseSalary, required this.presentDays, required this.absentDays, required this.lateDays, required this.leaveDays, required this.dailyRate, required this.absenceDeduction, required this.advanceBalance, required this.alreadyPaid});
  

@override final  DateTime periodMonth;
@override final  double baseSalary;
@override final  int presentDays;
@override final  int absentDays;
@override final  int lateDays;
@override final  int leaveDays;
@override final  double dailyRate;
@override final  double absenceDeduction;
@override final  double advanceBalance;
@override final  bool alreadyPaid;

/// Create a copy of PayrollPreview
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PayrollPreviewCopyWith<_PayrollPreview> get copyWith => __$PayrollPreviewCopyWithImpl<_PayrollPreview>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PayrollPreview&&(identical(other.periodMonth, periodMonth) || other.periodMonth == periodMonth)&&(identical(other.baseSalary, baseSalary) || other.baseSalary == baseSalary)&&(identical(other.presentDays, presentDays) || other.presentDays == presentDays)&&(identical(other.absentDays, absentDays) || other.absentDays == absentDays)&&(identical(other.lateDays, lateDays) || other.lateDays == lateDays)&&(identical(other.leaveDays, leaveDays) || other.leaveDays == leaveDays)&&(identical(other.dailyRate, dailyRate) || other.dailyRate == dailyRate)&&(identical(other.absenceDeduction, absenceDeduction) || other.absenceDeduction == absenceDeduction)&&(identical(other.advanceBalance, advanceBalance) || other.advanceBalance == advanceBalance)&&(identical(other.alreadyPaid, alreadyPaid) || other.alreadyPaid == alreadyPaid));
}


@override
int get hashCode => Object.hash(runtimeType,periodMonth,baseSalary,presentDays,absentDays,lateDays,leaveDays,dailyRate,absenceDeduction,advanceBalance,alreadyPaid);

@override
String toString() {
  return 'PayrollPreview(periodMonth: $periodMonth, baseSalary: $baseSalary, presentDays: $presentDays, absentDays: $absentDays, lateDays: $lateDays, leaveDays: $leaveDays, dailyRate: $dailyRate, absenceDeduction: $absenceDeduction, advanceBalance: $advanceBalance, alreadyPaid: $alreadyPaid)';
}


}

/// @nodoc
abstract mixin class _$PayrollPreviewCopyWith<$Res> implements $PayrollPreviewCopyWith<$Res> {
  factory _$PayrollPreviewCopyWith(_PayrollPreview value, $Res Function(_PayrollPreview) _then) = __$PayrollPreviewCopyWithImpl;
@override @useResult
$Res call({
 DateTime periodMonth, double baseSalary, int presentDays, int absentDays, int lateDays, int leaveDays, double dailyRate, double absenceDeduction, double advanceBalance, bool alreadyPaid
});




}
/// @nodoc
class __$PayrollPreviewCopyWithImpl<$Res>
    implements _$PayrollPreviewCopyWith<$Res> {
  __$PayrollPreviewCopyWithImpl(this._self, this._then);

  final _PayrollPreview _self;
  final $Res Function(_PayrollPreview) _then;

/// Create a copy of PayrollPreview
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? periodMonth = null,Object? baseSalary = null,Object? presentDays = null,Object? absentDays = null,Object? lateDays = null,Object? leaveDays = null,Object? dailyRate = null,Object? absenceDeduction = null,Object? advanceBalance = null,Object? alreadyPaid = null,}) {
  return _then(_PayrollPreview(
periodMonth: null == periodMonth ? _self.periodMonth : periodMonth // ignore: cast_nullable_to_non_nullable
as DateTime,baseSalary: null == baseSalary ? _self.baseSalary : baseSalary // ignore: cast_nullable_to_non_nullable
as double,presentDays: null == presentDays ? _self.presentDays : presentDays // ignore: cast_nullable_to_non_nullable
as int,absentDays: null == absentDays ? _self.absentDays : absentDays // ignore: cast_nullable_to_non_nullable
as int,lateDays: null == lateDays ? _self.lateDays : lateDays // ignore: cast_nullable_to_non_nullable
as int,leaveDays: null == leaveDays ? _self.leaveDays : leaveDays // ignore: cast_nullable_to_non_nullable
as int,dailyRate: null == dailyRate ? _self.dailyRate : dailyRate // ignore: cast_nullable_to_non_nullable
as double,absenceDeduction: null == absenceDeduction ? _self.absenceDeduction : absenceDeduction // ignore: cast_nullable_to_non_nullable
as double,advanceBalance: null == advanceBalance ? _self.advanceBalance : advanceBalance // ignore: cast_nullable_to_non_nullable
as double,alreadyPaid: null == alreadyPaid ? _self.alreadyPaid : alreadyPaid // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
