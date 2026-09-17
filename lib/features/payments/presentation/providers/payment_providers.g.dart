// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(paymentRepository)
const paymentRepositoryProvider = PaymentRepositoryProvider._();

final class PaymentRepositoryProvider
    extends
        $FunctionalProvider<
          PaymentRepository,
          PaymentRepository,
          PaymentRepository
        >
    with $Provider<PaymentRepository> {
  const PaymentRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'paymentRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$paymentRepositoryHash();

  @$internal
  @override
  $ProviderElement<PaymentRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PaymentRepository create(Ref ref) {
    return paymentRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PaymentRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PaymentRepository>(value),
    );
  }
}

String _$paymentRepositoryHash() => r'48fa88f0792ceebc763bdfa6398195b905f2c9c6';

@ProviderFor(instapayDetails)
const instapayDetailsProvider = InstapayDetailsProvider._();

final class InstapayDetailsProvider
    extends
        $FunctionalProvider<
          AsyncValue<InstapayDetails>,
          InstapayDetails,
          FutureOr<InstapayDetails>
        >
    with $FutureModifier<InstapayDetails>, $FutureProvider<InstapayDetails> {
  const InstapayDetailsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'instapayDetailsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$instapayDetailsHash();

  @$internal
  @override
  $FutureProviderElement<InstapayDetails> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<InstapayDetails> create(Ref ref) {
    return instapayDetails(ref);
  }
}

String _$instapayDetailsHash() => r'4333de2dce0b10c0730f03c8d8ccc123722ea304';

@ProviderFor(myPayments)
const myPaymentsProvider = MyPaymentsProvider._();

final class MyPaymentsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PaymentRecord>>,
          List<PaymentRecord>,
          FutureOr<List<PaymentRecord>>
        >
    with
        $FutureModifier<List<PaymentRecord>>,
        $FutureProvider<List<PaymentRecord>> {
  const MyPaymentsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myPaymentsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myPaymentsHash();

  @$internal
  @override
  $FutureProviderElement<List<PaymentRecord>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<PaymentRecord>> create(Ref ref) {
    return myPayments(ref);
  }
}

String _$myPaymentsHash() => r'4c9cad66d78427eb44c0960e15abba7de82316cc';

/// Admin review queue.

@ProviderFor(pendingInstapaySubmissions)
const pendingInstapaySubmissionsProvider =
    PendingInstapaySubmissionsProvider._();

/// Admin review queue.

final class PendingInstapaySubmissionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PaymentRecord>>,
          List<PaymentRecord>,
          FutureOr<List<PaymentRecord>>
        >
    with
        $FutureModifier<List<PaymentRecord>>,
        $FutureProvider<List<PaymentRecord>> {
  /// Admin review queue.
  const PendingInstapaySubmissionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingInstapaySubmissionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingInstapaySubmissionsHash();

  @$internal
  @override
  $FutureProviderElement<List<PaymentRecord>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<PaymentRecord>> create(Ref ref) {
    return pendingInstapaySubmissions(ref);
  }
}

String _$pendingInstapaySubmissionsHash() =>
    r'6edc2940ca4b1c79b21b58ad5cd1a3db86c0af25';
