// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'employees_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(employeesRepository)
const employeesRepositoryProvider = EmployeesRepositoryProvider._();

final class EmployeesRepositoryProvider
    extends
        $FunctionalProvider<
          EmployeesRepository,
          EmployeesRepository,
          EmployeesRepository
        >
    with $Provider<EmployeesRepository> {
  const EmployeesRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'employeesRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$employeesRepositoryHash();

  @$internal
  @override
  $ProviderElement<EmployeesRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  EmployeesRepository create(Ref ref) {
    return employeesRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EmployeesRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EmployeesRepository>(value),
    );
  }
}

String _$employeesRepositoryHash() =>
    r'848b9158f1244020c94380cc6b975ee917abafc8';

@ProviderFor(employees)
const employeesProvider = EmployeesProvider._();

final class EmployeesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Employee>>,
          List<Employee>,
          FutureOr<List<Employee>>
        >
    with $FutureModifier<List<Employee>>, $FutureProvider<List<Employee>> {
  const EmployeesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'employeesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$employeesHash();

  @$internal
  @override
  $FutureProviderElement<List<Employee>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Employee>> create(Ref ref) {
    return employees(ref);
  }
}

String _$employeesHash() => r'cb129a0dbf5c33e0306c7bdafcad9825f1ba64be';

@ProviderFor(employee)
const employeeProvider = EmployeeFamily._();

