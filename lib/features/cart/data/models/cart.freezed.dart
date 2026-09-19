// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'cart.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CartLine {

 String get productId; String get name; String? get sku; String? get imageUrl; int get quantity; double get unitPrice; double get priceSeen; bool get priceChanged; double get lineTotal; bool get isActive; bool get isAvailable; List<String> get optionIds; List<SelectedOption> get options;
/// Create a copy of CartLine
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CartLineCopyWith<CartLine> get copyWith => _$CartLineCopyWithImpl<CartLine>(this as CartLine, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CartLine&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.name, name) || other.name == name)&&(identical(other.sku, sku) || other.sku == sku)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.unitPrice, unitPrice) || other.unitPrice == unitPrice)&&(identical(other.priceSeen, priceSeen) || other.priceSeen == priceSeen)&&(identical(other.priceChanged, priceChanged) || other.priceChanged == priceChanged)&&(identical(other.lineTotal, lineTotal) || other.lineTotal == lineTotal)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.isAvailable, isAvailable) || other.isAvailable == isAvailable)&&const DeepCollectionEquality().equals(other.optionIds, optionIds)&&const DeepCollectionEquality().equals(other.options, options));
}


@override
int get hashCode => Object.hash(runtimeType,productId,name,sku,imageUrl,quantity,unitPrice,priceSeen,priceChanged,lineTotal,isActive,isAvailable,const DeepCollectionEquality().hash(optionIds),const DeepCollectionEquality().hash(options));

@override
String toString() {
  return 'CartLine(productId: $productId, name: $name, sku: $sku, imageUrl: $imageUrl, quantity: $quantity, unitPrice: $unitPrice, priceSeen: $priceSeen, priceChanged: $priceChanged, lineTotal: $lineTotal, isActive: $isActive, isAvailable: $isAvailable, optionIds: $optionIds, options: $options)';
}


}

/// @nodoc
abstract mixin class $CartLineCopyWith<$Res>  {
  factory $CartLineCopyWith(CartLine value, $Res Function(CartLine) _then) = _$CartLineCopyWithImpl;
@useResult
$Res call({
 String productId, String name, String? sku, String? imageUrl, int quantity, double unitPrice, double priceSeen, bool priceChanged, double lineTotal, bool isActive, bool isAvailable, List<String> optionIds, List<SelectedOption> options
});




}
/// @nodoc
class _$CartLineCopyWithImpl<$Res>
    implements $CartLineCopyWith<$Res> {
  _$CartLineCopyWithImpl(this._self, this._then);

  final CartLine _self;
  final $Res Function(CartLine) _then;

/// Create a copy of CartLine
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? productId = null,Object? name = null,Object? sku = freezed,Object? imageUrl = freezed,Object? quantity = null,Object? unitPrice = null,Object? priceSeen = null,Object? priceChanged = null,Object? lineTotal = null,Object? isActive = null,Object? isAvailable = null,Object? optionIds = null,Object? options = null,}) {
  return _then(_self.copyWith(
productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,sku: freezed == sku ? _self.sku : sku // ignore: cast_nullable_to_non_nullable
as String?,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,unitPrice: null == unitPrice ? _self.unitPrice : unitPrice // ignore: cast_nullable_to_non_nullable
as double,priceSeen: null == priceSeen ? _self.priceSeen : priceSeen // ignore: cast_nullable_to_non_nullable
as double,priceChanged: null == priceChanged ? _self.priceChanged : priceChanged // ignore: cast_nullable_to_non_nullable
as bool,lineTotal: null == lineTotal ? _self.lineTotal : lineTotal // ignore: cast_nullable_to_non_nullable
as double,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,isAvailable: null == isAvailable ? _self.isAvailable : isAvailable // ignore: cast_nullable_to_non_nullable
as bool,optionIds: null == optionIds ? _self.optionIds : optionIds // ignore: cast_nullable_to_non_nullable
as List<String>,options: null == options ? _self.options : options // ignore: cast_nullable_to_non_nullable
as List<SelectedOption>,
  ));
}

}


