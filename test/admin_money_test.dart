import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:steam_gallery_app/core/errors/app_exception.dart';
import 'package:steam_gallery_app/core/offline/outbox.dart';
import 'package:steam_gallery_app/core/theme/app_theme.dart';
import 'package:steam_gallery_app/core/utils/formatters.dart';
import 'package:steam_gallery_app/features/auth/data/models/app_user.dart';
import 'package:steam_gallery_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:steam_gallery_app/features/cashbox/data/models/cash_transaction.dart';
import 'package:steam_gallery_app/features/cashbox/data/models/cashbox_balance.dart';
import 'package:steam_gallery_app/features/cashbox/data/models/expense_category.dart';
import 'package:steam_gallery_app/features/cashbox/data/repositories/cashbox_repository.dart';
import 'package:steam_gallery_app/features/cashbox/presentation/providers/cashbox_providers.dart';
import 'package:steam_gallery_app/features/cashbox/presentation/screens/admin/admin_cash_movement_screen.dart';
import 'package:steam_gallery_app/features/cashbox/presentation/screens/admin/admin_cashbox_screen.dart';
import 'package:steam_gallery_app/features/cashbox/presentation/screens/admin/admin_record_expense_screen.dart';
import 'package:steam_gallery_app/features/customer_account/data/repositories/customer_account_repository.dart';
import 'package:steam_gallery_app/features/customer_account/presentation/providers/customer_account_providers.dart';
import 'package:steam_gallery_app/features/customer_account/presentation/screens/admin/admin_customer_payment_screen.dart';
import 'package:steam_gallery_app/features/purchases/data/repositories/purchases_repository.dart';
import 'package:steam_gallery_app/features/purchases/presentation/providers/purchases_providers.dart';
import 'package:steam_gallery_app/features/purchases/presentation/widgets/pay_supplier_dialog.dart';
import 'package:steam_gallery_app/features/technician_account/data/models/sale.dart';

const _cashBox = CashboxBalance(
  cashboxId: 'cb-cash',
  name: 'نقدي',
  balance: 500,
  kind: CashboxKind.cash,
);
const _transferBox = CashboxBalance(
  cashboxId: 'cb-transfer',
  name: 'تحويلات',
  balance: 1200,
  kind: CashboxKind.transfer,
);

CashTransaction _txn(String id, CashTxnType type, double amount, String box) =>
    CashTransaction(
      id: id,
      cashboxId: box,
      type: type,
      amount: amount,
      notes: 'ملاحظة $id',
      createdAt: DateTime(2026, 10, 7, 9),
    );

typedef _MoneyCall = ({
  String what,
  double amount,
  CashboxKind kind,
  String? notes,
  String? categoryId,
});

class _FakeCashboxRepo implements CashboxRepository {
  final calls = <_MoneyCall>[];
  OutboxResult result = const OutboxResult.done(null);
  Object? error;

  Future<OutboxResult> _record(_MoneyCall call) async {
    calls.add(call);
    if (error != null) throw error!;
    return result;
  }

  @override
  Future<OutboxResult> recordExpense({
    required String categoryId,
    required double amount,
    required DateTime expenseDate,
    required CashboxKind kind,
    String? notes,
  }) => _record((
    what: 'expense',
    amount: amount,
    kind: kind,
    notes: notes,
    categoryId: categoryId,
  ));

  @override
  Future<OutboxResult> depositCash({
    required double amount,
    required CashboxKind kind,
    String? notes,
  }) => _record((
    what: 'deposit',
    amount: amount,
    kind: kind,
    notes: notes,
    categoryId: null,
  ));

