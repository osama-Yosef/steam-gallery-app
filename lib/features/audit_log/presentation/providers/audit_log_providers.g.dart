// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audit_log_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(auditLogRepository)
const auditLogRepositoryProvider = AuditLogRepositoryProvider._();

final class AuditLogRepositoryProvider
    extends
        $FunctionalProvider<
          AuditLogRepository,
          AuditLogRepository,
          AuditLogRepository
        >
    with $Provider<AuditLogRepository> {
  const AuditLogRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'auditLogRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$auditLogRepositoryHash();

  @$internal
  @override
  $ProviderElement<AuditLogRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AuditLogRepository create(Ref ref) {
    return auditLogRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuditLogRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuditLogRepository>(value),
    );
  }
}

String _$auditLogRepositoryHash() =>
    r'b5c6af0a2c557ac8411bb4498056f22fe01397a8';

@ProviderFor(auditLogEntries)
const auditLogEntriesProvider = AuditLogEntriesFamily._();

final class AuditLogEntriesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<AuditLogEntry>>,
          List<AuditLogEntry>,
          FutureOr<List<AuditLogEntry>>
        >
    with
        $FutureModifier<List<AuditLogEntry>>,
        $FutureProvider<List<AuditLogEntry>> {
  const AuditLogEntriesProvider._({
    required AuditLogEntriesFamily super.from,
    required ({String? tableName, DateTime? from, DateTime? to}) super.argument,
  }) : super(
         retry: null,
         name: r'auditLogEntriesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$auditLogEntriesHash();

  @override
  String toString() {
    return r'auditLogEntriesProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<AuditLogEntry>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<AuditLogEntry>> create(Ref ref) {
    final argument =
        this.argument as ({String? tableName, DateTime? from, DateTime? to});
    return auditLogEntries(
      ref,
      tableName: argument.tableName,
      from: argument.from,
      to: argument.to,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AuditLogEntriesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$auditLogEntriesHash() => r'134fb6d0a82c096c762fe38394dbc4690132d87f';

final class AuditLogEntriesFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<AuditLogEntry>>,
          ({String? tableName, DateTime? from, DateTime? to})
        > {
  const AuditLogEntriesFamily._()
    : super(
        retry: null,
        name: r'auditLogEntriesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  AuditLogEntriesProvider call({
    String? tableName,
    DateTime? from,
    DateTime? to,
  }) => AuditLogEntriesProvider._(
    argument: (tableName: tableName, from: from, to: to),
    from: this,
  );

  @override
  String toString() => r'auditLogEntriesProvider';
}

@ProviderFor(auditLogTableNames)
const auditLogTableNamesProvider = AuditLogTableNamesProvider._();

final class AuditLogTableNamesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<String>>,
          List<String>,
          FutureOr<List<String>>
        >
    with $FutureModifier<List<String>>, $FutureProvider<List<String>> {
  const AuditLogTableNamesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'auditLogTableNamesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$auditLogTableNamesHash();

  @$internal
  @override
  $FutureProviderElement<List<String>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<String>> create(Ref ref) {
    return auditLogTableNames(ref);
  }
}

String _$auditLogTableNamesHash() =>
    r'f97efb29ef2fedb5167023d0d59b7dd0955d9d93';
