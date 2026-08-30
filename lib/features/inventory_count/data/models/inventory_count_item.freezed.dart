// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'inventory_count_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$InventoryCountItem {

 String get id; String get productId; String get productName; String get sku; int get systemQuantity; int? get actualQuantity; int get difference; String? get reason; String? get notes;
/// Create a copy of InventoryCountItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InventoryCountItemCopyWith<InventoryCountItem> get copyWith => _$InventoryCountItemCopyWithImpl<InventoryCountItem>(this as InventoryCountItem, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InventoryCountItem&&(identical(other.id, id) || other.id == id)&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.productName, productName) || other.productName == productName)&&(identical(other.sku, sku) || other.sku == sku)&&(identical(other.systemQuantity, systemQuantity) || other.systemQuantity == systemQuantity)&&(identical(other.actualQuantity, actualQuantity) || other.actualQuantity == actualQuantity)&&(identical(other.difference, difference) || other.difference == difference)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.notes, notes) || other.notes == notes));
}


@override
int get hashCode => Object.hash(runtimeType,id,productId,productName,sku,systemQuantity,actualQuantity,difference,reason,notes);

@override
String toString() {
  return 'InventoryCountItem(id: $id, productId: $productId, productName: $productName, sku: $sku, systemQuantity: $systemQuantity, actualQuantity: $actualQuantity, difference: $difference, reason: $reason, notes: $notes)';
}


}

/// @nodoc
abstract mixin class $InventoryCountItemCopyWith<$Res>  {
  factory $InventoryCountItemCopyWith(InventoryCountItem value, $Res Function(InventoryCountItem) _then) = _$InventoryCountItemCopyWithImpl;
@useResult
$Res call({
 String id, String productId, String productName, String sku, int systemQuantity, int? actualQuantity, int difference, String? reason, String? notes
});




}
/// @nodoc
class _$InventoryCountItemCopyWithImpl<$Res>
    implements $InventoryCountItemCopyWith<$Res> {
  _$InventoryCountItemCopyWithImpl(this._self, this._then);

  final InventoryCountItem _self;
  final $Res Function(InventoryCountItem) _then;

/// Create a copy of InventoryCountItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? productId = null,Object? productName = null,Object? sku = null,Object? systemQuantity = null,Object? actualQuantity = freezed,Object? difference = null,Object? reason = freezed,Object? notes = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String,productName: null == productName ? _self.productName : productName // ignore: cast_nullable_to_non_nullable
as String,sku: null == sku ? _self.sku : sku // ignore: cast_nullable_to_non_nullable
as String,systemQuantity: null == systemQuantity ? _self.systemQuantity : systemQuantity // ignore: cast_nullable_to_non_nullable
as int,actualQuantity: freezed == actualQuantity ? _self.actualQuantity : actualQuantity // ignore: cast_nullable_to_non_nullable
as int?,difference: null == difference ? _self.difference : difference // ignore: cast_nullable_to_non_nullable
as int,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [InventoryCountItem].
extension InventoryCountItemPatterns on InventoryCountItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InventoryCountItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InventoryCountItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InventoryCountItem value)  $default,){
final _that = this;
switch (_that) {
case _InventoryCountItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InventoryCountItem value)?  $default,){
final _that = this;
switch (_that) {
case _InventoryCountItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String productId,  String productName,  String sku,  int systemQuantity,  int? actualQuantity,  int difference,  String? reason,  String? notes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InventoryCountItem() when $default != null:
return $default(_that.id,_that.productId,_that.productName,_that.sku,_that.systemQuantity,_that.actualQuantity,_that.difference,_that.reason,_that.notes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String productId,  String productName,  String sku,  int systemQuantity,  int? actualQuantity,  int difference,  String? reason,  String? notes)  $default,) {final _that = this;
switch (_that) {
case _InventoryCountItem():
return $default(_that.id,_that.productId,_that.productName,_that.sku,_that.systemQuantity,_that.actualQuantity,_that.difference,_that.reason,_that.notes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String productId,  String productName,  String sku,  int systemQuantity,  int? actualQuantity,  int difference,  String? reason,  String? notes)?  $default,) {final _that = this;
switch (_that) {
case _InventoryCountItem() when $default != null:
return $default(_that.id,_that.productId,_that.productName,_that.sku,_that.systemQuantity,_that.actualQuantity,_that.difference,_that.reason,_that.notes);case _:
  return null;

}
}

}

/// @nodoc


class _InventoryCountItem extends InventoryCountItem {
  const _InventoryCountItem({required this.id, required this.productId, required this.productName, required this.sku, required this.systemQuantity, this.actualQuantity, required this.difference, this.reason, this.notes}): super._();
  

@override final  String id;
@override final  String productId;
@override final  String productName;
@override final  String sku;
@override final  int systemQuantity;
@override final  int? actualQuantity;
@override final  int difference;
@override final  String? reason;
@override final  String? notes;

/// Create a copy of InventoryCountItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InventoryCountItemCopyWith<_InventoryCountItem> get copyWith => __$InventoryCountItemCopyWithImpl<_InventoryCountItem>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InventoryCountItem&&(identical(other.id, id) || other.id == id)&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.productName, productName) || other.productName == productName)&&(identical(other.sku, sku) || other.sku == sku)&&(identical(other.systemQuantity, systemQuantity) || other.systemQuantity == systemQuantity)&&(identical(other.actualQuantity, actualQuantity) || other.actualQuantity == actualQuantity)&&(identical(other.difference, difference) || other.difference == difference)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.notes, notes) || other.notes == notes));
}


@override
int get hashCode => Object.hash(runtimeType,id,productId,productName,sku,systemQuantity,actualQuantity,difference,reason,notes);

@override
String toString() {
  return 'InventoryCountItem(id: $id, productId: $productId, productName: $productName, sku: $sku, systemQuantity: $systemQuantity, actualQuantity: $actualQuantity, difference: $difference, reason: $reason, notes: $notes)';
}


}

/// @nodoc
abstract mixin class _$InventoryCountItemCopyWith<$Res> implements $InventoryCountItemCopyWith<$Res> {
  factory _$InventoryCountItemCopyWith(_InventoryCountItem value, $Res Function(_InventoryCountItem) _then) = __$InventoryCountItemCopyWithImpl;
@override @useResult
$Res call({
 String id, String productId, String productName, String sku, int systemQuantity, int? actualQuantity, int difference, String? reason, String? notes
});




}
/// @nodoc
class __$InventoryCountItemCopyWithImpl<$Res>
    implements _$InventoryCountItemCopyWith<$Res> {
  __$InventoryCountItemCopyWithImpl(this._self, this._then);

  final _InventoryCountItem _self;
  final $Res Function(_InventoryCountItem) _then;

/// Create a copy of InventoryCountItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? productId = null,Object? productName = null,Object? sku = null,Object? systemQuantity = null,Object? actualQuantity = freezed,Object? difference = null,Object? reason = freezed,Object? notes = freezed,}) {
  return _then(_InventoryCountItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String,productName: null == productName ? _self.productName : productName // ignore: cast_nullable_to_non_nullable
as String,sku: null == sku ? _self.sku : sku // ignore: cast_nullable_to_non_nullable
as String,systemQuantity: null == systemQuantity ? _self.systemQuantity : systemQuantity // ignore: cast_nullable_to_non_nullable
as int,actualQuantity: freezed == actualQuantity ? _self.actualQuantity : actualQuantity // ignore: cast_nullable_to_non_nullable
as int?,difference: null == difference ? _self.difference : difference // ignore: cast_nullable_to_non_nullable
as int,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