  @override
  Future<OutboxResult> withdrawCash({
    required double amount,
    required CashboxKind kind,
    String? notes,
  }) => _record((
    what: 'withdraw',
    amount: amount,
    kind: kind,
    notes: notes,
    categoryId: null,
  ));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Pumps [screen] pushed over a plain page, as the app opens these forms.
Future<void> _open(
  WidgetTester tester,
  Widget screen,
  List overrides, {
  Size size = const Size(600, 1200),
}) async {
  await tester.binding.setSurfaceSize(size);
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

  group('الخزنة', () {
    List cashboxOverrides() => [
      cashboxBalancesProvider.overrideWith(
        (ref) async => [_cashBox, _transferBox],
      ),
      cashTransactionsProvider(null).overrideWith(
        (ref) async => [
          _txn('t1', CashTxnType.sale, 300, 'cb-cash'),
          _txn('t2', CashTxnType.expense, -50, 'cb-cash'),
          _txn('t3', CashTxnType.otherIncome, 1000, 'cb-transfer'),
        ],
      ),
      cashTransactionsProvider('cb-transfer').overrideWith(
        (ref) async => [
          _txn('t3', CashTxnType.otherIncome, 1000, 'cb-transfer'),
        ],
      ),
      currentUserProfileProvider.overrideWith(
        (ref) async => const AppUser(
          id: 'admin-1',
          role: AppRole.admin,
          fullName: 'أدمن',
          isActive: true,
        ),
      ),
    ];

    testWidgets('both tills and every movement, labelled and signed', (
      tester,
    ) async {
      await _open(tester, const AdminCashboxScreen(), cashboxOverrides());
      expect(find.text('الخزنة النقدية'), findsOneWidget);
      expect(find.text('خزنة التحويلات'), findsOneWidget);
      expect(find.text(Formatters.currency(500)), findsOneWidget);
      expect(find.text(Formatters.currency(1200)), findsOneWidget);
      expect(find.text('بيع'), findsOneWidget);
      expect(find.text('مصروف'), findsOneWidget);
      expect(find.text('إيداع نقدي'), findsOneWidget);
      expect(find.text(Formatters.currency(-50)), findsOneWidget);
    });

    testWidgets('filtering to one till shows only its movements', (
      tester,
    ) async {
      await _open(tester, const AdminCashboxScreen(), cashboxOverrides());
      await tester.tap(find.text('الكل'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('خزنة التحويلات').last);
      await tester.pumpAndSettle();
      expect(find.text('بيع'), findsNothing);
      expect(find.text('إيداع نقدي'), findsOneWidget);
    });

    testWidgets('a new movement offers expense, deposit and withdrawal', (
      tester,
    ) async {
      await _open(tester, const AdminCashboxScreen(), cashboxOverrides());
      await tester.tap(find.text('حركة جديدة'));
      await tester.pumpAndSettle();
      expect(find.text('تسجيل مصروف'), findsOneWidget);
      expect(find.text('إيداع في الخزنة'), findsOneWidget);
      expect(find.text('سحب من الخزنة'), findsOneWidget);
    });
  });

  group('تسجيل مصروف', () {
    List expenseOverrides(_FakeCashboxRepo repo, {bool noCategories = false}) =>
        [
          cashboxRepositoryProvider.overrideWithValue(repo),
          expenseCategoriesProvider.overrideWith(
            (ref) async => noCategories
                ? <ExpenseCategory>[]
                : const [
                    ExpenseCategory(id: 'c1', name: 'كهرباء', isActive: true),
                    ExpenseCategory(id: 'c2', name: 'إيجار', isActive: true),
                  ],
          ),
        ];

    testWidgets('with no categories yet, says so instead of an empty list', (
      tester,
    ) async {
      await _open(
        tester,
        const AdminRecordExpenseScreen(),
        expenseOverrides(_FakeCashboxRepo(), noCategories: true),
      );
      expect(
        find.text('لا توجد تصنيفات مصروفات — أضف تصنيفًا أولًا'),
        findsOneWidget,
      );
    });

    testWidgets('needs a category and a positive amount', (tester) async {
      final repo = _FakeCashboxRepo();
      await _open(
        tester,
        const AdminRecordExpenseScreen(),
        expenseOverrides(repo),
      );
      await tester.enterText(find.widgetWithText(TextFormField, 'المبلغ'), '0');
      await tester.tap(find.text('تسجيل المصروف'));
      await tester.pumpAndSettle();
      expect(find.text('أدخل مبلغًا صحيحًا'), findsOneWidget);
      expect(find.text('اختر التصنيف أولًا'), findsOneWidget);
      expect(repo.calls, isEmpty);
    });

    testWidgets('records it against the chosen category and till', (
      tester,
    ) async {
      final repo = _FakeCashboxRepo();
      await _open(
        tester,
        const AdminRecordExpenseScreen(),
        expenseOverrides(repo),
      );
      await tester.tap(find.text('التصنيف'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('إيجار').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'المبلغ'),
        '750.5',
      );
      await tester.tap(find.text('خزنة التحويلات'));
      await tester.enterText(
        find.widgetWithText(TextFormField, 'ملاحظات (اختياري)'),
        'شهر أكتوبر',
      );
      await tester.tap(find.text('تسجيل المصروف'));
      await tester.pumpAndSettle();

      final call = repo.calls.single;
      expect(call.what, 'expense');
      expect(call.categoryId, 'c2');
      expect(call.amount, 750.5);
      expect(call.kind, CashboxKind.transfer);
      expect(call.notes, 'شهر أكتوبر');
      expect(find.text('افتح'), findsOneWidget, reason: 'closed after saving');
    });

    testWidgets('a refusal (e.g. not enough in the till) stays open', (
      tester,
    ) async {
      final repo = _FakeCashboxRepo()
        ..error = const AppException('رصيد الخزنة لا يكفي');
      await _open(
        tester,
        const AdminRecordExpenseScreen(),
        expenseOverrides(repo),
      );
      await tester.tap(find.text('التصنيف'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('كهرباء').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'المبلغ'),
        '100',
      );
      await tester.tap(find.text('تسجيل المصروف'));
      await tester.pumpAndSettle();
      expect(find.text('رصيد الخزنة لا يكفي'), findsOneWidget);
      expect(find.text('تسجيل مصروف'), findsOneWidget);
    });
  });

  group('إيداع وسحب', () {
    List movementOverrides(_FakeCashboxRepo repo) => [
      cashboxRepositoryProvider.overrideWithValue(repo),
      cashboxBalancesProvider.overrideWith(
        (ref) async => [_cashBox, _transferBox],
      ),
    ];

    testWidgets('shows the balance of the till being used', (tester) async {
      await _open(
        tester,
        const AdminCashMovementScreen(kind: CashMovementKind.withdrawal),
        movementOverrides(_FakeCashboxRepo()),
      );
      expect(find.text('رصيد الخزنة النقدية'), findsOneWidget);
      expect(find.text(Formatters.currency(500)), findsOneWidget);
      await tester.tap(find.text('خزنة التحويلات'));
      await tester.pumpAndSettle();
      expect(find.text(Formatters.currency(1200)), findsOneWidget);
    });

    testWidgets('a withdrawal can\'t exceed the till', (tester) async {
      final repo = _FakeCashboxRepo();
      await _open(
        tester,
        const AdminCashMovementScreen(kind: CashMovementKind.withdrawal),
        movementOverrides(repo),
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'المبلغ'),
        '600',
      );
      await tester.tap(find.text('تأكيد السحب'));
      await tester.pumpAndSettle();
      expect(find.text('المبلغ أكبر من رصيد الخزنة'), findsOneWidget);
      expect(repo.calls, isEmpty);

      // From the transfer till (1200) the same amount is fine.
      await tester.tap(find.text('خزنة التحويلات'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('تأكيد السحب'));
      await tester.pumpAndSettle();
      expect(repo.calls.single.what, 'withdraw');
      expect(repo.calls.single.amount, 600);
      expect(repo.calls.single.kind, CashboxKind.transfer);
    });

    testWidgets('a deposit has no ceiling and keeps its reason', (
      tester,
    ) async {
      final repo = _FakeCashboxRepo();
      await _open(
        tester,
        const AdminCashMovementScreen(kind: CashMovementKind.deposit),
        movementOverrides(repo),
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'المبلغ'),
        '5000',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'السبب / ملاحظات (اختياري)'),
        'عهدة',
      );
      await tester.tap(find.text('تأكيد الإيداع'));
      await tester.pumpAndSettle();
      expect(repo.calls.single.what, 'deposit');
      expect(repo.calls.single.amount, 5000);
      expect(repo.calls.single.kind, CashboxKind.cash);
      expect(repo.calls.single.notes, 'عهدة');
    });

    testWidgets('offline: saved on the device', (tester) async {
      final repo = _FakeCashboxRepo()..result = const OutboxResult.queued();
      await _open(
        tester,
        const AdminCashMovementScreen(kind: CashMovementKind.deposit),
        movementOverrides(repo),
      );
      await tester.enterText(find.widgetWithText(TextFormField, 'المبلغ'), '1');
      await tester.tap(find.text('تأكيد الإيداع'));
      await tester.pumpAndSettle();
      expect(find.textContaining('على الجهاز'), findsOneWidget);
    });
  });

