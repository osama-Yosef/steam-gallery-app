import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:steam_gallery_app/core/errors/app_exception.dart';
import 'package:steam_gallery_app/core/theme/app_theme.dart';
import 'package:steam_gallery_app/core/utils/formatters.dart';
import 'package:steam_gallery_app/features/auth/data/models/app_user.dart';
import 'package:steam_gallery_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:steam_gallery_app/features/inventory/data/models/technician_bag_stock_item.dart';
import 'package:steam_gallery_app/features/inventory/presentation/providers/inventory_providers.dart';
import 'package:steam_gallery_app/features/products/data/models/product.dart';
import 'package:steam_gallery_app/features/products/presentation/providers/product_providers.dart';
import 'package:steam_gallery_app/features/sales/data/models/sale_line_input.dart';
import 'package:steam_gallery_app/features/technician_account/data/models/sale.dart';
import 'package:steam_gallery_app/features/technician_account/data/repositories/technician_account_repository.dart';
import 'package:steam_gallery_app/features/technician_account/presentation/providers/technician_account_providers.dart';
import 'package:steam_gallery_app/features/technician_account/presentation/screens/technician/technician_sale_screen.dart';

const _tech = AppUser(
  id: 't1',
  role: AppRole.technician,
  fullName: 'فني',
  isActive: true,
);

TechnicianBagStockItem _bag(String id, String name, int qty, double price) =>
    TechnicianBagStockItem(
      productId: id,
      productName: name,
      sku: id,
      quantity: qty,
      costPrice: price / 2,
      sellingPrice: price,
    );

typedef _Call = ({
  String technicianId,
  String? customerName,
  List<SaleLineInput> items,
  PaymentMethod method,
  double discount,
  double paid,
  String requestId,
  String? maintenanceRequestId,
});

class _FakeRepo implements TechnicianAccountRepository {
  final calls = <_Call>[];
  Object? error;

  @override
  Future<String> recordSale({
    required String technicianId,
    String? customerName,
    String? customerPhone,
    required List<SaleLineInput> items,
    required PaymentMethod paymentMethod,
    required double discount,
    required double paidAmount,
    required String clientRequestId,
    String? notes,
    String? maintenanceRequestId,
  }) async {
    calls.add((
      technicianId: technicianId,
      customerName: customerName,
      items: items,
      method: paymentMethod,
      discount: discount,
      paid: paidAmount,
      requestId: clientRequestId,
      maintenanceRequestId: maintenanceRequestId,
    ));
    if (error != null) throw error!;
    return 'sale-1';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _open(
  WidgetTester tester,
  _FakeRepo repo, {
  String? maintenanceRequestId,
  String? customerName,
}) async {
  await tester.binding.setSurfaceSize(const Size(600, 1600));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentUserProfileProvider.overrideWith((ref) async => _tech),
        technicianAccountRepositoryProvider.overrideWithValue(repo),
        technicianBagStockProvider('t1').overrideWith(
          (ref) async => [
            _bag('p1', 'مكواة', 2, 100),
            _bag('p2', 'فلتر', 5, 20),
            _bag('p3', 'خرطوم', 0, 15),
          ],
        ),
        serviceProductsProvider.overrideWith(
          (ref) async => [
            Product(
              id: 'svc',
              sku: 'S',
              name: 'صيانة',
              specs: const {},
              costPrice: 0,
              sellingPrice: 0,
              minStock: 0,
              isActive: true,
              isService: true,
              createdAt: DateTime(2026),
            ),
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
                  builder: (_) => TechnicianSaleScreen(
                    maintenanceRequestId: maintenanceRequestId,
                    customerName: customerName,
                  ),
                ),
              ),
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

Future<void> _addFromBag(
  WidgetTester tester, {
  String? name,
  String? qty,
}) async {
  await tester.tap(find.text('إضافة'));
  await tester.pumpAndSettle();
  if (name != null) {
    await tester.tap(
      find.byType(DropdownButtonFormField<TechnicianBagStockItem>),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining(name).last);
    await tester.pumpAndSettle();
  }
  if (qty != null) {
    await tester.enterText(find.widgetWithText(TextField, 'الكمية'), qty);
  }
  await tester.tap(find.text('إضافة').last);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => initializeDateFormatting('ar'));

  testWidgets('only what is in the bag can be added', (tester) async {
    await _open(tester, _FakeRepo());
    await tester.tap(find.text('إضافة'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byType(DropdownButtonFormField<TechnicianBagStockItem>),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('مكواة (متاح: 2)'), findsWidgets);
    expect(find.textContaining('خرطوم'), findsNothing, reason: 'none left');
  });

  testWidgets('a quantity above what the bag holds is refused', (tester) async {
    await _open(tester, _FakeRepo());
    await _addFromBag(tester, qty: '3');
    expect(find.text('كمية غير صحيحة'), findsOneWidget);
    expect(find.text('لم تُضف منتجات بعد'), findsOneWidget);
  });

  testWidgets('the total is lines minus discount; "دفع الكل" fills it in', (
    tester,
  ) async {
    await _open(tester, _FakeRepo());
    await _addFromBag(tester, qty: '2'); // مكواة 2 × 100
    await _addFromBag(tester, name: 'فلتر', qty: '3'); // 3 × 20
    await tester.enterText(find.widgetWithText(TextFormField, 'الخصم'), '10');
    await tester.pump();
    expect(find.text(Formatters.currency(250)), findsOneWidget);

    await tester.tap(find.text('دفع الكل'));
    await tester.pump();
    expect(
      tester
          .widget<TextFormField>(
            find.widgetWithText(TextFormField, 'المبلغ المحصَّل'),
          )
          .controller!
          .text,
      '250.00',
    );
  });

  testWidgets('confirming sends the sale for this technician', (tester) async {
    final repo = _FakeRepo();
    await _open(tester, repo);
    await _addFromBag(tester, qty: '1');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'اسم العميل'),
      'حسن',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'المبلغ المحصَّل'),
      '60',
    );
    await tester.tap(find.text('تأكيد البيع'));
    await tester.pumpAndSettle();

    final call = repo.calls.single;
    expect(call.technicianId, 't1');
    expect(call.customerName, 'حسن');
    expect(call.items.single.productId, 'p1');
    expect(call.items.single.unitPrice, isNull);
    expect(call.method, PaymentMethod.cash);
    expect(call.paid, 60, reason: 'the rest stays owed');
    expect(call.maintenanceRequestId, isNull);
    expect(find.text('افتح'), findsOneWidget, reason: 'closed after the sale');
  });

