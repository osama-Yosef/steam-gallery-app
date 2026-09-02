// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'product.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Product {

 String get id; String get sku; String? get barcode; String? get categoryId; String get name; String? get description; Map<String, String> get specs; double get costPrice; double get sellingPrice; int get minStock; bool get isActive; DateTime get createdAt; String? get primaryImageUrl;
/// Create a copy of Product
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductCopyWith<Product> get copyWith => _$ProductCopyWithImpl<Product>(this as Product, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Product&&(identical(other.id, id) || other.id == id)&&(identical(other.sku, sku) || other.sku == sku)&&(identical(other.barcode, barcode) || other.barcode == barcode)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other.specs, specs)&&(identical(other.costPrice, costPrice) || other.costPrice == costPrice)&&(identical(other.sellingPrice, sellingPrice) || other.sellingPrice == sellingPrice)&&(identical(other.minStock, minStock) || other.minStock == minStock)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.primaryImageUrl, primaryImageUrl) || other.primaryImageUrl == primaryImageUrl));
}


@override
int get hashCode => Object.hash(runtimeType,id,sku,barcode,categoryId,name,description,const DeepCollectionEquality().hash(specs),costPrice,sellingPrice,minStock,isActive,createdAt,primaryImageUrl);

@override
String toString() {
  return 'Product(id: $id, sku: $sku, barcode: $barcode, categoryId: $categoryId, name: $name, description: $description, specs: $specs, costPrice: $costPrice, sellingPrice: $sellingPrice, minStock: $minStock, isActive: $isActive, createdAt: $createdAt, primaryImageUrl: $primaryImageUrl)';
}


}

/// @nodoc
abstract mixin class $ProductCopyWith<$Res>  {
  factory $ProductCopyWith(Product value, $Res Function(Product) _then) = _$ProductCopyWithImpl;
@useResult
$Res call({
 String id, String sku, String? barcode, String? categoryId, String name, String? description, Map<String, String> specs, double costPrice, double sellingPrice, int minStock, bool isActive, DateTime createdAt, String? primaryImageUrl
});




}
/// @nodoc
class _$ProductCopyWithImpl<$Res>
    implements $ProductCopyWith<$Res> {
  _$ProductCopyWithImpl(this._self, this._then);

  final Product _self;
  final $Res Function(Product) _then;

/// Create a copy of Product
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? sku = null,Object? barcode = freezed,Object? categoryId = freezed,Object? name = null,Object? description = freezed,Object? specs = null,Object? costPrice = null,Object? sellingPrice = null,Object? minStock = null,Object? isActive = null,Object? createdAt = null,Object? primaryImageUrl = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sku: null == sku ? _self.sku : sku // ignore: cast_nullable_to_non_nullable
as String,barcode: freezed == barcode ? _self.barcode : barcode // ignore: cast_nullable_to_non_nullable
as String?,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,specs: null == specs ? _self.specs : specs // ignore: cast_nullable_to_non_nullable
as Map<String, String>,costPrice: null == costPrice ? _self.costPrice : costPrice // ignore: cast_nullable_to_non_nullable
as double,sellingPrice: null == sellingPrice ? _self.sellingPrice : sellingPrice // ignore: cast_nullable_to_non_nullable
as double,minStock: null == minStock ? _self.minStock : minStock // ignore: cast_nullable_to_non_nullable
as int,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,primaryImageUrl: freezed == primaryImageUrl ? _self.primaryImageUrl : primaryImageUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Product].
extension ProductPatterns on Product {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Product value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Product() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Product value)  $default,){
final _that = this;
switch (_that) {
case _Product():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Product value)?  $default,){
final _that = this;
switch (_that) {
case _Product() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String sku,  String? barcode,  String? categoryId,  String name,  String? description,  Map<String, String> specs,  double costPrice,  double sellingPrice,  int minStock,  bool isActive,  DateTime createdAt,  String? primaryImageUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Product() when $default != null:
return $default(_that.id,_that.sku,_that.barcode,_that.categoryId,_that.name,_that.description,_that.specs,_that.costPrice,_that.sellingPrice,_that.minStock,_that.isActive,_that.createdAt,_that.primaryImageUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String sku,  String? barcode,  String? categoryId,  String name,  String? description,  Map<String, String> specs,  double costPrice,  double sellingPrice,  int minStock,  bool isActive,  DateTime createdAt,  String? primaryImageUrl)  $default,) {final _that = this;
switch (_that) {
case _Product():
return $default(_that.id,_that.sku,_that.barcode,_that.categoryId,_that.name,_that.description,_that.specs,_that.costPrice,_that.sellingPrice,_that.minStock,_that.isActive,_that.createdAt,_that.primaryImageUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String sku,  String? barcode,  String? categoryId,  String name,  String? description,  Map<String, String> specs,  double costPrice,  double sellingPrice,  int minStock,  bool isActive,  DateTime createdAt,  String? primaryImageUrl)?  $default,) {final _that = this;
switch (_that) {
case _Product() when $default != null:
return $default(_that.id,_that.sku,_that.barcode,_that.categoryId,_that.name,_that.description,_that.specs,_that.costPrice,_that.sellingPrice,_that.minStock,_that.isActive,_that.createdAt,_that.primaryImageUrl);case _:
  return null;

}
}

}

/// @nodoc


class _Product implements Product {
  const _Product({required this.id, required this.sku, this.barcode, this.categoryId, required this.name, this.description, required final  Map<String, String> specs, required this.costPrice, required this.sellingPrice, required this.minStock, required this.isActive, required this.createdAt, this.primaryImageUrl}): _specs = specs;
  

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

@override final  double costPrice;
@override final  double sellingPrice;
@override final  int minStock;
@override final  bool isActive;
@override final  DateTime createdAt;
@override final  String? primaryImageUrl;

/// Create a copy of Product
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProductCopyWith<_Product> get copyWith => __$ProductCopyWithImpl<_Product>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Product&&(identical(other.id, id) || other.id == id)&&(identical(other.sku, sku) || other.sku == sku)&&(identical(other.barcode, barcode) || other.barcode == barcode)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other._specs, _specs)&&(identical(other.costPrice, costPrice) || other.costPrice == costPrice)&&(identical(other.sellingPrice, sellingPrice) || other.sellingPrice == sellingPrice)&&(identical(other.minStock, minStock) || other.minStock == minStock)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.primaryImageUrl, primaryImageUrl) || other.primaryImageUrl == primaryImageUrl));
}


