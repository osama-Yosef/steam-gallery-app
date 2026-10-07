import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:steam_gallery_app/core/errors/app_exception.dart';
import 'package:steam_gallery_app/core/offline/outbox.dart';
import 'package:steam_gallery_app/core/theme/app_theme.dart';
import 'package:steam_gallery_app/core/utils/formatters.dart';
import 'package:steam_gallery_app/features/inventory/data/models/warehouse_stock_item.dart';
import 'package:steam_gallery_app/features/inventory/presentation/providers/inventory_providers.dart';
import 'package:steam_gallery_app/features/products/data/models/product.dart';
import 'package:steam_gallery_app/features/products/presentation/providers/product_providers.dart';
import 'package:steam_gallery_app/features/sales/data/models/sale_line_input.dart';
import 'package:steam_gallery_app/features/sales/data/repositories/sales_repository.dart';
import 'package:steam_gallery_app/features/sales/presentation/providers/sales_providers.dart';
import 'package:steam_gallery_app/features/sales/presentation/screens/admin/admin_walk_in_sale_screen.dart';
import 'package:steam_gallery_app/features/technician_account/data/models/sale.dart';

import 'helpers/test_outbox.dart';

WarehouseStockItem _stock(
  String id,
  String name,
  int qty,
  double price, {
  String? sku,
  double? offerPrice,
  bool assembly = false,
}) => WarehouseStockItem(
  productId: id,
  productName: name,
  sku: sku ?? 'SKU-$id',
  quantity: qty,
  costPrice: price / 2,
  sellingPrice: price,
  minStock: 0,
  effectivePrice: offerPrice,
  isAssembly: assembly,
);

typedef _SaleCall = ({
  String? customerName,
  String? customerPhone,
  List<SaleLineInput> items,
  PaymentMethod paymentMethod,
  double discount,
  String clientRequestId,
  String? notes,
});

class _FakeSalesRepo implements SalesRepository {
  final calls = <_SaleCall>[];
  OutboxResult result = const OutboxResult.done(null);
  Object? error;

