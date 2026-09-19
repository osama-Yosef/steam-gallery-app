// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'support_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(supportRepository)
const supportRepositoryProvider = SupportRepositoryProvider._();

final class SupportRepositoryProvider
    extends
        $FunctionalProvider<
          SupportRepository,
          SupportRepository,
          SupportRepository
        >
    with $Provider<SupportRepository> {
  const SupportRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'supportRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$supportRepositoryHash();

  @$internal
  @override
  $ProviderElement<SupportRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SupportRepository create(Ref ref) {
    return supportRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SupportRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SupportRepository>(value),
    );
  }
}

String _$supportRepositoryHash() => r'9094229495f098c7f6172100a7dac20a70e5a933';

@ProviderFor(supportWhatsapp)
const supportWhatsappProvider = SupportWhatsappProvider._();

final class SupportWhatsappProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, FutureOr<String?>>
    with $FutureModifier<String?>, $FutureProvider<String?> {
  const SupportWhatsappProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'supportWhatsappProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$supportWhatsappHash();

  @$internal
  @override
  $FutureProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String?> create(Ref ref) {
    return supportWhatsapp(ref);
  }
}

String _$supportWhatsappHash() => r'e5ab82905cafa4cce5fa52a86b06d9e8d3177c36';
