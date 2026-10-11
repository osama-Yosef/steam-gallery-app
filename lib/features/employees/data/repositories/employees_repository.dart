import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/offline/outbox.dart';
import '../../../../core/utils/formatters.dart';
import '../../../cashbox/data/models/cashbox_balance.dart';
import '../models/employee_models.dart';

String _day(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime _monthStart(DateTime d) => DateTime(d.year, d.month);

/// Staff, attendance, advances and salary payments (0081). Admin only.
abstract class EmployeesRepository {
  Future<List<Employee>> getEmployees();

  Future<Employee> getEmployee(String id);

  /// Creates the employee when [id] is null, otherwise updates it.
  Future<void> saveEmployee({
    String? id,
    required String fullName,
    String? phone,
    String? jobTitle,
    required double monthlySalary,
    DateTime? hireDate,
    String? notes,
    bool isActive = true,
  });

  /// Every employee's mark for [day], keyed by employee id.
  Future<Map<String, AttendanceRecord>> getAttendanceForDay(DateTime day);

  /// One employee's marks in the month containing [month].
  Future<List<AttendanceRecord>> getAttendanceForMonth(
    String employeeId,
    DateTime month,
  );

  /// Saves [marks] for [day] (one per employee, replacing an earlier one);
  /// employees in [cleared] lose their mark for that day.
  Future<void> saveAttendance(
    DateTime day,
    Map<String, AttendanceStatus> marks, {
    Set<String> cleared = const {},
  });

  Future<List<EmployeeAdvance>> getAdvances(String employeeId);

  Future<List<EmployeePayroll>> getPayrolls(String employeeId);

  /// Money out of [kind] now, owed back by the employee. Queued offline.
  Future<OutboxResult> giveAdvance({
    required String employeeId,
    required String employeeName,
    required double amount,
    required DateTime date,
    required CashboxKind kind,
    String? notes,
  });

  Future<PayrollPreview> payrollPreview(String employeeId, DateTime month);

  /// Pays [month]: (salary - absenceDeduction + bonus) is the expense,
  /// that minus [advanceDeduction] leaves [kind] now. Queued offline; a
  /// month is never paid twice.
  Future<OutboxResult> paySalary({
    required String employeeId,
    required String employeeName,
    required DateTime month,
    required double absenceDeduction,
    required double bonus,
    required double advanceDeduction,
    required CashboxKind kind,
    String? notes,
  });
}

class SupabaseEmployeesRepository implements EmployeesRepository {
  final SupabaseClient _client;
  final Outbox _outbox;
  SupabaseEmployeesRepository(this._client, this._outbox);

  @override
  Future<List<Employee>> getEmployees() async {
    try {
      final rows = await _client
          .from('employee_balances')
          .select()
          .order('is_active', ascending: false)
          .order('full_name');
      return rows.map(Employee.fromRow).toList();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<Employee> getEmployee(String id) async {
    try {
      final row = await _client
          .from('employee_balances')
          .select()
          .eq('employee_id', id)
          .single();
      return Employee.fromRow(row);
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<void> saveEmployee({
    String? id,
    required String fullName,
    String? phone,
    String? jobTitle,
    required double monthlySalary,
    DateTime? hireDate,
    String? notes,
    bool isActive = true,
  }) async {
    final row = {
      'full_name': fullName,
      'phone': phone,
      'job_title': jobTitle,
      'monthly_salary': monthlySalary,
      'hire_date': hireDate == null ? null : _day(hireDate),
      'notes': notes,
      'is_active': isActive,
    };
    try {
      if (id == null) {
        await _client.from('employees').insert(row);
      } else {
        await _client.from('employees').update(row).eq('id', id);
      }
      _outbox.markServerChanged();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<Map<String, AttendanceRecord>> getAttendanceForDay(
    DateTime day,
  ) async {
    try {
      final rows = await _client
          .from('employee_attendance')
          .select()
          .eq('work_date', _day(day));
      return {
        for (final r in rows.map(AttendanceRecord.fromRow)) r.employeeId: r,
      };
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<List<AttendanceRecord>> getAttendanceForMonth(
    String employeeId,
    DateTime month,
  ) async {
    final start = _monthStart(month);
    final end = DateTime(start.year, start.month + 1);
    try {
      final rows = await _client
          .from('employee_attendance')
          .select()
          .eq('employee_id', employeeId)
          .gte('work_date', _day(start))
          .lt('work_date', _day(end))
          .order('work_date');
      return rows.map(AttendanceRecord.fromRow).toList();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<void> saveAttendance(
    DateTime day,
    Map<String, AttendanceStatus> marks, {
    Set<String> cleared = const {},
  }) async {
    try {
      if (marks.isNotEmpty) {
        await _client.from('employee_attendance').upsert([
          for (final e in marks.entries)
            {
              'employee_id': e.key,
              'work_date': _day(day),
              'status': attendanceStatusToString(e.value),
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            },
        ], onConflict: 'employee_id,work_date');
      }
      if (cleared.isNotEmpty) {
        await _client
            .from('employee_attendance')
            .delete()
            .eq('work_date', _day(day))
            .inFilter('employee_id', cleared.toList());
      }
      _outbox.markServerChanged();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<List<EmployeeAdvance>> getAdvances(String employeeId) async {
    try {
      final rows = await _client
          .from('employee_advances')
          .select()
          .eq('employee_id', employeeId)
          .order('advance_date', ascending: false)
          .order('advance_number', ascending: false);
      return rows.map(EmployeeAdvance.fromRow).toList();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<List<EmployeePayroll>> getPayrolls(String employeeId) async {
    try {
      final rows = await _client
          .from('employee_payrolls')
          .select()
          .eq('employee_id', employeeId)
          .order('period_month', ascending: false);
      return rows.map(EmployeePayroll.fromRow).toList();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<OutboxResult> giveAdvance({
    required String employeeId,
    required String employeeName,
    required double amount,
    required DateTime date,
    required CashboxKind kind,
    String? notes,
  }) => _outbox.submit(
    rpc: 'rpc_employee_advance',
    params: {
      'p_employee_id': employeeId,
      'p_amount': amount,
      'p_advance_date': _day(date),
      'p_kind': cashboxKindToString(kind),
      'p_notes': notes,
    },
    label: 'سلفة ${Formatters.currency(amount)} · $employeeName',
    kind: 'cashbox',
    viaReplay: true,
  );

  @override
  Future<PayrollPreview> payrollPreview(
    String employeeId,
    DateTime month,
  ) async {
    try {
      final res = await _client.rpc(
        'rpc_payroll_preview',
        params: {'p_employee_id': employeeId, 'p_month': _day(month)},
      );
      return PayrollPreview.fromRpc((res as Map).cast<String, dynamic>());
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<OutboxResult> paySalary({
    required String employeeId,
    required String employeeName,
    required DateTime month,
    required double absenceDeduction,
    required double bonus,
    required double advanceDeduction,
    required CashboxKind kind,
    String? notes,
  }) => _outbox.submit(
    rpc: 'rpc_pay_salary',
    params: {
      'p_employee_id': employeeId,
      'p_month': _day(_monthStart(month)),
      'p_absence_deduction': absenceDeduction,
      'p_bonus': bonus,
      'p_advance_deduction': advanceDeduction,
      'p_kind': cashboxKindToString(kind),
      'p_notes': notes,
    },
    label: 'مرتب $employeeName · ${Formatters.month(month)}',
    kind: 'cashbox',
    viaReplay: true,
  );
}
