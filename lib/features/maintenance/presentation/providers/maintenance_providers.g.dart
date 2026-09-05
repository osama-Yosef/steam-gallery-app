// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'maintenance_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(maintenanceRepository)
const maintenanceRepositoryProvider = MaintenanceRepositoryProvider._();

final class MaintenanceRepositoryProvider
    extends
        $FunctionalProvider<
          MaintenanceRepository,
          MaintenanceRepository,
          MaintenanceRepository
        >
    with $Provider<MaintenanceRepository> {
  const MaintenanceRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'maintenanceRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$maintenanceRepositoryHash();

  @$internal
  @override
  $ProviderElement<MaintenanceRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MaintenanceRepository create(Ref ref) {
    return maintenanceRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MaintenanceRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MaintenanceRepository>(value),
    );
  }
}

String _$maintenanceRepositoryHash() =>
    r'076033b90afc6df17783a7b4e796883ce0b8c95a';

@ProviderFor(myMaintenanceRequests)
const myMaintenanceRequestsProvider = MyMaintenanceRequestsFamily._();

final class MyMaintenanceRequestsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MaintenanceRequest>>,
          List<MaintenanceRequest>,
          Stream<List<MaintenanceRequest>>
        >
    with
        $FutureModifier<List<MaintenanceRequest>>,
        $StreamProvider<List<MaintenanceRequest>> {
  const MyMaintenanceRequestsProvider._({
    required MyMaintenanceRequestsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'myMaintenanceRequestsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$myMaintenanceRequestsHash();

  @override
  String toString() {
    return r'myMaintenanceRequestsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<MaintenanceRequest>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<MaintenanceRequest>> create(Ref ref) {
    final argument = this.argument as String;
    return myMaintenanceRequests(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is MyMaintenanceRequestsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$myMaintenanceRequestsHash() =>
    r'52b283caf1bba6c62dc21aea3c76db6c9d3f8b9d';

final class MyMaintenanceRequestsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<MaintenanceRequest>>, String> {
  const MyMaintenanceRequestsFamily._()
    : super(
        retry: null,
        name: r'myMaintenanceRequestsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  MyMaintenanceRequestsProvider call(String customerId) =>
      MyMaintenanceRequestsProvider._(argument: customerId, from: this);

  @override
  String toString() => r'myMaintenanceRequestsProvider';
}

@ProviderFor(maintenanceRequestDetail)
const maintenanceRequestDetailProvider = MaintenanceRequestDetailFamily._();

final class MaintenanceRequestDetailProvider
    extends
        $FunctionalProvider<
          AsyncValue<MaintenanceRequest?>,
          MaintenanceRequest?,
          Stream<MaintenanceRequest?>
        >
    with
        $FutureModifier<MaintenanceRequest?>,
        $StreamProvider<MaintenanceRequest?> {
  const MaintenanceRequestDetailProvider._({
    required MaintenanceRequestDetailFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'maintenanceRequestDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$maintenanceRequestDetailHash();

  @override
  String toString() {
    return r'maintenanceRequestDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<MaintenanceRequest?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<MaintenanceRequest?> create(Ref ref) {
    final argument = this.argument as String;
    return maintenanceRequestDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is MaintenanceRequestDetailProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$maintenanceRequestDetailHash() =>
    r'fc11408176015a5b7c203f54a5c6d0da69e3608e';

final class MaintenanceRequestDetailFamily extends $Family
    with $FunctionalFamilyOverride<Stream<MaintenanceRequest?>, String> {
  const MaintenanceRequestDetailFamily._()
    : super(
        retry: null,
        name: r'maintenanceRequestDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  MaintenanceRequestDetailProvider call(String requestId) =>
      MaintenanceRequestDetailProvider._(argument: requestId, from: this);

  @override
  String toString() => r'maintenanceRequestDetailProvider';
}

/// Raw RLS-scoped stream every queue screen (technician/admin) derives its
/// sorted "active" list from client-side — see repository doc comment.

@ProviderFor(visibleMaintenanceRequests)
const visibleMaintenanceRequestsProvider =
    VisibleMaintenanceRequestsProvider._();

/// Raw RLS-scoped stream every queue screen (technician/admin) derives its
/// sorted "active" list from client-side — see repository doc comment.

final class VisibleMaintenanceRequestsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MaintenanceRequest>>,
          List<MaintenanceRequest>,
          Stream<List<MaintenanceRequest>>
        >
    with
        $FutureModifier<List<MaintenanceRequest>>,
        $StreamProvider<List<MaintenanceRequest>> {
  /// Raw RLS-scoped stream every queue screen (technician/admin) derives its
  /// sorted "active" list from client-side — see repository doc comment.
  const VisibleMaintenanceRequestsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'visibleMaintenanceRequestsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$visibleMaintenanceRequestsHash();

  @$internal
  @override
  $StreamProviderElement<List<MaintenanceRequest>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<MaintenanceRequest>> create(Ref ref) {
    return visibleMaintenanceRequests(ref);
  }
}

String _$visibleMaintenanceRequestsHash() =>
    r'08923b297b312cae0d2c987be33b4f4a26787660';

@ProviderFor(myQueuePosition)
const myQueuePositionProvider = MyQueuePositionFamily._();

final class MyQueuePositionProvider
    extends
        $FunctionalProvider<
          AsyncValue<QueuePosition>,
          QueuePosition,
          FutureOr<QueuePosition>
        >
    with $FutureModifier<QueuePosition>, $FutureProvider<QueuePosition> {
  const MyQueuePositionProvider._({
    required MyQueuePositionFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'myQueuePositionProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$myQueuePositionHash();

  @override
  String toString() {
    return r'myQueuePositionProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<QueuePosition> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<QueuePosition> create(Ref ref) {
    final argument = this.argument as String;
    return myQueuePosition(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is MyQueuePositionProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$myQueuePositionHash() => r'8425c03fb12c02aec409aff8efffba69c809838f';

final class MyQueuePositionFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<QueuePosition>, String> {
  const MyQueuePositionFamily._()
    : super(
        retry: null,
        name: r'myQueuePositionProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  MyQueuePositionProvider call(String requestId) =>
      MyQueuePositionProvider._(argument: requestId, from: this);

  @override
  String toString() => r'myQueuePositionProvider';
}

@ProviderFor(maintenanceImages)
const maintenanceImagesProvider = MaintenanceImagesFamily._();

final class MaintenanceImagesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MaintenanceImage>>,
          List<MaintenanceImage>,
          FutureOr<List<MaintenanceImage>>
        >
    with
        $FutureModifier<List<MaintenanceImage>>,
        $FutureProvider<List<MaintenanceImage>> {
  const MaintenanceImagesProvider._({
    required MaintenanceImagesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'maintenanceImagesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$maintenanceImagesHash();

  @override
  String toString() {
    return r'maintenanceImagesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<MaintenanceImage>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<MaintenanceImage>> create(Ref ref) {
    final argument = this.argument as String;
    return maintenanceImages(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is MaintenanceImagesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$maintenanceImagesHash() => r'bfe418e9ad0ad9599b8745921181e8f66d0787e5';

final class MaintenanceImagesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<MaintenanceImage>>, String> {
  const MaintenanceImagesFamily._()
    : super(
        retry: null,
        name: r'maintenanceImagesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  MaintenanceImagesProvider call(String requestId) =>
      MaintenanceImagesProvider._(argument: requestId, from: this);

  @override
  String toString() => r'maintenanceImagesProvider';
}

/// Signed, time-limited URL for one stored maintenance image. The bucket is
/// private, so this is the only way the image can actually render.

@ProviderFor(maintenanceImageUrl)
const maintenanceImageUrlProvider = MaintenanceImageUrlFamily._();

/// Signed, time-limited URL for one stored maintenance image. The bucket is
/// private, so this is the only way the image can actually render.

final class MaintenanceImageUrlProvider
    extends $FunctionalProvider<AsyncValue<String>, String, FutureOr<String>>
    with $FutureModifier<String>, $FutureProvider<String> {
  /// Signed, time-limited URL for one stored maintenance image. The bucket is
  /// private, so this is the only way the image can actually render.
  const MaintenanceImageUrlProvider._({
    required MaintenanceImageUrlFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'maintenanceImageUrlProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$maintenanceImageUrlHash();

  @override
  String toString() {
    return r'maintenanceImageUrlProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<String> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String> create(Ref ref) {
    final argument = this.argument as String;
    return maintenanceImageUrl(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is MaintenanceImageUrlProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$maintenanceImageUrlHash() =>
    r'e82975ca622639d2654236f12d028eb8997b5ce2';

/// Signed, time-limited URL for one stored maintenance image. The bucket is
/// private, so this is the only way the image can actually render.

final class MaintenanceImageUrlFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<String>, String> {
  const MaintenanceImageUrlFamily._()
    : super(
        retry: null,
        name: r'maintenanceImageUrlProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Signed, time-limited URL for one stored maintenance image. The bucket is
  /// private, so this is the only way the image can actually render.

  MaintenanceImageUrlProvider call(String storedPathOrUrl) =>
      MaintenanceImageUrlProvider._(argument: storedPathOrUrl, from: this);

  @override
  String toString() => r'maintenanceImageUrlProvider';
}

@ProviderFor(assignableTechnicians)
const assignableTechniciansProvider = AssignableTechniciansProvider._();

final class AssignableTechniciansProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<TechnicianOption>>,
          List<TechnicianOption>,
          FutureOr<List<TechnicianOption>>
        >
    with
        $FutureModifier<List<TechnicianOption>>,
        $FutureProvider<List<TechnicianOption>> {
  const AssignableTechniciansProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'assignableTechniciansProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$assignableTechniciansHash();

  @$internal
  @override
  $FutureProviderElement<List<TechnicianOption>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<TechnicianOption>> create(Ref ref) {
    return assignableTechnicians(ref);
  }
}

String _$assignableTechniciansHash() =>
    r'3b07d7ee25c7aefad6f8e269343877b4783bbd9f';