  @override
  Future<OutboxResult> recordWalkInSale({
    String? customerName,
    String? customerPhone,
    required List<SaleLineInput> items,
    required PaymentMethod paymentMethod,
    required double discount,
    required String clientRequestId,
    String? notes,
  }) async {
    calls.add((
      customerName: customerName,
      customerPhone: customerPhone,
      items: items,
      paymentMethod: paymentMethod,
      discount: discount,
      clientRequestId: clientRequestId,
      notes: notes,
    ));
    if (error != null) throw error!;
    return result;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final _iron = _stock('p1', 'مكواة بخار', 2, 100);
final _base = _stock('p2', 'قاعدة مكواة', 5, 40, sku: 'BASE-9');
final _empty = _stock('p3', 'خرطوم', 0, 15);
final _kit = _stock('p4', 'طقم كامل', 3, 300, assembly: true);
final _offer = _stock('p5', 'فلتر', 10, 20, offerPrice: 15);

final _service = Product(
  id: 'svc',
  sku: 'SERVICE-MAINT',
  name: 'صيانة مكواة',
  specs: const {},
  createdAt: DateTime(2026),
  costPrice: 0,
  sellingPrice: 0,
  minStock: 0,
  isActive: true,
  isService: true,
);

Future<void> _pump(
  WidgetTester tester,
  _FakeSalesRepo repo, {
  Outbox? outbox,
  List<WarehouseStockItem>? stock,
}) async {
  await tester.binding.setSurfaceSize(const Size(900, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        salesRepositoryProvider.overrideWithValue(repo),
        outboxProvider.overrideWithValue(outbox ?? testOutbox()),
        warehouseStockProvider().overrideWith(
          (ref) async => stock ?? [_iron, _base, _empty, _offer],
        ),
        assemblyStockProvider.overrideWith((ref) async => [_kit]),
        serviceProductsProvider.overrideWith((ref) async => [_service]),
        walkInSalesProvider.overrideWith((ref) async => <Sale>[]),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: const Directionality(
          textDirection: TextDirection.rtl,
          child: AdminWalkInSaleScreen(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _confirmButton() => find.byWidgetPredicate(
  (w) => w is FilledButton,
  description: 'confirm sale button',
);

String _confirmLabel(double total) =>
    'تأكيد البيع · ${Formatters.currency(total)}';

Future<void> _openCart(WidgetTester tester) async {
  await tester.tap(find.textContaining('السلة ('));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => initializeDateFormatting('ar'));

  testWidgets('shows only products in stock, assemblies marked', (
    tester,
  ) async {
    await _pump(tester, _FakeSalesRepo());
    expect(find.text('مكواة بخار'), findsOneWidget);
    expect(find.text('قاعدة مكواة'), findsOneWidget);
    expect(find.text('طقم كامل (تجميع)'), findsOneWidget);
    expect(find.text('خرطوم'), findsNothing, reason: 'out of stock');
    // The confirm button is disabled until something is added.
    expect(tester.widget<FilledButton>(_confirmButton()).onPressed, isNull);
  });

  testWidgets('search matches name or SKU', (tester) async {
    await _pump(tester, _FakeSalesRepo());
    await tester.enterText(find.byType(TextField).at(2), 'base-9');
    await tester.pumpAndSettle();
    expect(find.text('قاعدة مكواة'), findsOneWidget);
    expect(find.text('مكواة بخار'), findsNothing);

    await tester.enterText(find.byType(TextField).at(2), 'لا يوجد');
    await tester.pumpAndSettle();
    expect(find.text('لا توجد نتائج لـ "لا يوجد"'), findsOneWidget);
  });

  testWidgets('tapping adds one, again adds another, never past stock', (
    tester,
  ) async {
    await _pump(tester, _FakeSalesRepo());
    await tester.tap(find.text('مكواة بخار'));
    await tester.pump();
    expect(find.text(_confirmLabel(100)), findsOneWidget);

    await tester.tap(find.text('مكواة بخار'));
    await tester.pump();
    expect(find.text(_confirmLabel(200)), findsOneWidget);
    expect(find.text('السلة (2 صنف)'), findsOneWidget);

    // Only 2 in stock: a third tap is refused with the reason.
    await tester.tap(find.text('مكواة بخار'));
    await tester.pump();
    expect(find.text('المتاح بالمخزن 2 فقط'), findsOneWidget);
    expect(find.text(_confirmLabel(200)), findsOneWidget);
  });

  testWidgets('a live offer price is what the register charges', (
    tester,
  ) async {
    await _pump(tester, _FakeSalesRepo());
    await tester.tap(find.text('فلتر'));
    await tester.pump();
    expect(find.text(_confirmLabel(15)), findsOneWidget);
  });

  testWidgets('cart: minus/plus change the quantity, minus to 0 removes', (
    tester,
  ) async {
    await _pump(tester, _FakeSalesRepo());
    await tester.tap(find.text('قاعدة مكواة'));
    await tester.pump();
    await _openCart(tester);

    await tester.tap(find.byIcon(Iconsax.add_circle_copy).first);
    await tester.pump();
    expect(find.text(_confirmLabel(80)), findsOneWidget);

    await tester.tap(find.byIcon(Iconsax.minus_cirlce_copy).first);
    await tester.tap(find.byIcon(Iconsax.minus_cirlce_copy).first);
    await tester.pumpAndSettle();
    expect(find.textContaining('السلة ('), findsNothing);
    expect(tester.widget<FilledButton>(_confirmButton()).onPressed, isNull);
  });

  testWidgets('the discount comes off the total', (tester) async {
    await _pump(tester, _FakeSalesRepo());
    await tester.tap(find.text('مكواة بخار'));
    await tester.pump();
    await tester.enterText(find.widgetWithText(TextField, 'الخصم'), '30');
    await tester.pump();
    expect(find.text(_confirmLabel(70)), findsOneWidget);
  });

  testWidgets('the discount field only takes a money amount', (tester) async {
    await _pump(tester, _FakeSalesRepo());
    await tester.enterText(find.widgetWithText(TextField, 'الخصم'), '1x0');
    await tester.pump();
    final field = tester.widget<TextField>(
      find.widgetWithText(TextField, 'الخصم'),
    );
    expect(field.controller!.text, isNot(contains('x')));
  });

  testWidgets('a discount above the total is refused, nothing is sent', (
    tester,
  ) async {
    final repo = _FakeSalesRepo();
    await _pump(tester, repo);
    await tester.tap(find.text('قاعدة مكواة'));
    await tester.pump();
    await tester.enterText(find.widgetWithText(TextField, 'الخصم'), '50');
    await tester.pump();
    await tester.tap(_confirmButton());
    await tester.pump();
    expect(find.text('الخصم أكبر من إجمالي الفاتورة'), findsOneWidget);
    expect(repo.calls, isEmpty);
  });

  testWidgets('confirming sends exactly what was rung up, then starts a new '
      'sale with a new idempotency key', (tester) async {
    final repo = _FakeSalesRepo();
    await _pump(tester, repo);

    await tester.enterText(
      find.widgetWithText(TextField, 'اسم العميل (اختياري)'),
      ' أحمد ',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'رقم الهاتف (اختياري)'),
      '01012345678',
    );
    await tester.tap(find.text('مكواة بخار'));
    await tester.tap(find.text('قاعدة مكواة'));
    await tester.tap(find.text('قاعدة مكواة'));
    await tester.pump();
    await tester.enterText(find.widgetWithText(TextField, 'الخصم'), '10');
    await tester.pump();

    // Pay by transfer instead of the default cash.
    await tester.tap(find.text('نقدًا'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('تحويل').last);
    await tester.pumpAndSettle();

    expect(find.text(_confirmLabel(170)), findsOneWidget);
    await tester.tap(_confirmButton());
    await tester.pumpAndSettle();

    final call = repo.calls.single;
    expect(call.customerName, 'أحمد');
    expect(call.customerPhone, '01012345678');
    expect(call.paymentMethod, PaymentMethod.transfer);
    expect(call.discount, 10);
    expect(call.notes, isNull);
    expect(
      call.items.map((i) => (i.productId, i.quantity, i.unitPrice)).toList(),
      [('p1', 1, null), ('p2', 2, null)],
      reason: 'stock products never carry a client price',
    );
    expect(find.text('تم تسجيل البيع بنجاح'), findsOneWidget);

    // The register is clean for the next customer…
    expect(find.textContaining('السلة ('), findsNothing);
    expect(
      tester
          .widget<TextField>(
            find.widgetWithText(TextField, 'اسم العميل (اختياري)'),
          )
          .controller!
          .text,
      isEmpty,
    );

    // …and the next sale can't be mistaken for a resend of this one.
    await tester.tap(find.text('مكواة بخار'));
    await tester.pump();
    await tester.tap(_confirmButton());
    await tester.pumpAndSettle();
    expect(repo.calls, hasLength(2));
    expect(repo.calls[1].clientRequestId, isNot(repo.calls[0].clientRequestId));
    expect(repo.calls[1].paymentMethod, PaymentMethod.cash);
    expect(repo.calls[1].discount, 0);
  });

  testWidgets('offline: the sale is saved on the device and says so', (
    tester,
  ) async {
    final repo = _FakeSalesRepo()..result = const OutboxResult.queued();
    await _pump(tester, repo);
    await tester.tap(find.text('مكواة بخار'));
    await tester.pump();
    await tester.tap(_confirmButton());
    await tester.pumpAndSettle();
    expect(find.textContaining('البيع اتسجل على الجهاز'), findsOneWidget);
  });

  testWidgets('a server refusal shows its message and keeps the cart', (
    tester,
  ) async {
    final repo = _FakeSalesRepo()
      ..error = const AppException('الكمية المطلوبة غير متوفرة');
    await _pump(tester, repo);
    await tester.tap(find.text('مكواة بخار'));
    await tester.pump();
    await tester.tap(_confirmButton());
    await tester.pumpAndSettle();
    expect(find.text('الكمية المطلوبة غير متوفرة'), findsOneWidget);
    expect(find.text(_confirmLabel(100)), findsOneWidget);
    expect(tester.widget<FilledButton>(_confirmButton()).onPressed, isNotNull);
  });

  testWidgets('sales still waiting offline are taken off what can be sold', (
    tester,
  ) async {
    final server = FakeServer()..online = false;
    final outbox = testOutbox(server: server);
    await outbox.submit(
      rpc: 'rpc_admin_walk_in_sale',
      params: {
        'p_items': [
          {'product_id': 'p1', 'quantity': 1},
        ],
      },
      label: 'بيع مباشر',
      kind: 'walk_in_sale',
    );
    await _pump(tester, _FakeSalesRepo(), outbox: outbox);
    expect(find.text('متاح 1'), findsOneWidget, reason: '2 in stock − 1');

    await tester.tap(find.text('مكواة بخار'));
    await tester.tap(find.text('مكواة بخار'));
    await tester.pump();
    expect(find.text('المتاح بالمخزن 1 فقط'), findsOneWidget);
  });

  testWidgets('a service line carries the price agreed with the customer', (
    tester,
  ) async {
    final repo = _FakeSalesRepo();
    await _pump(tester, repo);
    await tester.tap(find.text('خدمة'));
    await tester.pumpAndSettle();
    expect(find.text('إضافة خدمة'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'سعر الخدمة'), '75');
    await tester.tap(find.text('إضافة'));
    await tester.pumpAndSettle();
    expect(find.text(_confirmLabel(75)), findsOneWidget);

    await tester.tap(_confirmButton());
    await tester.pumpAndSettle();
    final item = repo.calls.single.items.single;
    expect(item.productId, 'svc');
    expect(item.unitPrice, 75);
  });

  testWidgets('a service without a valid price is not added', (tester) async {
    await _pump(tester, _FakeSalesRepo());
    await tester.tap(find.text('خدمة'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('إضافة'));
    await tester.pumpAndSettle();
    expect(find.text('أدخل سعرًا صحيحًا'), findsOneWidget);
    expect(find.textContaining('السلة ('), findsNothing);
  });

  testWidgets('opens on the invoices tab when asked', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          salesRepositoryProvider.overrideWithValue(_FakeSalesRepo()),
          outboxProvider.overrideWithValue(testOutbox()),
          warehouseStockProvider().overrideWith((ref) async => [_iron]),
          assemblyStockProvider.overrideWith((ref) async => []),
          walkInSalesProvider.overrideWith((ref) async => <Sale>[]),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const AdminWalkInSaleScreen(showInvoices: true),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('لا توجد فواتير اليوم'), findsOneWidget);
    // The checkout bar belongs to the sale tab only.
    expect(_confirmButton(), findsNothing);
  });
}