/// Adds pattern-matching-related methods to [CartLine].
extension CartLinePatterns on CartLine {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CartLine value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CartLine() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CartLine value)  $default,){
final _that = this;
switch (_that) {
case _CartLine():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CartLine value)?  $default,){
final _that = this;
switch (_that) {
case _CartLine() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String productId,  String name,  String? sku,  String? imageUrl,  int quantity,  double unitPrice,  double priceSeen,  bool priceChanged,  double lineTotal,  bool isActive,  bool isAvailable,  List<String> optionIds,  List<SelectedOption> options)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CartLine() when $default != null:
return $default(_that.productId,_that.name,_that.sku,_that.imageUrl,_that.quantity,_that.unitPrice,_that.priceSeen,_that.priceChanged,_that.lineTotal,_that.isActive,_that.isAvailable,_that.optionIds,_that.options);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String productId,  String name,  String? sku,  String? imageUrl,  int quantity,  double unitPrice,  double priceSeen,  bool priceChanged,  double lineTotal,  bool isActive,  bool isAvailable,  List<String> optionIds,  List<SelectedOption> options)  $default,) {final _that = this;
switch (_that) {
case _CartLine():
return $default(_that.productId,_that.name,_that.sku,_that.imageUrl,_that.quantity,_that.unitPrice,_that.priceSeen,_that.priceChanged,_that.lineTotal,_that.isActive,_that.isAvailable,_that.optionIds,_that.options);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String productId,  String name,  String? sku,  String? imageUrl,  int quantity,  double unitPrice,  double priceSeen,  bool priceChanged,  double lineTotal,  bool isActive,  bool isAvailable,  List<String> optionIds,  List<SelectedOption> options)?  $default,) {final _that = this;
switch (_that) {
case _CartLine() when $default != null:
return $default(_that.productId,_that.name,_that.sku,_that.imageUrl,_that.quantity,_that.unitPrice,_that.priceSeen,_that.priceChanged,_that.lineTotal,_that.isActive,_that.isAvailable,_that.optionIds,_that.options);case _:
  return null;

}
}

}

/// @nodoc


class _CartLine extends CartLine {
  const _CartLine({required this.productId, required this.name, this.sku, this.imageUrl, required this.quantity, required this.unitPrice, required this.priceSeen, required this.priceChanged, required this.lineTotal, required this.isActive, required this.isAvailable, required final  List<String> optionIds, required final  List<SelectedOption> options}): _optionIds = optionIds,_options = options,super._();
  

@override final  String productId;
@override final  String name;
@override final  String? sku;
@override final  String? imageUrl;
@override final  int quantity;
@override final  double unitPrice;
@override final  double priceSeen;
@override final  bool priceChanged;
@override final  double lineTotal;
@override final  bool isActive;
@override final  bool isAvailable;
 final  List<String> _optionIds;
@override List<String> get optionIds {
  if (_optionIds is EqualUnmodifiableListView) return _optionIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_optionIds);
}

 final  List<SelectedOption> _options;
@override List<SelectedOption> get options {
  if (_options is EqualUnmodifiableListView) return _options;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_options);
}


/// Create a copy of CartLine
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CartLineCopyWith<_CartLine> get copyWith => __$CartLineCopyWithImpl<_CartLine>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CartLine&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.name, name) || other.name == name)&&(identical(other.sku, sku) || other.sku == sku)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.unitPrice, unitPrice) || other.unitPrice == unitPrice)&&(identical(other.priceSeen, priceSeen) || other.priceSeen == priceSeen)&&(identical(other.priceChanged, priceChanged) || other.priceChanged == priceChanged)&&(identical(other.lineTotal, lineTotal) || other.lineTotal == lineTotal)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.isAvailable, isAvailable) || other.isAvailable == isAvailable)&&const DeepCollectionEquality().equals(other._optionIds, _optionIds)&&const DeepCollectionEquality().equals(other._options, _options));
}


