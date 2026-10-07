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
import 'package:steam_gallery_app/features/inventory/data/models/warehouse_stock_item.dart';
import 'package:steam_gallery_app/features/inventory/presentation/providers/inventory_providers.dart';
import 'package:steam_gallery_app/features/products/data/models/product.dart';
import 'package:steam_gallery_app/features/products/presentation/providers/product_providers.dart';
import 'package:steam_gallery_app/features/sales/data/models/invoice_line.dart';
import 'package:steam_gallery_app/features/sales/data/repositories/sales_repository.dart';
import 'package:steam_gallery_app/features/sales/presentation/providers/sales_providers.dart';
import 'package:steam_gallery_app/features/sales/presentation/screens/admin/admin_sale_invoice_screen.dart';
import 'package:steam_gallery_app/features/technician_account/data/models/sale.dart';

import 'helpers/test_outbox.dart';

Sale _sale({
  SaleStatus status = SaleStatus.completed,
  PaymentMethod method = PaymentMethod.cash,
}) => Sale(
  id: 's1',
  saleNumber: 12,
  customerName: 'أحمد',
  paymentMethod: method,
  subtotal: 300,
  discount: 20,
  total: 280,
  paidAmount: 280,
  status: status,
  createdAt: DateTime(2026, 10, 7, 10),
);

const _lines = [
  InvoiceLine(
    productId: 'p1',
    productName: 'مكواة',
    quantity: 2,
    unitPrice: 100,
  ),
  InvoiceLine(
    productId: 'p2',
    productName: 'قاعدة',
    quantity: 1,
    unitPrice: 100,
  ),
];

WarehouseStockItem _stock(String id, String name, int qty, double price) =>
    WarehouseStockItem(
      productId: id,
      productName: name,
      sku: id,
      quantity: qty,
      costPrice: price / 2,
      sellingPrice: price,
      minStock: 0,
    );

final _service = Product(
  id: 'svc',
  sku: 'SERVICE-MAINT',
  name: 'صيانة',
  specs: const {},
  costPrice: 0,
  sellingPrice: 0,
  minStock: 0,
  isActive: true,
  isService: true,
  createdAt: DateTime(2026),
);

typedef _EditCall = ({
  List<InvoiceLine> items,
  double? discount,
  CashboxKind? kind,
});
typedef _DeleteCall = ({String reason, CashboxKind? kind});

class _FakeSalesRepo implements SalesRepository {
  final edits = <_EditCall>[];
  final deletes = <_DeleteCall>[];
  OutboxResult result = const OutboxResult.done(null);
  Object? error;

  @override
  Future<OutboxResult> editSale({
    required String saleId,
    required int saleNumber,
    required List<InvoiceLine> items,
    double? discount,
    CashboxKind? moneyKind,
  }) async {
    edits.add((items: [...items], discount: discount, kind: moneyKind));
    if (error != null) throw error!;
    return result;
  }

