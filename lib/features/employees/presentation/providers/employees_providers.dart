import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/offline/outbox.dart';
import '../../../../core/supabase/supabase_client_provider.dart';
import '../../../../core/utils/provider_cache.dart';
import '../../data/models/employee_models.dart';
import '../../data/repositories/employees_repository.dart';

part 'employees_providers.g.dart';

@Riverpod(keepAlive: true)
EmployeesRepository employeesRepository(Ref ref) {
  return SupabaseEmployeesRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(outboxProvider),
  );
}

@riverpod
Future<List<Employee>> employees(Ref ref) {
  ref.cacheFor();
  ref.refreshOnServerChange();
  return ref.watch(employeesRepositoryProvider).getEmployees();
}

@riverpod
Future<Employee> employee(Ref ref, String id) {
  ref.refreshOnServerChange();
  return ref.watch(employeesRepositoryProvider).getEmployee(id);
}

/// [day] is a date with no time part, so equal days share one provider.
@riverpod
Future<Map<String, AttendanceRecord>> attendanceForDay(Ref ref, DateTime day) {
  ref.refreshOnServerChange();
  return ref.watch(employeesRepositoryProvider).getAttendanceForDay(day);
}

/// [month] is the first day of the month.
@riverpod
Future<List<AttendanceRecord>> employeeAttendance(
  Ref ref,
  String employeeId,
  DateTime month,
) {
  ref.refreshOnServerChange();
  return ref
      .watch(employeesRepositoryProvider)
      .getAttendanceForMonth(employeeId, month);
}

@riverpod
Future<List<EmployeeAdvance>> employeeAdvances(Ref ref, String employeeId) {
  ref.refreshOnServerChange();
  return ref.watch(employeesRepositoryProvider).getAdvances(employeeId);
}

@riverpod
Future<List<EmployeePayroll>> employeePayrolls(Ref ref, String employeeId) {
  ref.refreshOnServerChange();
  return ref.watch(employeesRepositoryProvider).getPayrolls(employeeId);
}
