import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:steam_gallery_app/core/errors/app_exception.dart';
import 'package:steam_gallery_app/core/offline/outbox.dart';
import 'package:steam_gallery_app/core/theme/app_theme.dart';
import 'package:steam_gallery_app/core/utils/formatters.dart';
import 'package:steam_gallery_app/features/cashbox/data/models/cashbox_balance.dart';
import 'package:steam_gallery_app/features/products/data/models/product.dart';
import 'package:steam_gallery_app/features/products/presentation/providers/product_providers.dart';
import 'package:steam_gallery_app/features/purchases/data/models/purchase_models.dart';
import 'package:steam_gallery_app/features/purchases/data/repositories/purchases_repository.dart';
import 'package:steam_gallery_app/features/purchases/presentation/providers/purchases_providers.dart';
import 'package:steam_gallery_app/features/purchases/presentation/screens/admin/admin_purchase_invoice_form_screen.dart';

Product _product(
  String id,
  String name,
  double cost, {
  bool service = false,
  bool assembly = false,
  bool active = true,
}) => Product(
  id: id,
  sku: 'SKU-$id',
  name: name,
  specs: const {},
  costPrice: cost,
  sellingPrice: cost * 2,
  minStock: 0,
  isActive: active,
  isService: service,
  isAssembly: assembly,
  createdAt: DateTime(2026),
);

const _supplier = SupplierBalance(
  id: 'sup1',
  name: 'مورد المكاوي',
  phone: '0100',
  totalInvoices: 1000,
  totalPaid: 600,
  balance: 400,
  invoicesCount: 2,
);

typedef _InvoiceCall = ({
  String? supplierId,
  String? supplierName,
  String? supplierPhone,
  List<PurchaseLineInput> items,
  double discount,
  double paidAmount,
  CashboxKind? paymentKind,
  String? supplierInvoiceRef,
  String? notes,
  String clientRequestId,
});

class _FakePurchasesRepo implements PurchasesRepository {
  final calls = <_InvoiceCall>[];
  OutboxResult result = const OutboxResult.done(null);
  Object? error;