@override
int get hashCode => Object.hash(runtimeType,id,sku,barcode,categoryId,name,description,const DeepCollectionEquality().hash(_specs),costPrice,sellingPrice,minStock,isActive,createdAt,primaryImageUrl);

@override
String toString() {
  return 'Product(id: $id, sku: $sku, barcode: $barcode, categoryId: $categoryId, name: $name, description: $description, specs: $specs, costPrice: $costPrice, sellingPrice: $sellingPrice, minStock: $minStock, isActive: $isActive, createdAt: $createdAt, primaryImageUrl: $primaryImageUrl)';
}


}

/// @nodoc
abstract mixin class _$ProductCopyWith<$Res> implements $ProductCopyWith<$Res> {
  factory _$ProductCopyWith(_Product value, $Res Function(_Product) _then) = __$ProductCopyWithImpl;
@override @useResult
$Res call({
 String id, String sku, String? barcode, String? categoryId, String name, String? description, Map<String, String> specs, double costPrice, double sellingPrice, int minStock, bool isActive, DateTime createdAt, String? primaryImageUrl
});




}
/// @nodoc
class __$ProductCopyWithImpl<$Res>
    implements _$ProductCopyWith<$Res> {
  __$ProductCopyWithImpl(this._self, this._then);

  final _Product _self;
  final $Res Function(_Product) _then;

/// Create a copy of Product
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? sku = null,Object? barcode = freezed,Object? categoryId = freezed,Object? name = null,Object? description = freezed,Object? specs = null,Object? costPrice = null,Object? sellingPrice = null,Object? minStock = null,Object? isActive = null,Object? createdAt = null,Object? primaryImageUrl = freezed,}) {
  return _then(_Product(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sku: null == sku ? _self.sku : sku // ignore: cast_nullable_to_non_nullable
as String,barcode: freezed == barcode ? _self.barcode : barcode // ignore: cast_nullable_to_non_nullable
as String?,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,specs: null == specs ? _self._specs : specs // ignore: cast_nullable_to_non_nullable
as Map<String, String>,costPrice: null == costPrice ? _self.costPrice : costPrice // ignore: cast_nullable_to_non_nullable
as double,sellingPrice: null == sellingPrice ? _self.sellingPrice : sellingPrice // ignore: cast_nullable_to_non_nullable
as double,minStock: null == minStock ? _self.minStock : minStock // ignore: cast_nullable_to_non_nullable
as int,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,primaryImageUrl: freezed == primaryImageUrl ? _self.primaryImageUrl : primaryImageUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
