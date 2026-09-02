// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'product_public.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ProductPublic {

 String get id; String get sku; String? get barcode; String? get categoryId; String get name; String? get description; Map<String, String> get specs; double get sellingPrice; bool get isAvailable; DateTime get createdAt; String? get primaryImageUrl;
/// Create a copy of ProductPublic
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductPublicCopyWith<ProductPublic> get copyWith => _$ProductPublicCopyWithImpl<ProductPublic>(this as ProductPublic, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProductPublic&&(identical(other.id, id) || other.id == id)&&(identical(other.sku, sku) || other.sku == sku)&&(identical(other.barcode, barcode) || other.barcode == barcode)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other.specs, specs)&&(identical(other.sellingPrice, sellingPrice) || other.sellingPrice == sellingPrice)&&(identical(other.isAvailable, isAvailable) || other.isAvailable == isAvailable)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.primaryImageUrl, primaryImageUrl) || other.primaryImageUrl == primaryImageUrl));
}


@override
int get hashCode => Object.hash(runtimeType,id,sku,barcode,categoryId,name,description,const DeepCollectionEquality().hash(specs),sellingPrice,isAvailable,createdAt,primaryImageUrl);

@override
String toString() {
  return 'ProductPublic(id: $id, sku: $sku, barcode: $barcode, categoryId: $categoryId, name: $name, description: $description, specs: $specs, sellingPrice: $sellingPrice, isAvailable: $isAvailable, createdAt: $createdAt, primaryImageUrl: $primaryImageUrl)';
}


}

/// @nodoc
abstract mixin class $ProductPublicCopyWith<$Res>  {
  factory $ProductPublicCopyWith(ProductPublic value, $Res Function(ProductPublic) _then) = _$ProductPublicCopyWithImpl;
@useResult
$Res call({
 String id, String sku, String? barcode, String? categoryId, String name, String? description, Map<String, String> specs, double sellingPrice, bool isAvailable, DateTime createdAt, String? primaryImageUrl
});




}
/// @nodoc
class _$ProductPublicCopyWithImpl<$Res>
    implements $ProductPublicCopyWith<$Res> {
  _$ProductPublicCopyWithImpl(this._self, this._then);

  final ProductPublic _self;
  final $Res Function(ProductPublic) _then;

/// Create a copy of ProductPublic
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? sku = null,Object? barcode = freezed,Object? categoryId = freezed,Object? name = null,Object? description = freezed,Object? specs = null,Object? sellingPrice = null,Object? isAvailable = null,Object? createdAt = null,Object? primaryImageUrl = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sku: null == sku ? _self.sku : sku // ignore: cast_nullable_to_non_nullable
as String,barcode: freezed == barcode ? _self.barcode : barcode // ignore: cast_nullable_to_non_nullable
as String?,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,specs: null == specs ? _self.specs : specs // ignore: cast_nullable_to_non_nullable
as Map<String, String>,sellingPrice: null == sellingPrice ? _self.sellingPrice : sellingPrice // ignore: cast_nullable_to_non_nullable
as double,isAvailable: null == isAvailable ? _self.isAvailable : isAvailable // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,primaryImageUrl: freezed == primaryImageUrl ? _self.primaryImageUrl : primaryImageUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ProductPublic].
extension ProductPublicPatterns on ProductPublic {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProductPublic value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProductPublic() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProductPublic value)  $default,){
final _that = this;
switch (_that) {
case _ProductPublic():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProductPublic value)?  $default,){
final _that = this;
switch (_that) {
case _ProductPublic() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String sku,  String? barcode,  String? categoryId,  String name,  String? description,  Map<String, String> specs,  double sellingPrice,  bool isAvailable,  DateTime createdAt,  String? primaryImageUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProductPublic() when $default != null:
return $default(_that.id,_that.sku,_that.barcode,_that.categoryId,_that.name,_that.description,_that.specs,_that.sellingPrice,_that.isAvailable,_that.createdAt,_that.primaryImageUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String sku,  String? barcode,  String? categoryId,  String name,  String? description,  Map<String, String> specs,  double sellingPrice,  bool isAvailable,  DateTime createdAt,  String? primaryImageUrl)  $default,) {final _that = this;
switch (_that) {
case _ProductPublic():
return $default(_that.id,_that.sku,_that.barcode,_that.categoryId,_that.name,_that.description,_that.specs,_that.sellingPrice,_that.isAvailable,_that.createdAt,_that.primaryImageUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String sku,  String? barcode,  String? categoryId,  String name,  String? description,  Map<String, String> specs,  double sellingPrice,  bool isAvailable,  DateTime createdAt,  String? primaryImageUrl)?  $default,) {final _that = this;
switch (_that) {
case _ProductPublic() when $default != null:
return $default(_that.id,_that.sku,_that.barcode,_that.categoryId,_that.name,_that.description,_that.specs,_that.sellingPrice,_that.isAvailable,_that.createdAt,_that.primaryImageUrl);case _:
  return null;

}
}

}

/// @nodoc


class _ProductPublic implements ProductPublic {
  const _ProductPublic({required this.id, required this.sku, this.barcode, this.categoryId, required this.name, this.description, required final  Map<String, String> specs, required this.sellingPrice, required this.isAvailable, required this.createdAt, this.primaryImageUrl}): _specs = specs;
  

@override final  String id;
@override final  String sku;
@override final  String? barcode;
@override final  String? categoryId;
@override final  String name;
@override final  String? description;
 final  Map<String, String> _specs;
@override Map<String, String> get specs {
  if (_specs is EqualUnmodifiableMapView) return _specs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_specs);
}

@override final  double sellingPrice;
@override final  bool isAvailable;
@override final  DateTime createdAt;
@override final  String? primaryImageUrl;

/// Create a copy of ProductPublic
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProductPublicCopyWith<_ProductPublic> get copyWith => __$ProductPublicCopyWithImpl<_ProductPublic>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProductPublic&&(identical(other.id, id) || other.id == id)&&(identical(other.sku, sku) || other.sku == sku)&&(identical(other.barcode, barcode) || other.barcode == barcode)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other._specs, _specs)&&(identical(other.sellingPrice, sellingPrice) || other.sellingPrice == sellingPrice)&&(identical(other.isAvailable, isAvailable) || other.isAvailable == isAvailable)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.primaryImageUrl, primaryImageUrl) || other.primaryImageUrl == primaryImageUrl));
}


