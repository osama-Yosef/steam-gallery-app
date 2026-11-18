// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'outbox.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The app's [Outbox]. main() creates and starts it before the app runs and
/// provides it by overriding this; tests override it with an [Outbox] wired
/// to a fake server.

@ProviderFor(outbox)
const outboxProvider = OutboxProvider._();

/// The app's [Outbox]. main() creates and starts it before the app runs and
/// provides it by overriding this; tests override it with an [Outbox] wired
/// to a fake server.

final class OutboxProvider extends $FunctionalProvider<Outbox, Outbox, Outbox>
    with $Provider<Outbox> {
  /// The app's [Outbox]. main() creates and starts it before the app runs and
  /// provides it by overriding this; tests override it with an [Outbox] wired
  /// to a fake server.
  const OutboxProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'outboxProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$outboxHash();

  @$internal
  @override
  $ProviderElement<Outbox> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Outbox create(Ref ref) {
    return outbox(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Outbox value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Outbox>(value),
    );
  }
}

String _$outboxHash() => r'af1c0a934602274bd5d57d3065b817c13686abeb';

/// The device store opened in main(), for data that must outlive the HTTP
/// cache (the signed-in profile). Null in tests and when Supabase isn't
/// configured; callers then simply don't keep anything.

@ProviderFor(offlineStore)
const offlineStoreProvider = OfflineStoreProvider._();

/// The device store opened in main(), for data that must outlive the HTTP
/// cache (the signed-in profile). Null in tests and when Supabase isn't
/// configured; callers then simply don't keep anything.

final class OfflineStoreProvider
    extends $FunctionalProvider<OfflineStore?, OfflineStore?, OfflineStore?>
    with $Provider<OfflineStore?> {
  /// The device store opened in main(), for data that must outlive the HTTP
  /// cache (the signed-in profile). Null in tests and when Supabase isn't
  /// configured; callers then simply don't keep anything.
  const OfflineStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'offlineStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$offlineStoreHash();

  @$internal
  @override
  $ProviderElement<OfflineStore?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  OfflineStore? create(Ref ref) {
    return offlineStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OfflineStore? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OfflineStore?>(value),
    );
  }
}

String _$offlineStoreHash() => r'73b805e30817d41f2e3bad55fbdb4ce16ea24cb0';
