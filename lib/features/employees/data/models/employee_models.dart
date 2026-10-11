import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../cashbox/data/models/cashbox_balance.dart';

part 'employee_models.freezed.dart';

DateTime? _date(Object? v) => v == null ? null : DateTime.parse(v as String);
double _num(Object? v) => (v as num?)?.toDouble() ?? 0;

/// A member of the shop's staff (0081) — not an app user, no login. Read
/// from the employee_balances view, so it carries the advance balance too.
@freezed
abstract class Employee with _$Employee {
  const factory Employee({
    required String id,
    required String fullName,
    String? phone,
    String? jobTitle,
    required double monthlySalary,
    DateTime? hireDate,
    String? notes,
    required bool isActive,

    /// Advances given minus advances already deducted from salaries — what
    /// the employee still owes the shop.
    @Default(0) double advanceBalance,
    DateTime? lastPaidMonth,
  }) = _Employee;

  factory Employee.fromRow(Map<String, dynamic> row) => Employee(
    id: (row['employee_id'] ?? row['id']) as String,
    fullName: row['full_name'] as String,
    phone: row['phone'] as String?,
    jobTitle: row['job_title'] as String?,
    monthlySalary: _num(row['monthly_salary']),
    hireDate: _date(row['hire_date']),
    notes: row['notes'] as String?,
    isActive: row['is_active'] as bool? ?? true,
    advanceBalance: _num(row['advance_balance']),
    lastPaidMonth: _date(row['last_paid_month']),
  );
}

enum AttendanceStatus { present, absent, late, leave }

AttendanceStatus attendanceStatusFromString(String v) => switch (v) {
  'absent' => AttendanceStatus.absent,
  'late' => AttendanceStatus.late,
  'leave' => AttendanceStatus.leave,
  _ => AttendanceStatus.present,
};

String attendanceStatusToString(AttendanceStatus s) => switch (s) {
  AttendanceStatus.present => 'present',
  AttendanceStatus.absent => 'absent',
  AttendanceStatus.late => 'late',
  AttendanceStatus.leave => 'leave',
};

String attendanceStatusLabelAr(AttendanceStatus s) => switch (s) {
  AttendanceStatus.present => 'حاضر',
  AttendanceStatus.absent => 'غائب',
  AttendanceStatus.late => 'متأخر',
  AttendanceStatus.leave => 'إجازة',
};

@freezed
abstract class AttendanceRecord with _$AttendanceRecord {
  const factory AttendanceRecord({
    required String employeeId,
    required DateTime workDate,
    required AttendanceStatus status,
    String? notes,
  }) = _AttendanceRecord;

  factory AttendanceRecord.fromRow(Map<String, dynamic> row) =>
      AttendanceRecord(
        employeeId: row['employee_id'] as String,
        workDate: DateTime.parse(row['work_date'] as String),
        status: attendanceStatusFromString(row['status'] as String),
        notes: row['notes'] as String?,
      );
}

@freezed
abstract class EmployeeAdvance with _$EmployeeAdvance {
  const factory EmployeeAdvance({
    required String id,
    required int advanceNumber,
    required double amount,
    required DateTime advanceDate,
    required CashboxKind kind,
    String? notes,
  }) = _EmployeeAdvance;

  factory EmployeeAdvance.fromRow(Map<String, dynamic> row) => EmployeeAdvance(
    id: row['id'] as String,
    advanceNumber: row['advance_number'] as int,
    amount: _num(row['amount']),
    advanceDate: DateTime.parse(row['advance_date'] as String),
    kind: cashboxKindFromString(row['kind'] as String),
    notes: row['notes'] as String?,
  );
}

@freezed
abstract class EmployeePayroll with _$EmployeePayroll {
  const factory EmployeePayroll({
    required String id,
    required int payrollNumber,
    required DateTime periodMonth,
    required double baseSalary,
    required int absentDays,
    required double absenceDeduction,
    required double bonus,
    required double advanceDeduction,
    required double netAmount,
    required CashboxKind kind,
    String? notes,
    required DateTime createdAt,
  }) = _EmployeePayroll;

  const EmployeePayroll._();

  /// What the month cost the shop — the expense booked under "مرتبات".
  double get earned => baseSalary - absenceDeduction + bonus;

  factory EmployeePayroll.fromRow(Map<String, dynamic> row) => EmployeePayroll(
    id: row['id'] as String,
    payrollNumber: row['payroll_number'] as int,
    periodMonth: DateTime.parse(row['period_month'] as String),
    baseSalary: _num(row['base_salary']),
    absentDays: row['absent_days'] as int,
    absenceDeduction: _num(row['absence_deduction']),
    bonus: _num(row['bonus']),
    advanceDeduction: _num(row['advance_deduction']),
    netAmount: _num(row['net_amount']),
    kind: cashboxKindFromString(row['kind'] as String),
    notes: row['notes'] as String?,
    createdAt: DateTime.parse(row['created_at'] as String),
  );
}

/// rpc_payroll_preview: the month's attendance and the suggested figures
/// for paying it.
@freezed
abstract class PayrollPreview with _$PayrollPreview {
  const factory PayrollPreview({
    required DateTime periodMonth,
    required double baseSalary,
    required int presentDays,
    required int absentDays,
    required int lateDays,
    required int leaveDays,
    required double dailyRate,
    required double absenceDeduction,
    required double advanceBalance,
    required bool alreadyPaid,
  }) = _PayrollPreview;

  factory PayrollPreview.fromRpc(Map<String, dynamic> j) => PayrollPreview(
    periodMonth: DateTime.parse(j['period_month'] as String),
    baseSalary: _num(j['base_salary']),
    presentDays: (j['present_days'] as num).toInt(),
    absentDays: (j['absent_days'] as num).toInt(),
    lateDays: (j['late_days'] as num).toInt(),
    leaveDays: (j['leave_days'] as num).toInt(),
    dailyRate: _num(j['daily_rate']),
    absenceDeduction: _num(j['absence_deduction']),
    advanceBalance: _num(j['advance_balance']),
    alreadyPaid: j['already_paid'] as bool,
  );
}