@override
int get hashCode => Object.hash(runtimeType,productId,name,sku,imageUrl,quantity,unitPrice,priceSeen,priceChanged,lineTotal,isActive,isAvailable,const DeepCollectionEquality().hash(_optionIds),const DeepCollectionEquality().hash(_options));

@override
String toString() {
  return 'CartLine(productId: $productId, name: $name, sku: $sku, imageUrl: $imageUrl, quantity: $quantity, unitPrice: $unitPrice, priceSeen: $priceSeen, priceChanged: $priceChanged, lineTotal: $lineTotal, isActive: $isActive, isAvailable: $isAvailable, optionIds: $optionIds, options: $options)';
}


}

/// @nodoc
abstract mixin class _$CartLineCopyWith<$Res> implements $CartLineCopyWith<$Res> {
  factory _$CartLineCopyWith(_CartLine value, $Res Function(_CartLine) _then) = __$CartLineCopyWithImpl;
@override @useResult
$Res call({
 String productId, String name, String? sku, String? imageUrl, int quantity, double unitPrice, double priceSeen, bool priceChanged, double lineTotal, bool isActive, bool isAvailable, List<String> optionIds, List<SelectedOption> options
});




}
/// @nodoc
class __$CartLineCopyWithImpl<$Res>
    implements _$CartLineCopyWith<$Res> {
  __$CartLineCopyWithImpl(this._self, this._then);

  final _CartLine _self;
  final $Res Function(_CartLine) _then;

/// Create a copy of CartLine
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? productId = null,Object? name = null,Object? sku = freezed,Object? imageUrl = freezed,Object? quantity = null,Object? unitPrice = null,Object? priceSeen = null,Object? priceChanged = null,Object? lineTotal = null,Object? isActive = null,Object? isAvailable = null,Object? optionIds = null,Object? options = null,}) {
  return _then(_CartLine(
productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,sku: freezed == sku ? _self.sku : sku // ignore: cast_nullable_to_non_nullable
as String?,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,unitPrice: null == unitPrice ? _self.unitPrice : unitPrice // ignore: cast_nullable_to_non_nullable
as double,priceSeen: null == priceSeen ? _self.priceSeen : priceSeen // ignore: cast_nullable_to_non_nullable
as double,priceChanged: null == priceChanged ? _self.priceChanged : priceChanged // ignore: cast_nullable_to_non_nullable
as bool,lineTotal: null == lineTotal ? _self.lineTotal : lineTotal // ignore: cast_nullable_to_non_nullable
as double,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,isAvailable: null == isAvailable ? _self.isAvailable : isAvailable // ignore: cast_nullable_to_non_nullable
as bool,optionIds: null == optionIds ? _self._optionIds : optionIds // ignore: cast_nullable_to_non_nullable
as List<String>,options: null == options ? _self._options : options // ignore: cast_nullable_to_non_nullable
as List<SelectedOption>,
  ));
}


}

/// @nodoc
mixin _$CartSummary {

 List<CartLine> get items; int get itemCount; double get subtotal; String get currency; bool get hasIssues;
/// Create a copy of CartSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CartSummaryCopyWith<CartSummary> get copyWith => _$CartSummaryCopyWithImpl<CartSummary>(this as CartSummary, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CartSummary&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.itemCount, itemCount) || other.itemCount == itemCount)&&(identical(other.subtotal, subtotal) || other.subtotal == subtotal)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.hasIssues, hasIssues) || other.hasIssues == hasIssues));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(items),itemCount,subtotal,currency,hasIssues);

@override
String toString() {
  return 'CartSummary(items: $items, itemCount: $itemCount, subtotal: $subtotal, currency: $currency, hasIssues: $hasIssues)';
}


}

