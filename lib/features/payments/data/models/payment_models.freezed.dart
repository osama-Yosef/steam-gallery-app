// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'payment_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PaymentRecord {

 String get id; String get customerId; String? get orderId; PaymentChannel get channel; String? get provider; double get amount; String get currency; PaymentTxnStatus get status; String? get providerReference; Map<String, dynamic> get metadata; DateTime get createdAt; DateTime? get paidAt;
/// Create a copy of PaymentRecord
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PaymentRecordCopyWith<PaymentRecord> get copyWith => _$PaymentRecordCopyWithImpl<PaymentRecord>(this as PaymentRecord, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PaymentRecord&&(identical(other.id, id) || other.id == id)&&(identical(other.customerId, customerId) || other.customerId == customerId)&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.channel, channel) || other.channel == channel)&&(identical(other.provider, provider) || other.provider == provider)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.status, status) || other.status == status)&&(identical(other.providerReference, providerReference) || other.providerReference == providerReference)&&const DeepCollectionEquality().equals(other.metadata, metadata)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.paidAt, paidAt) || other.paidAt == paidAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,customerId,orderId,channel,provider,amount,currency,status,providerReference,const DeepCollectionEquality().hash(metadata),createdAt,paidAt);

@override
String toString() {
  return 'PaymentRecord(id: $id, customerId: $customerId, orderId: $orderId, channel: $channel, provider: $provider, amount: $amount, currency: $currency, status: $status, providerReference: $providerReference, metadata: $metadata, createdAt: $createdAt, paidAt: $paidAt)';
}


}

/// @nodoc
abstract mixin class $PaymentRecordCopyWith<$Res>  {
  factory $PaymentRecordCopyWith(PaymentRecord value, $Res Function(PaymentRecord) _then) = _$PaymentRecordCopyWithImpl;
@useResult
$Res call({
 String id, String customerId, String? orderId, PaymentChannel channel, String? provider, double amount, String currency, PaymentTxnStatus status, String? providerReference, Map<String, dynamic> metadata, DateTime createdAt, DateTime? paidAt
});




}
/// @nodoc
class _$PaymentRecordCopyWithImpl<$Res>
    implements $PaymentRecordCopyWith<$Res> {
  _$PaymentRecordCopyWithImpl(this._self, this._then);

  final PaymentRecord _self;
  final $Res Function(PaymentRecord) _then;

/// Create a copy of PaymentRecord
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? customerId = null,Object? orderId = freezed,Object? channel = null,Object? provider = freezed,Object? amount = null,Object? currency = null,Object? status = null,Object? providerReference = freezed,Object? metadata = null,Object? createdAt = null,Object? paidAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,customerId: null == customerId ? _self.customerId : customerId // ignore: cast_nullable_to_non_nullable
as String,orderId: freezed == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as String?,channel: null == channel ? _self.channel : channel // ignore: cast_nullable_to_non_nullable
as PaymentChannel,provider: freezed == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as String?,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as PaymentTxnStatus,providerReference: freezed == providerReference ? _self.providerReference : providerReference // ignore: cast_nullable_to_non_nullable
as String?,metadata: null == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,paidAt: freezed == paidAt ? _self.paidAt : paidAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [PaymentRecord].
extension PaymentRecordPatterns on PaymentRecord {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PaymentRecord value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PaymentRecord() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PaymentRecord value)  $default,){
final _that = this;
switch (_that) {
case _PaymentRecord():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PaymentRecord value)?  $default,){
final _that = this;
switch (_that) {
case _PaymentRecord() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String customerId,  String? orderId,  PaymentChannel channel,  String? provider,  double amount,  String currency,  PaymentTxnStatus status,  String? providerReference,  Map<String, dynamic> metadata,  DateTime createdAt,  DateTime? paidAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PaymentRecord() when $default != null:
return $default(_that.id,_that.customerId,_that.orderId,_that.channel,_that.provider,_that.amount,_that.currency,_that.status,_that.providerReference,_that.metadata,_that.createdAt,_that.paidAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String customerId,  String? orderId,  PaymentChannel channel,  String? provider,  double amount,  String currency,  PaymentTxnStatus status,  String? providerReference,  Map<String, dynamic> metadata,  DateTime createdAt,  DateTime? paidAt)  $default,) {final _that = this;
switch (_that) {
case _PaymentRecord():
return $default(_that.id,_that.customerId,_that.orderId,_that.channel,_that.provider,_that.amount,_that.currency,_that.status,_that.providerReference,_that.metadata,_that.createdAt,_that.paidAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String customerId,  String? orderId,  PaymentChannel channel,  String? provider,  double amount,  String currency,  PaymentTxnStatus status,  String? providerReference,  Map<String, dynamic> metadata,  DateTime createdAt,  DateTime? paidAt)?  $default,) {final _that = this;
switch (_that) {
case _PaymentRecord() when $default != null:
return $default(_that.id,_that.customerId,_that.orderId,_that.channel,_that.provider,_that.amount,_that.currency,_that.status,_that.providerReference,_that.metadata,_that.createdAt,_that.paidAt);case _:
  return null;

}
}

}

/// @nodoc


class _PaymentRecord extends PaymentRecord {
  const _PaymentRecord({required this.id, required this.customerId, this.orderId, required this.channel, this.provider, required this.amount, required this.currency, required this.status, this.providerReference, required final  Map<String, dynamic> metadata, required this.createdAt, this.paidAt}): _metadata = metadata,super._();
  

@override final  String id;
@override final  String customerId;
@override final  String? orderId;
@override final  PaymentChannel channel;
@override final  String? provider;
@override final  double amount;
@override final  String currency;
@override final  PaymentTxnStatus status;
@override final  String? providerReference;
 final  Map<String, dynamic> _metadata;
@override Map<String, dynamic> get metadata {
  if (_metadata is EqualUnmodifiableMapView) return _metadata;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_metadata);
}

@override final  DateTime createdAt;
@override final  DateTime? paidAt;

/// Create a copy of PaymentRecord
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PaymentRecordCopyWith<_PaymentRecord> get copyWith => __$PaymentRecordCopyWithImpl<_PaymentRecord>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PaymentRecord&&(identical(other.id, id) || other.id == id)&&(identical(other.customerId, customerId) || other.customerId == customerId)&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.channel, channel) || other.channel == channel)&&(identical(other.provider, provider) || other.provider == provider)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.status, status) || other.status == status)&&(identical(other.providerReference, providerReference) || other.providerReference == providerReference)&&const DeepCollectionEquality().equals(other._metadata, _metadata)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.paidAt, paidAt) || other.paidAt == paidAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,customerId,orderId,channel,provider,amount,currency,status,providerReference,const DeepCollectionEquality().hash(_metadata),createdAt,paidAt);