  @override
  Future<OutboxResult> createInvoice({
    String? supplierId,
    String? supplierName,
    String? supplierPhone,
    required List<PurchaseLineInput> items,
    required double discount,
    required double paidAmount,
    CashboxKind? paymentKind,
    required DateTime invoiceDate,
    String? supplierInvoiceRef,
    String? notes,
    required String clientRequestId,
  }) async {
    calls.add((
      supplierId: supplierId,
      supplierName: supplierName,
      supplierPhone: supplierPhone,
      items: [...items],
      discount: discount,
      paidAmount: paidAmount,
      paymentKind: paymentKind,
      supplierInvoiceRef: supplierInvoiceRef,
      notes: notes,
      clientRequestId: clientRequestId,
    ));
    if (error != null) throw error!;
    return result;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _open(WidgetTester tester, _FakePurchasesRepo repo) async {
  await tester.binding.setSurfaceSize(const Size(700, 2000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        purchasesRepositoryProvider.overrideWithValue(repo),
        suppliersProvider.overrideWith((ref) async => [_supplier]),
        adminProductsProvider().overrideWith(
          (ref) async => [
            _product('p1', 'مكواة', 60),
            _product('p2', 'قاعدة', 20),
            _product('svc', 'صيانة', 0, service: true),
            _product('kit', 'طقم', 0, assembly: true),
            _product('old', 'موقوف', 5, active: false),
          ],
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const AdminPurchaseInvoiceFormScreen(),
                ),
              ),
              child: const Text('فاتورة جديدة'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('فاتورة جديدة'));
  await tester.pumpAndSettle();
}

Future<void> _addLine(
  WidgetTester tester,
  String name, {
  String? qty,
  String? cost,
}) async {
  await tester.tap(find.text('إضافة صنف'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(name).last);
  await tester.pumpAndSettle();
  if (qty != null) {
    await tester.enterText(find.widgetWithText(TextField, 'الكمية'), qty);
  }
  if (cost != null) {
    await tester.enterText(
      find.widgetWithText(TextField, 'سعر الشراء للوحدة'),
      cost,
    );
  }
  await tester.tap(find.text('إضافة').last);
  await tester.pumpAndSettle();
}

Future<void> _typeSupplier(WidgetTester tester, String name) async {
  await tester.enterText(
    find.widgetWithText(TextField, 'اسم المورد / التاجر'),
    name,
  );
  await tester.pump();
}

String _saveLabel(double total) =>
    'حفظ الفاتورة · ${Formatters.currency(total)}';

Future<void> _save(WidgetTester tester, double total) async {
  await tester.tap(find.text(_saveLabel(total)));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => initializeDateFormatting('ar'));

  testWidgets('only active stock products can be bought — not services or '
      'assemblies (their components are bought instead)', (tester) async {
    await _open(tester, _FakePurchasesRepo());
    await tester.tap(find.text('إضافة صنف'));
    await tester.pumpAndSettle();
    expect(find.text('مكواة'), findsOneWidget);
    expect(find.text('قاعدة'), findsOneWidget);
    expect(find.text('صيانة'), findsNothing);
    expect(find.text('طقم'), findsNothing);
    expect(find.text('موقوف'), findsNothing);
  });

  testWidgets('a line starts at the product\'s last cost and adds up', (
    tester,
  ) async {
    await _open(tester, _FakePurchasesRepo());
    await _addLine(tester, 'مكواة', qty: '3');
    expect(find.text('3 × ${Formatters.currency(60)}'), findsOneWidget);
    expect(find.text(_saveLabel(180)), findsOneWidget);

    // The same product at the same cost merges into one line.
    await _addLine(tester, 'مكواة', qty: '2');
    expect(find.text('5 × ${Formatters.currency(60)}'), findsOneWidget);

    // At another cost it is its own line.
    await _addLine(tester, 'مكواة', qty: '1', cost: '55');
    expect(find.text('1 × ${Formatters.currency(55)}'), findsOneWidget);
    expect(find.text(_saveLabel(355)), findsOneWidget);
  });

  testWidgets('a zero quantity is refused', (tester) async {
    await _open(tester, _FakePurchasesRepo());
    await _addLine(tester, 'مكواة', qty: '0');
    expect(find.text('أدخل كمية وسعر صحيحين'), findsOneWidget);
    expect(find.text('لم تتم إضافة أصناف بعد'), findsOneWidget);
  });

  testWidgets('tapping a line edits it, the bin removes it', (tester) async {
    await _open(tester, _FakePurchasesRepo());
    await _addLine(tester, 'مكواة', qty: '2');
    await tester.tap(find.text('2 × ${Formatters.currency(60)}'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'الكمية'), '4');
    await tester.tap(find.text('حفظ'));
    await tester.pumpAndSettle();
    expect(find.text(_saveLabel(240)), findsOneWidget);

    await tester.tap(find.byIcon(Iconsax.trash_copy));
    await tester.pumpAndSettle();
    expect(find.text('لم تتم إضافة أصناف بعد'), findsOneWidget);
  });

  testWidgets('needs a supplier and at least one product', (tester) async {
    final repo = _FakePurchasesRepo();
    await _open(tester, repo);
    await _save(tester, 0);
    expect(find.text('اختر المورد أو اكتب اسمه'), findsOneWidget);
    expect(repo.calls, isEmpty);
  });

  testWidgets('cash: paid in full from the chosen till, to a new supplier', (
    tester,
  ) async {
    final repo = _FakePurchasesRepo();
    await _open(tester, repo);
    await _typeSupplier(tester, ' تاجر جديد ');
    await tester.enterText(
      find.widgetWithText(TextField, 'تليفون المورد (اختياري)'),
      '0111',
    );
    await _addLine(tester, 'مكواة', qty: '2');
    await _addLine(tester, 'قاعدة', qty: '5');
    await tester.enterText(find.widgetWithText(TextField, 'الخصم'), '20');
    await tester.pump();
    await tester.tap(find.text('تحويل'));
    await tester.pump();
    expect(find.text(_saveLabel(200)), findsOneWidget);

    await _save(tester, 200);
    final call = repo.calls.single;
    expect(call.supplierId, isNull, reason: 'a typed name is a new supplier');
    expect(call.supplierName, 'تاجر جديد');
    expect(call.supplierPhone, '0111');
    expect(call.discount, 20);
    expect(call.paidAmount, 200);
    expect(call.paymentKind, CashboxKind.transfer);
    expect(
      call.items.map((l) => (l.productId, l.quantity, l.unitCost)).toList(),
      [('p1', 2, 60.0), ('p2', 5, 20.0)],
    );
    expect(
      find.text('تم تسجيل فاتورة الشراء وإضافة البضاعة للمخزن'),
      findsOneWidget,
    );
    expect(find.text('فاتورة جديدة'), findsOneWidget, reason: 'popped back');
  });

  testWidgets('a registered supplier is picked by id', (tester) async {
    final repo = _FakePurchasesRepo();
    await _open(tester, repo);
    await tester.tap(find.byTooltip('اختيار مورد مسجَّل'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('مورد المكاوي'));
    await tester.pumpAndSettle();
    await _addLine(tester, 'مكواة');
    await _save(tester, 60);
    expect(repo.calls.single.supplierId, 'sup1');
    expect(repo.calls.single.supplierPhone, '0100');
  });

  testWidgets('editing the picked supplier\'s name makes a new supplier', (
    tester,
  ) async {
    final repo = _FakePurchasesRepo();
    await _open(tester, repo);
    await tester.tap(find.byTooltip('اختيار مورد مسجَّل'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('مورد المكاوي'));
    await tester.pumpAndSettle();
    await _typeSupplier(tester, 'مورد تاني');
    await _addLine(tester, 'مكواة');
    await _save(tester, 60);
    expect(repo.calls.single.supplierId, isNull);
    expect(repo.calls.single.supplierName, 'مورد تاني');
  });

  testWidgets('partial: what is paid now, the rest on the supplier', (
    tester,
  ) async {
    final repo = _FakePurchasesRepo();
    await _open(tester, repo);
    await _typeSupplier(tester, 'تاجر');
    await _addLine(tester, 'مكواة', qty: '5'); // 300
    await tester.tap(find.text('جزئي'));
    await tester.pump();
    await tester.enterText(
      find.widgetWithText(TextField, 'المبلغ المدفوع الآن'),
      '100',
    );
    await tester.pump();
    expect(
      find.widgetWithText(Row, 'المتبقي على الحساب (آجل)'),
      findsOneWidget,
    );
    expect(find.text(Formatters.currency(200)), findsOneWidget);

    await _save(tester, 300);
    expect(repo.calls.single.paidAmount, 100);
    expect(repo.calls.single.paymentKind, CashboxKind.cash);
  });

  testWidgets('partial: paying more than the invoice is refused', (
    tester,
  ) async {
    final repo = _FakePurchasesRepo();
    await _open(tester, repo);
    await _typeSupplier(tester, 'تاجر');
    await _addLine(tester, 'مكواة'); // 60
    await tester.tap(find.text('جزئي'));
    await tester.pump();
    await tester.enterText(
      find.widgetWithText(TextField, 'المبلغ المدفوع الآن'),
      '61',
    );
    await tester.pump();
    await _save(tester, 60);
    expect(
      find.text('المدفوع لازم يكون بين صفر وإجمالي الفاتورة'),
      findsOneWidget,
    );
    expect(repo.calls, isEmpty);
  });

  testWidgets('deferred: nothing paid, no till touched', (tester) async {
    final repo = _FakePurchasesRepo();
    await _open(tester, repo);
    await _typeSupplier(tester, 'تاجر');
    await _addLine(tester, 'مكواة');
    await tester.tap(find.text('آجل'));
    await tester.pump();
    expect(find.text('كاش'), findsNothing, reason: 'no till to choose');
    await _save(tester, 60);
    expect(repo.calls.single.paidAmount, 0);
    expect(repo.calls.single.paymentKind, isNull);
  });

  testWidgets('a discount above the invoice is refused', (tester) async {
    final repo = _FakePurchasesRepo();
    await _open(tester, repo);
    await _typeSupplier(tester, 'تاجر');
    await _addLine(tester, 'مكواة');
    await tester.enterText(find.widgetWithText(TextField, 'الخصم'), '70');
    await tester.pump();
    await _save(tester, -10);
    expect(find.text('قيمة الخصم غير صحيحة'), findsOneWidget);
    expect(repo.calls, isEmpty);
  });

  testWidgets('optional fields are sent only when filled', (tester) async {
    final repo = _FakePurchasesRepo();
    await _open(tester, repo);
    await _typeSupplier(tester, 'تاجر');
    await tester.enterText(
      find.widgetWithText(TextField, 'رقم فاتورة المورد (اختياري)'),
      'INV-77',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'ملاحظات (اختياري)'),
      'بضاعة الشتا',
    );
    await _addLine(tester, 'مكواة');
    await _save(tester, 60);
    expect(repo.calls.single.supplierInvoiceRef, 'INV-77');
    expect(repo.calls.single.notes, 'بضاعة الشتا');
  });

  testWidgets('offline: saved on the device', (tester) async {
    final repo = _FakePurchasesRepo()..result = const OutboxResult.queued();
    await _open(tester, repo);
    await _typeSupplier(tester, 'تاجر');
    await _addLine(tester, 'مكواة');
    await _save(tester, 60);
    expect(find.textContaining('فاتورة الشراء اتسجلت على الجهاز'), findsOne);
  });

  testWidgets('a server refusal keeps the form with its message', (
    tester,
  ) async {
    final repo = _FakePurchasesRepo()
      ..error = const AppException('رصيد الخزنة لا يكفي');
    await _open(tester, repo);
    await _typeSupplier(tester, 'تاجر');
    await _addLine(tester, 'مكواة');
    await _save(tester, 60);
    expect(find.text('رصيد الخزنة لا يكفي'), findsOneWidget);
    expect(find.text('فاتورة شراء جديدة'), findsOneWidget);
  });

  testWidgets('a retry after a refusal reuses the same request id', (
    tester,
  ) async {
    final repo = _FakePurchasesRepo()
      ..error = const AppException('لا يوجد اتصال');
    await _open(tester, repo);
    await _typeSupplier(tester, 'تاجر');
    await _addLine(tester, 'مكواة');
    await _save(tester, 60);
    repo.error = null;
    await _save(tester, 60);
    expect(repo.calls, hasLength(2));
    expect(
      repo.calls[1].clientRequestId,
      repo.calls[0].clientRequestId,
      reason: 'the same invoice can never be recorded twice',
    );
  });
}