@override
int get hashCode => Object.hash(runtimeType,id,sku,barcode,categoryId,name,description,const DeepCollectionEquality().hash(_specs),sellingPrice,isAvailable,createdAt,primaryImageUrl);

@override
String toString() {
  return 'ProductPublic(id: $id, sku: $sku, barcode: $barcode, categoryId: $categoryId, name: $name, description: $description, specs: $specs, sellingPrice: $sellingPrice, isAvailable: $isAvailable, createdAt: $createdAt, primaryImageUrl: $primaryImageUrl)';
}


}

/// @nodoc
abstract mixin class _$ProductPublicCopyWith<$Res> implements $ProductPublicCopyWith<$Res> {
  factory _$ProductPublicCopyWith(_ProductPublic value, $Res Function(_ProductPublic) _then) = __$ProductPublicCopyWithImpl;
@override @useResult
$Res call({
 String id, String sku, String? barcode, String? categoryId, String name, String? description, Map<String, String> specs, double sellingPrice, bool isAvailable, DateTime createdAt, String? primaryImageUrl
});




}
/// @nodoc
class __$ProductPublicCopyWithImpl<$Res>
    implements _$ProductPublicCopyWith<$Res> {
  __$ProductPublicCopyWithImpl(this._self, this._then);

  final _ProductPublic _self;
  final $Res Function(_ProductPublic) _then;

/// Create a copy of ProductPublic
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? sku = null,Object? barcode = freezed,Object? categoryId = freezed,Object? name = null,Object? description = freezed,Object? specs = null,Object? sellingPrice = null,Object? isAvailable = null,Object? createdAt = null,Object? primaryImageUrl = freezed,}) {
  return _then(_ProductPublic(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sku: null == sku ? _self.sku : sku // ignore: cast_nullable_to_non_nullable
as String,barcode: freezed == barcode ? _self.barcode : barcode // ignore: cast_nullable_to_non_nullable
as String?,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,specs: null == specs ? _self._specs : specs // ignore: cast_nullable_to_non_nullable
as Map<String, String>,sellingPrice: null == sellingPrice ? _self.sellingPrice : sellingPrice // ignore: cast_nullable_to_non_nullable
as double,isAvailable: null == isAvailable ? _self.isAvailable : isAvailable // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,primaryImageUrl: freezed == primaryImageUrl ? _self.primaryImageUrl : primaryImageUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