@override
String toString() {
  return 'PaymentRecord(id: $id, customerId: $customerId, orderId: $orderId, channel: $channel, provider: $provider, amount: $amount, currency: $currency, status: $status, providerReference: $providerReference, metadata: $metadata, createdAt: $createdAt, paidAt: $paidAt)';
}


}

/// @nodoc
abstract mixin class _$PaymentRecordCopyWith<$Res> implements $PaymentRecordCopyWith<$Res> {
  factory _$PaymentRecordCopyWith(_PaymentRecord value, $Res Function(_PaymentRecord) _then) = __$PaymentRecordCopyWithImpl;
@override @useResult
$Res call({
 String id, String customerId, String? orderId, PaymentChannel channel, String? provider, double amount, String currency, PaymentTxnStatus status, String? providerReference, Map<String, dynamic> metadata, DateTime createdAt, DateTime? paidAt
});




}
/// @nodoc
class __$PaymentRecordCopyWithImpl<$Res>
    implements _$PaymentRecordCopyWith<$Res> {
  __$PaymentRecordCopyWithImpl(this._self, this._then);

  final _PaymentRecord _self;
  final $Res Function(_PaymentRecord) _then;

/// Create a copy of PaymentRecord
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? customerId = null,Object? orderId = freezed,Object? channel = null,Object? provider = freezed,Object? amount = null,Object? currency = null,Object? status = null,Object? providerReference = freezed,Object? metadata = null,Object? createdAt = null,Object? paidAt = freezed,}) {
  return _then(_PaymentRecord(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,customerId: null == customerId ? _self.customerId : customerId // ignore: cast_nullable_to_non_nullable
as String,orderId: freezed == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as String?,channel: null == channel ? _self.channel : channel // ignore: cast_nullable_to_non_nullable
as PaymentChannel,provider: freezed == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as String?,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as PaymentTxnStatus,providerReference: freezed == providerReference ? _self.providerReference : providerReference // ignore: cast_nullable_to_non_nullable
as String?,metadata: null == metadata ? _self._metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,paidAt: freezed == paidAt ? _self.paidAt : paidAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

/// @nodoc
mixin _$InstapayDetails {

 bool get configured; String? get ipaAddress; String? get beneficiaryName;
/// Create a copy of InstapayDetails
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InstapayDetailsCopyWith<InstapayDetails> get copyWith => _$InstapayDetailsCopyWithImpl<InstapayDetails>(this as InstapayDetails, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InstapayDetails&&(identical(other.configured, configured) || other.configured == configured)&&(identical(other.ipaAddress, ipaAddress) || other.ipaAddress == ipaAddress)&&(identical(other.beneficiaryName, beneficiaryName) || other.beneficiaryName == beneficiaryName));
}


@override
int get hashCode => Object.hash(runtimeType,configured,ipaAddress,beneficiaryName);

@override
String toString() {
  return 'InstapayDetails(configured: $configured, ipaAddress: $ipaAddress, beneficiaryName: $beneficiaryName)';
}


}

/// @nodoc
abstract mixin class $InstapayDetailsCopyWith<$Res>  {
  factory $InstapayDetailsCopyWith(InstapayDetails value, $Res Function(InstapayDetails) _then) = _$InstapayDetailsCopyWithImpl;
@useResult
$Res call({
 bool configured, String? ipaAddress, String? beneficiaryName
});




}
/// @nodoc
class _$InstapayDetailsCopyWithImpl<$Res>
    implements $InstapayDetailsCopyWith<$Res> {
  _$InstapayDetailsCopyWithImpl(this._self, this._then);

  final InstapayDetails _self;
  final $Res Function(InstapayDetails) _then;

/// Create a copy of InstapayDetails
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? configured = null,Object? ipaAddress = freezed,Object? beneficiaryName = freezed,}) {
  return _then(_self.copyWith(
configured: null == configured ? _self.configured : configured // ignore: cast_nullable_to_non_nullable
as bool,ipaAddress: freezed == ipaAddress ? _self.ipaAddress : ipaAddress // ignore: cast_nullable_to_non_nullable
as String?,beneficiaryName: freezed == beneficiaryName ? _self.beneficiaryName : beneficiaryName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [InstapayDetails].
extension InstapayDetailsPatterns on InstapayDetails {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InstapayDetails value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InstapayDetails() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InstapayDetails value)  $default,){
final _that = this;
switch (_that) {
case _InstapayDetails():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InstapayDetails value)?  $default,){
final _that = this;
switch (_that) {
case _InstapayDetails() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool configured,  String? ipaAddress,  String? beneficiaryName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InstapayDetails() when $default != null:
return $default(_that.configured,_that.ipaAddress,_that.beneficiaryName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool configured,  String? ipaAddress,  String? beneficiaryName)  $default,) {final _that = this;
switch (_that) {
case _InstapayDetails():
return $default(_that.configured,_that.ipaAddress,_that.beneficiaryName);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool configured,  String? ipaAddress,  String? beneficiaryName)?  $default,) {final _that = this;
switch (_that) {
case _InstapayDetails() when $default != null:
return $default(_that.configured,_that.ipaAddress,_that.beneficiaryName);case _:
  return null;

}
}

}

/// @nodoc


class _InstapayDetails implements InstapayDetails {
  const _InstapayDetails({required this.configured, this.ipaAddress, this.beneficiaryName});
  

@override final  bool configured;
@override final  String? ipaAddress;
@override final  String? beneficiaryName;

/// Create a copy of InstapayDetails
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InstapayDetailsCopyWith<_InstapayDetails> get copyWith => __$InstapayDetailsCopyWithImpl<_InstapayDetails>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InstapayDetails&&(identical(other.configured, configured) || other.configured == configured)&&(identical(other.ipaAddress, ipaAddress) || other.ipaAddress == ipaAddress)&&(identical(other.beneficiaryName, beneficiaryName) || other.beneficiaryName == beneficiaryName));
}


@override
int get hashCode => Object.hash(runtimeType,configured,ipaAddress,beneficiaryName);

@override
String toString() {
  return 'InstapayDetails(configured: $configured, ipaAddress: $ipaAddress, beneficiaryName: $beneficiaryName)';
}


}

/// @nodoc
abstract mixin class _$InstapayDetailsCopyWith<$Res> implements $InstapayDetailsCopyWith<$Res> {
  factory _$InstapayDetailsCopyWith(_InstapayDetails value, $Res Function(_InstapayDetails) _then) = __$InstapayDetailsCopyWithImpl;
@override @useResult
$Res call({
 bool configured, String? ipaAddress, String? beneficiaryName
});




}
/// @nodoc
class __$InstapayDetailsCopyWithImpl<$Res>
    implements _$InstapayDetailsCopyWith<$Res> {
  __$InstapayDetailsCopyWithImpl(this._self, this._then);

  final _InstapayDetails _self;
  final $Res Function(_InstapayDetails) _then;

/// Create a copy of InstapayDetails
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? configured = null,Object? ipaAddress = freezed,Object? beneficiaryName = freezed,}) {
  return _then(_InstapayDetails(
configured: null == configured ? _self.configured : configured // ignore: cast_nullable_to_non_nullable
as bool,ipaAddress: freezed == ipaAddress ? _self.ipaAddress : ipaAddress // ignore: cast_nullable_to_non_nullable
as String?,beneficiaryName: freezed == beneficiaryName ? _self.beneficiaryName : beneficiaryName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
