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
