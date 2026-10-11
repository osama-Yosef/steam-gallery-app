import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:steam_gallery_app/core/offline/outbox.dart';
import 'package:steam_gallery_app/core/theme/app_theme.dart';
import 'package:steam_gallery_app/core/utils/formatters.dart';
import 'package:steam_gallery_app/features/cashbox/data/models/cashbox_balance.dart';
import 'package:steam_gallery_app/features/cashbox/data/models/expense_category.dart';
import 'package:steam_gallery_app/features/cashbox/data/repositories/cashbox_repository.dart';
import 'package:steam_gallery_app/features/cashbox/presentation/providers/cashbox_providers.dart';
import 'package:steam_gallery_app/features/cashbox/presentation/screens/admin/admin_cash_transfer_screen.dart';
import 'package:steam_gallery_app/features/cashbox/presentation/screens/admin/admin_record_expense_screen.dart';
import 'package:steam_gallery_app/features/employees/data/models/employee_models.dart';
import 'package:steam_gallery_app/features/employees/data/repositories/employees_repository.dart';
import 'package:steam_gallery_app/features/employees/presentation/providers/employees_providers.dart';
import 'package:steam_gallery_app/features/employees/presentation/screens/admin_attendance_screen.dart';
import 'package:steam_gallery_app/features/employees/presentation/screens/admin_pay_salary_screen.dart';
import 'package:steam_gallery_app/features/technician_account/data/models/sale.dart';

const _tills = [
  CashboxBalance(
    cashboxId: 'a',
    name: 'درج',
    balance: 500,
    kind: CashboxKind.cash,
  ),
  CashboxBalance(
    cashboxId: 'b',
    name: 'رئيسية',
    balance: 9000,
    kind: CashboxKind.main,
  ),
  CashboxBalance(
    cashboxId: 'c',
    name: 'CIB',
    balance: 100,
    kind: CashboxKind.transfer,
  ),
  CashboxBalance(
    cashboxId: 'd',
    name: 'فودافون',
    balance: 0,
    kind: CashboxKind.wallet,
  ),
];

class _FakeCashboxRepo implements CashboxRepository {
  final transfers = <({CashboxKind from, CashboxKind to, double amount})>[];
  final batches =
      <
        ({
          List<({String categoryId, double amount, String? notes})> lines,
          CashboxKind kind,
        })
      >[];

  @override
  Future<OutboxResult> transferBetweenTills({
    required CashboxKind from,
    required CashboxKind to,
    required double amount,
    String? notes,
  }) async {
    transfers.add((from: from, to: to, amount: amount));
    return const OutboxResult.done(null);
  }

