import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:steam_gallery_app/core/theme/app_colors.dart';
import 'package:steam_gallery_app/core/theme/app_theme.dart';
import 'package:steam_gallery_app/core/utils/formatters.dart';
import 'package:steam_gallery_app/features/inventory/data/models/warehouse_stock_item.dart';
import 'package:steam_gallery_app/features/inventory/presentation/providers/inventory_providers.dart';
import 'package:steam_gallery_app/features/products/data/models/product.dart';
import 'package:steam_gallery_app/features/products/presentation/providers/product_providers.dart';
import 'package:steam_gallery_app/features/products/presentation/screens/admin/admin_price_list_screen.dart';

Product _product(
  String id,
  String name, {
  double cost = 10,
  double price = 20,
  bool active = true,
  bool service = false,
  bool assembly = false,
}) => Product(
  id: id,
  sku: 'SKU-$id',
  name: name,
  specs: const {},
  costPrice: cost,
  sellingPrice: price,
  minStock: 0,
  isActive: active,
  isService: service,
  isAssembly: assembly,
  createdAt: DateTime(2026),
);

WarehouseStockItem _stock(String id, int qty, {bool assembly = false}) =>
    WarehouseStockItem(
      productId: id,
      productName: id,
      sku: id,
      quantity: qty,
      costPrice: 1,
      sellingPrice: 1,
      minStock: 0,
      isAssembly: assembly,
    );

Future<void> _pump(
  WidgetTester tester,
  List<Product> products, {
  Size size = const Size(800, 1200),
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        adminProductsProvider().overrideWith((ref) async => products),
        warehouseStockProvider().overrideWith(
          (ref) async => [_stock('p1', 7), _stock('p2', 0)],
        ),
        assemblyStockProvider.overrideWith(
          (ref) async => [_stock('kit', 2, assembly: true)],
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: const AdminPriceListScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  final products = [
    _product('p2', 'فلتر', cost: 5, price: 12),
    _product('p1', 'مكواة', cost: 60, price: 100),
    _product('kit', 'طقم', cost: 70, price: 150, assembly: true),
    _product('svc', 'صيانة', service: true),
    _product('off', 'موقوف', active: false),
  ];

  testWidgets('every active stock product, sorted, with both prices and '
      'the quantity', (tester) async {
    await _pump(tester, products);
    expect(find.text('الصنف'), findsOneWidget);
    expect(find.text('سعر البيع'), findsOneWidget);
    expect(find.text('سعر الشراء'), findsOneWidget);
    expect(find.text('الموجود بالمخزن'), findsOneWidget);

    expect(find.text('مكواة'), findsOneWidget);
    expect(find.text(Formatters.currency(100)), findsOneWidget);
    expect(find.text(Formatters.currency(60)), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    // An assembly shows how many its components can build.
    expect(find.text('طقم'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    // Services and switched-off products aren't priced stock.
    expect(find.text('صيانة'), findsNothing);
    expect(find.text('موقوف'), findsNothing);

    final names = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data)
        .where((d) => d == 'طقم' || d == 'فلتر' || d == 'مكواة')
        .toList();
    expect(names, ['طقم', 'فلتر', 'مكواة'], reason: 'alphabetical');
  });

  testWidgets('out of stock is shown in red', (tester) async {
    await _pump(tester, products);
    final zero = tester.widget<Text>(find.text('0'));
    expect(zero.style?.color, AppColors.danger);
    expect(tester.widget<Text>(find.text('7')).style?.color, isNull);
  });

  testWidgets('search by name or SKU', (tester) async {
    await _pump(tester, products);
    await tester.enterText(find.byType(TextField), 'sku-p1');
    await tester.pumpAndSettle();
    expect(find.text('مكواة'), findsOneWidget);
    expect(find.text('فلتر'), findsNothing);

    await tester.enterText(find.byType(TextField), 'لا شيء');
    await tester.pumpAndSettle();
    expect(find.text('لا توجد نتائج لـ "لا شيء"'), findsOneWidget);
  });

  testWidgets('a long list is built as it scrolls, header always on top', (
    tester,
  ) async {
    final many = [
      for (var i = 0; i < 300; i++)
        _product('x$i', 'صنف ${i.toString().padLeft(3, '0')}'),
    ];
    await _pump(tester, many, size: const Size(800, 900));
    expect(find.text('صنف 000'), findsOneWidget);
    expect(
      find.text('صنف 299'),
      findsNothing,
      reason: 'rows off screen are not built',
    );
    await tester.drag(find.text('صنف 000'), const Offset(0, -30000));
    await tester.pumpAndSettle();
    expect(find.text('صنف 299'), findsOneWidget);
    expect(find.text('الصنف'), findsOneWidget, reason: 'header still shown');
  });

  testWidgets('on a phone the table scrolls sideways instead of squeezing', (
    tester,
  ) async {
    await _pump(tester, products, size: const Size(360, 800));
    expect(tester.takeException(), isNull);
    expect(find.text('الموجود بالمخزن'), findsOneWidget);
  });
}