  group('تحصيل من عميل', () {
    testWidgets('records the amount into the till it came in by, and a '
        'retry reuses the same request id', (tester) async {
      final repo = _FakeCustomerAccountRepo()
        ..error = const AppException('لا يوجد اتصال');
      await _open(tester, const AdminCustomerPaymentScreen(customerId: 'c1'), [
        customerAccountRepositoryProvider.overrideWithValue(repo),
      ]);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'المبلغ'),
        '250',
      );
      await tester.tap(find.text('تحويل'));
      await tester.tap(find.text('تسجيل الدفعة'));
      await tester.pumpAndSettle();
      expect(find.text('لا يوجد اتصال'), findsOneWidget);

      repo.error = null;
      await tester.tap(find.text('تسجيل الدفعة'));
      await tester.pumpAndSettle();
      expect(repo.calls, hasLength(2));
      expect(repo.calls[1].customerId, 'c1');
      expect(repo.calls[1].amount, 250);
      expect(repo.calls[1].method, PaymentMethod.transfer);
      expect(repo.calls[1].requestId, repo.calls[0].requestId);
      expect(find.text('افتح'), findsOneWidget);
    });

    testWidgets('an empty amount is refused', (tester) async {
      final repo = _FakeCustomerAccountRepo();
      await _open(tester, const AdminCustomerPaymentScreen(customerId: 'c1'), [
        customerAccountRepositoryProvider.overrideWithValue(repo),
      ]);
      await tester.tap(find.text('تسجيل الدفعة'));
      await tester.pumpAndSettle();
      expect(find.text('أدخل مبلغًا صحيحًا'), findsOneWidget);
      expect(repo.calls, isEmpty);
    });
  });

  group('سداد مورد', () {
    Future<void> openDialog(
      WidgetTester tester,
      _FakePurchasesRepo repo, {
      String? invoiceId,
    }) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [purchasesRepositoryProvider.overrideWithValue(repo)],
          child: MaterialApp(
            theme: AppTheme.light(),
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) => TextButton(
                  onPressed: () => showPaySupplierDialog(
                    context,
                    ref,
                    supplierId: 'sup1',
                    supplierName: 'مورد المكاوي',
                    maxAmount: 400,
                    invoiceId: invoiceId,
                  ),
                  child: const Text('سداد'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('سداد'));
      await tester.pumpAndSettle();
    }

    testWidgets('defaults to the whole amount due, from the chosen till', (
      tester,
    ) async {
      final repo = _FakePurchasesRepo();
      await openDialog(tester, repo, invoiceId: 'inv-1');
      expect(find.text('سداد للمورد مورد المكاوي'), findsOneWidget);
      await tester.tap(find.text('تحويل'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('سداد').last);
      await tester.pumpAndSettle();
      final call = repo.calls.single;
      expect(call.amount, 400);
      expect(call.kind, CashboxKind.transfer);
      expect(call.invoiceId, 'inv-1');
      expect(find.text('تم تسجيل السداد'), findsOneWidget);
    });

    testWidgets('more than what is due is refused', (tester) async {
      final repo = _FakePurchasesRepo();
      await openDialog(tester, repo);
      await tester.enterText(find.widgetWithText(TextField, 'المبلغ'), '401');
      await tester.tap(find.text('سداد').last);
      await tester.pumpAndSettle();
      expect(
        find.text('المبلغ لازم يكون أكبر من صفر ومش أكبر من المستحق'),
        findsOneWidget,
      );
      expect(repo.calls, isEmpty);
    });

    testWidgets('without an invoice, the oldest are settled first', (
      tester,
    ) async {
      final repo = _FakePurchasesRepo();
      await openDialog(tester, repo);
      await tester.enterText(find.widgetWithText(TextField, 'المبلغ'), '150');
      await tester.tap(find.text('سداد').last);
      await tester.pumpAndSettle();
      expect(repo.calls.single.invoiceId, isNull);
      expect(repo.calls.single.amount, 150);
      expect(repo.calls.single.kind, CashboxKind.cash);
    });
  });
}

class _FakeCustomerAccountRepo implements CustomerAccountRepository {
  final calls =
      <
        ({
          String customerId,
          double amount,
          PaymentMethod method,
          String requestId,
        })
      >[];
  Object? error;

  @override
  Future<OutboxResult> recordPayment({
    required String customerId,
    required double amount,
    String? notes,
    required String clientRequestId,
    required PaymentMethod paymentMethod,
  }) async {
    calls.add((
      customerId: customerId,
      amount: amount,
      method: paymentMethod,
      requestId: clientRequestId,
    ));
    if (error != null) throw error!;
    return const OutboxResult.done(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakePurchasesRepo implements PurchasesRepository {
  final calls = <({double amount, CashboxKind kind, String? invoiceId})>[];

  @override
  Future<OutboxResult> paySupplier({
    required String supplierId,
    required String supplierName,
    required double amount,
    required CashboxKind kind,
    String? invoiceId,
    String? notes,
    required String clientRequestId,
  }) async {
    calls.add((amount: amount, kind: kind, invoiceId: invoiceId));
    return const OutboxResult.done(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