  @override
  Future<OutboxResult> deleteSale({
    required String saleId,
    required int saleNumber,
    required String reason,
    CashboxKind? refundKind,
  }) async {
    deletes.add((reason: reason, kind: refundKind));
    if (error != null) throw error!;
    return result;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Opens the editor the way the invoice list does — pushed on top of
/// another screen, which it pops back to after saving.
Future<void> _open(
  WidgetTester tester,
  _FakeSalesRepo repo, {
  Sale? sale,
  Outbox? outbox,
}) async {
  await tester.binding.setSurfaceSize(const Size(700, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        salesRepositoryProvider.overrideWithValue(repo),
        outboxProvider.overrideWithValue(outbox ?? testOutbox()),
        walkInSalesProvider.overrideWith((ref) async => [sale ?? _sale()]),
        invoiceLinesProvider('s1').overrideWith((ref) async => _lines),
        warehouseStockProvider().overrideWith(
          (ref) async => [
            _stock('p1', 'مكواة', 1, 100),
            _stock('p2', 'قاعدة', 0, 100),
            _stock('p6', 'فلتر', 5, 20),
          ],
        ),
        assemblyStockProvider.overrideWith((ref) async => []),
        serviceProductsProvider.overrideWith((ref) async => [_service]),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AdminSaleInvoiceScreen(saleId: 's1'),
                  ),
                ),
                child: const Text('افتح الفاتورة'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('افتح الفاتورة'));
  await tester.pumpAndSettle();
}

String _saveLabel(double total) =>
    'حفظ التعديلات · ${Formatters.currency(total)}';

Finder _plus(String name) => find.descendant(
  of: find.widgetWithText(ListTile, name),
  matching: find.byIcon(Iconsax.add_circle_copy),
);

Finder _minus(String name) => find.descendant(
  of: find.widgetWithText(ListTile, name),
  matching: find.byIcon(Iconsax.minus_cirlce_copy),
);

Future<void> _saveAndConfirm(WidgetTester tester, double total) async {
  await tester.tap(find.text(_saveLabel(total)));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => initializeDateFormatting('ar'));

  testWidgets('opens on the invoice as the server has it', (tester) async {
    await _open(tester, _FakeSalesRepo());
    expect(find.text('فاتورة #12'), findsOneWidget);
    expect(find.text('العميل: أحمد'), findsOneWidget);
    expect(find.text('مكواة'), findsOneWidget);
    expect(find.text('قاعدة'), findsOneWidget);
    expect(find.text(Formatters.currency(300)), findsOneWidget);
    expect(find.text(_saveLabel(280)), findsOneWidget);
  });

  testWidgets('a quantity can grow up to what was sold plus what is in '
      'stock, no further', (tester) async {
    await _open(tester, _FakeSalesRepo());
    // 2 on the invoice + 1 in the warehouse = 3.
    await tester.tap(_plus('مكواة'));
    await tester.pump();
    expect(find.text(_saveLabel(380)), findsOneWidget);

    await tester.tap(_plus('مكواة'));
    await tester.pump();
    expect(find.text('المتاح بالمخزن لا يكفي'), findsOneWidget);
    expect(find.text(_saveLabel(380)), findsOneWidget);
  });

  testWidgets('down to zero, or the bin, takes a product off', (tester) async {
    await _open(tester, _FakeSalesRepo());
    await tester.tap(_minus('قاعدة'));
    await tester.pumpAndSettle();
    expect(find.text('قاعدة'), findsNothing);
    expect(find.text(_saveLabel(180)), findsOneWidget);

    await tester.tap(find.byTooltip('حذف الصنف'));
    await tester.pumpAndSettle();
    expect(find.text('لا توجد أصناف'), findsOneWidget);
  });

  testWidgets('adding from the list: a new product, then the same again', (
    tester,
  ) async {
    await _open(tester, _FakeSalesRepo());
    await tester.tap(find.text('إضافة صنف'));
    await tester.pumpAndSettle();
    expect(find.text('إضافة صنف للفاتورة'), findsOneWidget);
    // Out of stock and not on the invoice: listed but can't be picked.
    expect(
      tester
          .widget<ListTile>(find.widgetWithText(ListTile, 'قاعدة').last)
          .enabled,
      isFalse,
    );
    await tester.tap(find.text('فلتر'));
    await tester.pumpAndSettle();
    expect(find.text(_saveLabel(300)), findsOneWidget);

    await tester.tap(find.text('إضافة صنف'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('فلتر').last);
    await tester.pumpAndSettle();
    expect(find.text(_saveLabel(320)), findsOneWidget, reason: '2 × 20');
  });

  testWidgets('a service is added at the price typed for it', (tester) async {
    await _open(tester, _FakeSalesRepo());
    await tester.tap(find.text('إضافة صنف'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('صيانة'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'سعر الخدمة'), '50');
    await tester.tap(find.text('إضافة'));
    await tester.pumpAndSettle();
    expect(find.text(_saveLabel(330)), findsOneWidget);
  });

  testWidgets('a discount above the total is not saved', (tester) async {
    final repo = _FakeSalesRepo();
    await _open(tester, repo);
    await tester.enterText(find.widgetWithText(TextField, 'الخصم'), '400');
    await tester.pump();
    await tester.tap(find.textContaining('حفظ التعديلات'));
    await tester.pumpAndSettle();
    expect(find.text('قيمة الخصم غير صحيحة'), findsOneWidget);
    expect(repo.edits, isEmpty);
  });

  testWidgets('an emptied invoice is not saved (deleting is separate)', (
    tester,
  ) async {
    final repo = _FakeSalesRepo();
    await _open(tester, repo);
    await tester.tap(find.byTooltip('حذف الصنف').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('حذف الصنف').first);
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('حفظ التعديلات'));
    await tester.pumpAndSettle();
    expect(find.textContaining('الفاتورة فاضية'), findsOneWidget);
    expect(repo.edits, isEmpty);
  });

  testWidgets('more on the invoice: collects the difference into the chosen '
      'till and sends the invoice\'s final content', (tester) async {
    final repo = _FakeSalesRepo();
    await _open(tester, repo);
    await tester.tap(_plus('مكواة'));
    await tester.pump();
    await _saveAndConfirm(tester, 380);

    expect(
      find.text('هيتم تحصيل ${Formatters.currency(100)} من العميل'),
      findsOneWidget,
    );
    // Paid in cash, so the cash till is suggested; switch to transfer.
    await tester.tap(find.text('تحويل'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('حفظ'));
    await tester.pumpAndSettle();

    final edit = repo.edits.single;
    expect(edit.kind, CashboxKind.transfer);
    expect(edit.discount, 20);
    expect(edit.items.map((l) => (l.productId, l.quantity)).toList(), [
      ('p1', 3),
      ('p2', 1),
    ]);
    expect(find.text('تم حفظ تعديل الفاتورة'), findsOneWidget);
    expect(find.text('افتح الفاتورة'), findsOneWidget, reason: 'popped back');
  });

  testWidgets('less on the invoice: refunds the difference', (tester) async {
    final repo = _FakeSalesRepo();
    await _open(tester, repo);
    await tester.enterText(find.widgetWithText(TextField, 'الخصم'), '50');
    await tester.pump();
    expect(find.text('فرق يُرد للعميل: ${Formatters.currency(30)}'), findsOne);
    await _saveAndConfirm(tester, 250);
    expect(
      find.text('هيتم رد ${Formatters.currency(30)} للعميل'),
      findsOneWidget,
    );
    await tester.tap(find.text('حفظ'));
    await tester.pumpAndSettle();
    expect(repo.edits.single.discount, 50);
    expect(repo.edits.single.kind, CashboxKind.cash);
  });

  testWidgets('no money difference: no till to choose', (tester) async {
    await _open(tester, _FakeSalesRepo());
    await _saveAndConfirm(tester, 280);
    expect(find.text('لا يوجد فرق في الفلوس'), findsOneWidget);
    expect(find.text('كاش'), findsNothing);
  });

  testWidgets('backing out of the save dialog sends nothing', (tester) async {
    final repo = _FakeSalesRepo();
    await _open(tester, repo);
    await _saveAndConfirm(tester, 280);
    await tester.tap(find.text('رجوع'));
    await tester.pumpAndSettle();
    expect(repo.edits, isEmpty);
    expect(find.text('فاتورة #12'), findsOneWidget);
  });

  testWidgets('a server refusal stays on the invoice with its message', (
    tester,
  ) async {
    final repo = _FakeSalesRepo()
      ..error = const AppException('الكمية المطلوبة غير متوفرة');
    await _open(tester, repo);
    await _saveAndConfirm(tester, 280);
    await tester.tap(find.text('حفظ'));
    await tester.pumpAndSettle();
    expect(find.text('الكمية المطلوبة غير متوفرة'), findsOneWidget);
    expect(find.text('فاتورة #12'), findsOneWidget);
  });

  testWidgets('saved offline: says so', (tester) async {
    final repo = _FakeSalesRepo()..result = const OutboxResult.queued();
    await _open(tester, repo);
    await _saveAndConfirm(tester, 280);
    await tester.tap(find.text('حفظ'));
    await tester.pumpAndSettle();
    expect(find.textContaining('التعديل اتسجل على الجهاز'), findsOneWidget);
  });

  testWidgets('deleting refunds the whole invoice from the chosen till', (
    tester,
  ) async {
    final repo = _FakeSalesRepo();
    await _open(tester, repo, sale: _sale(method: PaymentMethod.transfer));
    await tester.tap(find.byTooltip('حذف الفاتورة'));
    await tester.pumpAndSettle();
    expect(find.text('حذف فاتورة #12'), findsOneWidget);
    expect(find.textContaining(Formatters.currency(280)), findsWidgets);

    await tester.enterText(find.widgetWithText(TextField, 'السبب'), 'غلط');
    await tester.tap(find.text('حذف'));
    await tester.pumpAndSettle();
    expect(repo.deletes.single.reason, 'غلط');
    expect(
      repo.deletes.single.kind,
      CashboxKind.transfer,
      reason: 'paid by transfer, refunded from the transfer till',
    );
    expect(find.text('تم حذف الفاتورة'), findsOneWidget);
  });

  testWidgets('deleting without a reason still records one', (tester) async {
    final repo = _FakeSalesRepo();
    await _open(tester, repo);
    await tester.tap(find.byTooltip('حذف الفاتورة'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('حذف'));
    await tester.pumpAndSettle();
    expect(repo.deletes.single.reason, 'حذف فاتورة');
    expect(repo.deletes.single.kind, CashboxKind.cash);
  });

  testWidgets('a cancelled invoice is read-only', (tester) async {
    await _open(
      tester,
      _FakeSalesRepo(),
      sale: _sale(status: SaleStatus.cancelled),
    );
    expect(find.text('الحالة: ملغي'), findsOneWidget);
    expect(find.text('× 2'), findsOneWidget);
    expect(find.textContaining('حفظ التعديلات'), findsNothing);
    expect(find.byTooltip('حذف الفاتورة'), findsNothing);
    expect(find.text('إضافة صنف'), findsNothing);
  });

  testWidgets('a delete waiting offline locks the invoice', (tester) async {
    final server = FakeServer()..online = false;
    final outbox = testOutbox(server: server);
    await outbox.submit(
      rpc: 'rpc_admin_delete_sale',
      params: const {},
      label: 'حذف فاتورة #12',
      kind: 'sale_delete',
      refId: 's1',
    );
    await _open(tester, _FakeSalesRepo(), outbox: outbox);
    expect(find.text('الفاتورة هتتحذف أول ما النت يرجع'), findsOneWidget);
    expect(find.textContaining('حفظ التعديلات'), findsNothing);
  });

  testWidgets('an edit waiting offline is where the next edit starts', (
    tester,
  ) async {
    final server = FakeServer()..online = false;
    final outbox = testOutbox(server: server);
    await outbox.submit(
      rpc: 'rpc_admin_edit_sale',
      params: const {},
      label: 'تعديل فاتورة #12',
      kind: 'sale_edit',
      refId: 's1',
      meta: {
        'lines': [_lines.first.copyWith(quantity: 1).toJson()],
        'discount': 0,
      },
    );
    await _open(tester, _FakeSalesRepo(), outbox: outbox);
    expect(find.text('بتعدل على آخر تعديل لسه مستني المزامنة'), findsOne);
    expect(find.text('قاعدة'), findsNothing);
    expect(find.text(_saveLabel(100)), findsOneWidget);
  });
}