final class EmployeeProvider
    extends
        $FunctionalProvider<AsyncValue<Employee>, Employee, FutureOr<Employee>>
    with $FutureModifier<Employee>, $FutureProvider<Employee> {
  const EmployeeProvider._({
    required EmployeeFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'employeeProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$employeeHash();

  @override
  String toString() {
    return r'employeeProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Employee> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Employee> create(Ref ref) {
    final argument = this.argument as String;
    return employee(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is EmployeeProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$employeeHash() => r'62128baf8740d1373970af59a480bd9940c7b346';

final class EmployeeFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Employee>, String> {
  const EmployeeFamily._()
    : super(
        retry: null,
        name: r'employeeProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  EmployeeProvider call(String id) =>
      EmployeeProvider._(argument: id, from: this);

  @override
  String toString() => r'employeeProvider';
}

/// [day] is a date with no time part, so equal days share one provider.

@ProviderFor(attendanceForDay)
const attendanceForDayProvider = AttendanceForDayFamily._();

/// [day] is a date with no time part, so equal days share one provider.

final class AttendanceForDayProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, AttendanceRecord>>,
          Map<String, AttendanceRecord>,
          FutureOr<Map<String, AttendanceRecord>>
        >
    with
        $FutureModifier<Map<String, AttendanceRecord>>,
        $FutureProvider<Map<String, AttendanceRecord>> {
  /// [day] is a date with no time part, so equal days share one provider.
  const AttendanceForDayProvider._({
    required AttendanceForDayFamily super.from,
    required DateTime super.argument,
  }) : super(
         retry: null,
         name: r'attendanceForDayProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$attendanceForDayHash();

  @override
  String toString() {
    return r'attendanceForDayProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Map<String, AttendanceRecord>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<String, AttendanceRecord>> create(Ref ref) {
    final argument = this.argument as DateTime;
    return attendanceForDay(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is AttendanceForDayProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$attendanceForDayHash() => r'1061ea9cba284e5256f9aa0fed39893781cfe57c';

/// [day] is a date with no time part, so equal days share one provider.

final class AttendanceForDayFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<Map<String, AttendanceRecord>>,
          DateTime
        > {
  const AttendanceForDayFamily._()
    : super(
        retry: null,
        name: r'attendanceForDayProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// [day] is a date with no time part, so equal days share one provider.

  AttendanceForDayProvider call(DateTime day) =>
      AttendanceForDayProvider._(argument: day, from: this);

  @override
  String toString() => r'attendanceForDayProvider';
}

/// [month] is the first day of the month.

@ProviderFor(employeeAttendance)
const employeeAttendanceProvider = EmployeeAttendanceFamily._();

/// [month] is the first day of the month.

final class EmployeeAttendanceProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<AttendanceRecord>>,
          List<AttendanceRecord>,
          FutureOr<List<AttendanceRecord>>
        >
    with
        $FutureModifier<List<AttendanceRecord>>,
        $FutureProvider<List<AttendanceRecord>> {
  /// [month] is the first day of the month.
  const EmployeeAttendanceProvider._({
    required EmployeeAttendanceFamily super.from,
    required (String, DateTime) super.argument,
  }) : super(
         retry: null,
         name: r'employeeAttendanceProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$employeeAttendanceHash();

  @override
  String toString() {
    return r'employeeAttendanceProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<AttendanceRecord>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<AttendanceRecord>> create(Ref ref) {
    final argument = this.argument as (String, DateTime);
    return employeeAttendance(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is EmployeeAttendanceProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$employeeAttendanceHash() =>
    r'4446d783c7da6788be26dfced410953b0f771110';

/// [month] is the first day of the month.

final class EmployeeAttendanceFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<AttendanceRecord>>,
          (String, DateTime)
        > {
  const EmployeeAttendanceFamily._()
    : super(
        retry: null,
        name: r'employeeAttendanceProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// [month] is the first day of the month.

  EmployeeAttendanceProvider call(String employeeId, DateTime month) =>
      EmployeeAttendanceProvider._(argument: (employeeId, month), from: this);

  @override
  String toString() => r'employeeAttendanceProvider';
}

@ProviderFor(employeeAdvances)
const employeeAdvancesProvider = EmployeeAdvancesFamily._();

final class EmployeeAdvancesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<EmployeeAdvance>>,
          List<EmployeeAdvance>,
          FutureOr<List<EmployeeAdvance>>
        >
    with
        $FutureModifier<List<EmployeeAdvance>>,
        $FutureProvider<List<EmployeeAdvance>> {
  const EmployeeAdvancesProvider._({
    required EmployeeAdvancesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'employeeAdvancesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$employeeAdvancesHash();

  @override
  String toString() {
    return r'employeeAdvancesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<EmployeeAdvance>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<EmployeeAdvance>> create(Ref ref) {
    final argument = this.argument as String;
    return employeeAdvances(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is EmployeeAdvancesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$employeeAdvancesHash() => r'f62d0b84e37fc69da99935a67a0f57546ec47b5d';

final class EmployeeAdvancesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<EmployeeAdvance>>, String> {
  const EmployeeAdvancesFamily._()
    : super(
        retry: null,
        name: r'employeeAdvancesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  EmployeeAdvancesProvider call(String employeeId) =>
      EmployeeAdvancesProvider._(argument: employeeId, from: this);

  @override
  String toString() => r'employeeAdvancesProvider';
}

@ProviderFor(employeePayrolls)
const employeePayrollsProvider = EmployeePayrollsFamily._();

final class EmployeePayrollsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<EmployeePayroll>>,
          List<EmployeePayroll>,
          FutureOr<List<EmployeePayroll>>
        >
    with
        $FutureModifier<List<EmployeePayroll>>,
        $FutureProvider<List<EmployeePayroll>> {
  const EmployeePayrollsProvider._({
    required EmployeePayrollsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'employeePayrollsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$employeePayrollsHash();

  @override
  String toString() {
    return r'employeePayrollsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<EmployeePayroll>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<EmployeePayroll>> create(Ref ref) {
    final argument = this.argument as String;
    return employeePayrolls(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is EmployeePayrollsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$employeePayrollsHash() => r'9f61e91b0d1aac3429d08236ff82271efe0dc22e';

final class EmployeePayrollsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<EmployeePayroll>>, String> {
  const EmployeePayrollsFamily._()
    : super(
        retry: null,
        name: r'employeePayrollsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  EmployeePayrollsProvider call(String employeeId) =>
      EmployeePayrollsProvider._(argument: employeeId, from: this);

  @override
  String toString() => r'employeePayrollsProvider';
}
