// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'storefront_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(storefrontRepository)
const storefrontRepositoryProvider = StorefrontRepositoryProvider._();

final class StorefrontRepositoryProvider
    extends
        $FunctionalProvider<
          StorefrontRepository,
          StorefrontRepository,
          StorefrontRepository
        >
    with $Provider<StorefrontRepository> {
  const StorefrontRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'storefrontRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$storefrontRepositoryHash();

  @$internal
  @override
  $ProviderElement<StorefrontRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  StorefrontRepository create(Ref ref) {
    return storefrontRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StorefrontRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StorefrontRepository>(value),
    );
  }
}

String _$storefrontRepositoryHash() =>
    r'2375cceabb48f918a4ddce3093f19af4fa01738e';

@ProviderFor(customerHome)
const customerHomeProvider = CustomerHomeProvider._();

final class CustomerHomeProvider
    extends
        $FunctionalProvider<
          AsyncValue<CustomerHomeData>,
          CustomerHomeData,
          FutureOr<CustomerHomeData>
        >
    with $FutureModifier<CustomerHomeData>, $FutureProvider<CustomerHomeData> {
  const CustomerHomeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'customerHomeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$customerHomeHash();

  @$internal
  @override
  $FutureProviderElement<CustomerHomeData> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CustomerHomeData> create(Ref ref) {
    return customerHome(ref);
  }
}

String _$customerHomeHash() => r'7091d0564882a746c0bd0db24869d2364c83da2d';

@ProviderFor(offerDetail)
const offerDetailProvider = OfferDetailFamily._();

final class OfferDetailProvider
    extends $FunctionalProvider<AsyncValue<Offer?>, Offer?, FutureOr<Offer?>>
    with $FutureModifier<Offer?>, $FutureProvider<Offer?> {
  const OfferDetailProvider._({
    required OfferDetailFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'offerDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$offerDetailHash();

  @override
  String toString() {
    return r'offerDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Offer?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Offer?> create(Ref ref) {
    final argument = this.argument as String;
    return offerDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is OfferDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$offerDetailHash() => r'f3b21032c9a9ccc79464532e33563964f1208bd8';

final class OfferDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Offer?>, String> {
  const OfferDetailFamily._()
    : super(
        retry: null,
        name: r'offerDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  OfferDetailProvider call(String offerId) =>
      OfferDetailProvider._(argument: offerId, from: this);

  @override
  String toString() => r'offerDetailProvider';
}

@ProviderFor(offerProducts)
const offerProductsProvider = OfferProductsFamily._();

final class OfferProductsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ProductPublic>>,
          List<ProductPublic>,
          FutureOr<List<ProductPublic>>
        >
    with
        $FutureModifier<List<ProductPublic>>,
        $FutureProvider<List<ProductPublic>> {
  const OfferProductsProvider._({
    required OfferProductsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'offerProductsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$offerProductsHash();

  @override
  String toString() {
    return r'offerProductsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<ProductPublic>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ProductPublic>> create(Ref ref) {
    final argument = this.argument as String;
    return offerProducts(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is OfferProductsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$offerProductsHash() => r'6efe8b0b201e5240539c345d03238ed6b82a9878';

final class OfferProductsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<ProductPublic>>, String> {
  const OfferProductsFamily._()
    : super(
        retry: null,
        name: r'offerProductsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  OfferProductsProvider call(String offerId) =>
      OfferProductsProvider._(argument: offerId, from: this);

  @override
  String toString() => r'offerProductsProvider';
}

@ProviderFor(adminBanners)
const adminBannersProvider = AdminBannersProvider._();

final class AdminBannersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<HomeBanner>>,
          List<HomeBanner>,
          FutureOr<List<HomeBanner>>
        >
    with $FutureModifier<List<HomeBanner>>, $FutureProvider<List<HomeBanner>> {
  const AdminBannersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adminBannersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adminBannersHash();

  @$internal
  @override
  $FutureProviderElement<List<HomeBanner>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<HomeBanner>> create(Ref ref) {
    return adminBanners(ref);
  }
}

String _$adminBannersHash() => r'1c5a571280bca20ddcc3af028d8671e1b039d253';

@ProviderFor(adminOffers)
const adminOffersProvider = AdminOffersProvider._();

final class AdminOffersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Offer>>,
          List<Offer>,
          FutureOr<List<Offer>>
        >
    with $FutureModifier<List<Offer>>, $FutureProvider<List<Offer>> {
  const AdminOffersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adminOffersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adminOffersHash();

  @$internal
  @override
  $FutureProviderElement<List<Offer>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Offer>> create(Ref ref) {
    return adminOffers(ref);
  }
}

String _$adminOffersHash() => r'57f6f27c294fe3fb21d893e2525794194b4b7087';