/// @nodoc
abstract mixin class $CartSummaryCopyWith<$Res>  {
  factory $CartSummaryCopyWith(CartSummary value, $Res Function(CartSummary) _then) = _$CartSummaryCopyWithImpl;
@useResult
$Res call({
 List<CartLine> items, int itemCount, double subtotal, String currency, bool hasIssues
});




}
/// @nodoc
class _$CartSummaryCopyWithImpl<$Res>
    implements $CartSummaryCopyWith<$Res> {
  _$CartSummaryCopyWithImpl(this._self, this._then);

  final CartSummary _self;
  final $Res Function(CartSummary) _then;

/// Create a copy of CartSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? itemCount = null,Object? subtotal = null,Object? currency = null,Object? hasIssues = null,}) {
  return _then(_self.copyWith(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<CartLine>,itemCount: null == itemCount ? _self.itemCount : itemCount // ignore: cast_nullable_to_non_nullable
as int,subtotal: null == subtotal ? _self.subtotal : subtotal // ignore: cast_nullable_to_non_nullable
as double,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,hasIssues: null == hasIssues ? _self.hasIssues : hasIssues // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [CartSummary].
extension CartSummaryPatterns on CartSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CartSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CartSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CartSummary value)  $default,){
final _that = this;
switch (_that) {
case _CartSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CartSummary value)?  $default,){
final _that = this;
switch (_that) {
case _CartSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<CartLine> items,  int itemCount,  double subtotal,  String currency,  bool hasIssues)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CartSummary() when $default != null:
return $default(_that.items,_that.itemCount,_that.subtotal,_that.currency,_that.hasIssues);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<CartLine> items,  int itemCount,  double subtotal,  String currency,  bool hasIssues)  $default,) {final _that = this;
switch (_that) {
case _CartSummary():
return $default(_that.items,_that.itemCount,_that.subtotal,_that.currency,_that.hasIssues);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<CartLine> items,  int itemCount,  double subtotal,  String currency,  bool hasIssues)?  $default,) {final _that = this;
switch (_that) {
case _CartSummary() when $default != null:
return $default(_that.items,_that.itemCount,_that.subtotal,_that.currency,_that.hasIssues);case _:
  return null;

}
}

}

/// @nodoc


class _CartSummary extends CartSummary {
  const _CartSummary({required final  List<CartLine> items, required this.itemCount, required this.subtotal, required this.currency, required this.hasIssues}): _items = items,super._();
  

 final  List<CartLine> _items;
@override List<CartLine> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override final  int itemCount;
@override final  double subtotal;
@override final  String currency;
@override final  bool hasIssues;

/// Create a copy of CartSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CartSummaryCopyWith<_CartSummary> get copyWith => __$CartSummaryCopyWithImpl<_CartSummary>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CartSummary&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.itemCount, itemCount) || other.itemCount == itemCount)&&(identical(other.subtotal, subtotal) || other.subtotal == subtotal)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.hasIssues, hasIssues) || other.hasIssues == hasIssues));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),itemCount,subtotal,currency,hasIssues);

@override
String toString() {
  return 'CartSummary(items: $items, itemCount: $itemCount, subtotal: $subtotal, currency: $currency, hasIssues: $hasIssues)';
}


}

/// @nodoc
abstract mixin class _$CartSummaryCopyWith<$Res> implements $CartSummaryCopyWith<$Res> {
  factory _$CartSummaryCopyWith(_CartSummary value, $Res Function(_CartSummary) _then) = __$CartSummaryCopyWithImpl;
@override @useResult
$Res call({
 List<CartLine> items, int itemCount, double subtotal, String currency, bool hasIssues
});




}
/// @nodoc
class __$CartSummaryCopyWithImpl<$Res>
    implements _$CartSummaryCopyWith<$Res> {
  __$CartSummaryCopyWithImpl(this._self, this._then);

  final _CartSummary _self;
  final $Res Function(_CartSummary) _then;

/// Create a copy of CartSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? itemCount = null,Object? subtotal = null,Object? currency = null,Object? hasIssues = null,}) {
  return _then(_CartSummary(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<CartLine>,itemCount: null == itemCount ? _self.itemCount : itemCount // ignore: cast_nullable_to_non_nullable
as int,subtotal: null == subtotal ? _self.subtotal : subtotal // ignore: cast_nullable_to_non_nullable
as double,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,hasIssues: null == hasIssues ? _self.hasIssues : hasIssues // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
