import 'package:flutter_test/flutter_test.dart';
import 'package:steam_gallery_app/features/employees/data/models/employee_models.dart';

/// A day's pay is the monthly salary over a 26-day working month.
void main() {
  test('5,200 a month is 200 a day', () {
    expect(dailyRateOf(5200), 200);
  });

  test('raising the daily rate raises the salary', () {
    expect(monthlySalaryOf(220), 5720);
    expect(monthlySalaryOf(dailyRateOf(5200)), 5200);
  });

  test('the payroll preview deducts absence at the 26-day rate', () {
    // The server (0081) still sends salary / 30.
    final p = PayrollPreview.fromRpc({
      'period_month': '2026-10-01',
      'base_salary': 5200,
      'present_days': 22,
      'absent_days': 2,
      'late_days': 0,
      'leave_days': 0,
      'daily_rate': 173.33,
      'absence_deduction': 346.67,
      'advance_balance': 0,
      'already_paid': false,
    });
    expect(p.dailyRate, 200);
    expect(p.absenceDeduction, 400);
  });

  test('the deduction never passes the salary', () {
    final p = PayrollPreview.fromRpc({
      'period_month': '2026-10-01',
      'base_salary': 2600,
      'present_days': 0,
      'absent_days': 30,
      'late_days': 0,
      'leave_days': 0,
      'daily_rate': 0,
      'absence_deduction': 0,
      'advance_balance': 0,
      'already_paid': false,
    });
    expect(p.absenceDeduction, 2600);
  });
}