  testWidgets('a service carries its agreed price', (tester) async {
    final repo = _FakeRepo();
    await _open(tester, repo);
    await tester.tap(find.text('خدمة'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'سعر الخدمة'), '120');
    await tester.tap(find.text('إضافة').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('تأكيد البيع'));
    await tester.pumpAndSettle();
    expect(repo.calls.single.items.single.unitPrice, 120);
  });

  testWidgets('a maintenance invoice is linked to its job and customer', (
    tester,
  ) async {
    final repo = _FakeRepo();
    await _open(tester, repo, maintenanceRequestId: 'm7', customerName: 'سارة');
    expect(find.text('فاتورة الصيانة'), findsOneWidget);
    await _addFromBag(tester, qty: '1');
    await tester.tap(find.text('تأكيد البيع'));
    await tester.pumpAndSettle();
    expect(repo.calls.single.maintenanceRequestId, 'm7');
    expect(repo.calls.single.customerName, 'سارة');
  });

  testWidgets('nothing to sell, nothing sent', (tester) async {
    final repo = _FakeRepo();
    await _open(tester, repo);
    await tester.tap(find.text('تأكيد البيع'));
    await tester.pumpAndSettle();
    expect(find.text('أضف منتجًا واحدًا على الأقل'), findsOneWidget);
    expect(repo.calls, isEmpty);
  });

  testWidgets('a refusal stays on the sale with its message, and a retry '
      'reuses the same request id', (tester) async {
    final repo = _FakeRepo()
      ..error = const AppException('المبلغ المحصَّل أكبر من إجمالي الفاتورة');
    await _open(tester, repo);
    await _addFromBag(tester, qty: '1');
    await tester.tap(find.text('تأكيد البيع'));
    await tester.pumpAndSettle();
    expect(
      find.text('المبلغ المحصَّل أكبر من إجمالي الفاتورة'),
      findsOneWidget,
    );
    repo.error = null;
    await tester.tap(find.text('تأكيد البيع'));
    await tester.pumpAndSettle();
    expect(repo.calls[1].requestId, repo.calls[0].requestId);
  });

  testWidgets('money fields take only money', (tester) async {
    await _open(tester, _FakeRepo());
    await tester.enterText(find.widgetWithText(TextFormField, 'الخصم'), '5x');
    await tester.pump();
    expect(
      tester
          .widget<TextFormField>(find.widgetWithText(TextFormField, 'الخصم'))
          .controller!
          .text,
      '5',
    );
  });
}