  @override
  Future<OutboxResult> recordExpenses({
    required List<({String categoryId, double amount, String? notes})> lines,
    required DateTime expenseDate,
    required CashboxKind kind,
  }) async {
    batches.add((lines: lines, kind: kind));
    return const OutboxResult.done(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeEmployeesRepo implements EmployeesRepository {
  PayrollPreview preview = PayrollPreview(
    periodMonth: DateTime(2026, 10),
    baseSalary: 6000,
    presentDays: 20,
    absentDays: 2,
    lateDays: 1,
    leaveDays: 0,
    dailyRate: 200,
    absenceDeduction: 400,
    advanceBalance: 1000,
    alreadyPaid: false,
  );
  final payments =
      <({double absence, double bonus, double advance, CashboxKind kind})>[];
  final attendance = <Map<String, AttendanceStatus>>[];

  @override
  Future<PayrollPreview> payrollPreview(
    String employeeId,
    DateTime month,
  ) async => preview;

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
  }) async {
    payments.add((
      absence: absenceDeduction,
      bonus: bonus,
      advance: advanceDeduction,
      kind: kind,
    ));
    return const OutboxResult.done(null);
  }

  @override
  Future<void> saveAttendance(
    DateTime day,
    Map<String, AttendanceStatus> marks, {
    Set<String> cleared = const {},
  }) async => attendance.add(marks);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _employee = Employee(
  id: 'e1',
  fullName: 'محمود',
  monthlySalary: 6000,
  isActive: true,
  advanceBalance: 1000,
);

Future<void> _open(WidgetTester tester, Widget screen, List overrides) async {
  await tester.binding.setSurfaceSize(const Size(400, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [...overrides],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(
                context,
              ).push(MaterialPageRoute<void>(builder: (_) => screen)),
              child: const Text('افتح'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('افتح'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => initializeDateFormatting('ar'));

  test('each payment method lands in its own till', () {
    expect(cashboxKindForPayment(PaymentMethod.cash), CashboxKind.cash);
    expect(cashboxKindForPayment(PaymentMethod.transfer), CashboxKind.transfer);
    expect(cashboxKindForPayment(PaymentMethod.wallet), CashboxKind.wallet);
  });

  group('تحويل بين الخزن', () {
    testWidgets('the source till is never offered as the destination, and '
        'more than it holds is refused', (tester) async {
      final repo = _FakeCashboxRepo();
      await _open(tester, const AdminCashTransferScreen(), [
        cashboxRepositoryProvider.overrideWithValue(repo),
        cashboxBalancesProvider.overrideWith((ref) async => _tills),
      ]);
      // From the drawer: it appears once (as the source), not as a target.
      expect(find.text('خزنة الدرج'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'المبلغ'),
        '600',
      );
      await tester.tap(find.text('تأكيد التحويل'));
      await tester.pumpAndSettle();
      expect(find.text('المبلغ أكبر من رصيد الخزنة'), findsOneWidget);
      expect(repo.transfers, isEmpty);

      // Picking the safe as the source swaps the drawer in as the target.
      await tester.tap(find.text('الخزنة الرئيسية').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('تأكيد التحويل'));
      await tester.pumpAndSettle();
      expect(repo.transfers.single.from, CashboxKind.main);
      expect(repo.transfers.single.to, CashboxKind.cash);
      expect(repo.transfers.single.amount, 600);
    });
  });

  group('مصروف بأكثر من بند', () {
    testWidgets('two lines go out together from one till', (tester) async {
      final repo = _FakeCashboxRepo();
      await _open(tester, const AdminRecordExpenseScreen(), [
        cashboxRepositoryProvider.overrideWithValue(repo),
        expenseCategoriesProvider.overrideWith(
          (ref) async => const [
            ExpenseCategory(id: 'c1', name: 'كهرباء', isActive: true),
            ExpenseCategory(id: 'c2', name: 'إيجار', isActive: true),
          ],
        ),
      ]);
      await tester.tap(find.text('التصنيف'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('كهرباء').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'المبلغ'),
        '120',
      );

      await tester.tap(find.text('إضافة بند'));
      await tester.pumpAndSettle();
      expect(find.text('بند 2'), findsOneWidget);
      await tester.tap(find.text('التصنيف').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('إيجار').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'المبلغ').last,
        '3000',
      );
      await tester.pumpAndSettle();
      expect(find.text(Formatters.currency(3120)), findsOneWidget);

      await tester.tap(find.text('فودافون كاش'));
      await tester.tap(find.text('تسجيل 2 بنود'));
      await tester.pumpAndSettle();

      final batch = repo.batches.single;
      expect(batch.kind, CashboxKind.wallet);
      expect(batch.lines.map((l) => (l.categoryId, l.amount)).toList(), [
        ('c1', 120.0),
        ('c2', 3000.0),
      ]);
    });
  });

  group('الحضور والغياب', () {
    testWidgets('mark the rest present, one absent, save', (tester) async {
      final repo = _FakeEmployeesRepo();
      final today = DateUtils.dateOnly(DateTime.now());
      await _open(tester, const AdminAttendanceScreen(), [
        employeesRepositoryProvider.overrideWithValue(repo),
        employeesProvider.overrideWith(
          (ref) async => [
            _employee,
            const Employee(
              id: 'e2',
              fullName: 'سامح',
              monthlySalary: 4000,
              isActive: true,
            ),
            const Employee(
              id: 'e3',
              fullName: 'موقوف',
              monthlySalary: 1,
              isActive: false,
            ),
          ],
        ),
        attendanceForDayProvider(today).overrideWith((ref) async => {}),
      ]);
      expect(find.text('موقوف'), findsNothing, reason: 'only working staff');
      await tester.tap(find.text('الباقي حاضر'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('غائب').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('حفظ الحضور'));
      await tester.pumpAndSettle();
      expect(repo.attendance.single, {
        'e1': AttendanceStatus.present,
        'e2': AttendanceStatus.absent,
      });
    });
  });

  group('صرف مرتب', () {
    testWidgets('suggests the deductions and pays the net', (tester) async {
      final repo = _FakeEmployeesRepo();
      await _open(tester, const AdminPaySalaryScreen(employee: _employee), [
        employeesRepositoryProvider.overrideWithValue(repo),
      ]);
      // 6000 − 400 absence − 1000 advances.
      expect(find.text('صرف ${Formatters.currency(4600)}'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextField, 'مكافأة / إضافي'),
        '200',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('صرف ${Formatters.currency(4800)}'));
      await tester.pumpAndSettle();
      final p = repo.payments.single;
      expect((p.absence, p.bonus, p.advance), (400.0, 200.0, 1000.0));
      expect(p.kind, CashboxKind.main);
    });

    testWidgets('deducting more advances than owed is blocked', (tester) async {
      final repo = _FakeEmployeesRepo();
      await _open(tester, const AdminPaySalaryScreen(employee: _employee), [
        employeesRepositoryProvider.overrideWithValue(repo),
      ]);
      await tester.enterText(
        find.widgetWithText(TextField, 'خصم من السلف'),
        '1500',
      );
      await tester.pumpAndSettle();
      expect(find.text('خصم السلف أكبر من السلف اللي عليه'), findsOneWidget);
      await tester.tap(find.text('صرف ${Formatters.currency(4100)}'));
      await tester.pumpAndSettle();
      expect(repo.payments, isEmpty);
    });

    testWidgets('an already paid month says so', (tester) async {
      final repo = _FakeEmployeesRepo()
        ..preview = _FakeEmployeesRepo().preview.copyWith(alreadyPaid: true);
      await _open(tester, const AdminPaySalaryScreen(employee: _employee), [
        employeesRepositoryProvider.overrideWithValue(repo),
      ]);
      expect(find.text('مرتب الشهر ده اتصرف قبل كدا'), findsOneWidget);
    });
  });
}
