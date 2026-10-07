import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:steam_gallery_app/core/offline/outbox.dart';
import 'package:steam_gallery_app/core/theme/app_theme.dart';
import 'package:steam_gallery_app/features/products/data/models/assembly_component.dart';
import 'package:steam_gallery_app/features/products/data/models/product.dart';
import 'package:steam_gallery_app/features/products/data/models/product_category.dart';
import 'package:steam_gallery_app/features/products/data/models/product_image.dart';
import 'package:steam_gallery_app/features/products/data/models/product_option.dart';
import 'package:steam_gallery_app/features/products/data/repositories/product_repository.dart';
import 'package:steam_gallery_app/features/products/presentation/providers/product_providers.dart';
import 'package:steam_gallery_app/features/products/presentation/screens/admin/admin_product_form_screen.dart';

import 'helpers/test_outbox.dart';

/// An in-memory product store standing in for the database.
class _FakeProductRepo implements ProductRepository {
  final products = <String, Product>{};
  final options = <String, List<ProductOption>>{};
  final recipes = <String, List<AssemblyComponent>>{};
  var _nextId = 0;
  int setAssemblyCalls = 0;

  _FakeProductRepo() {
    for (final p in [
      _make('c1', 'مقبض', cost: 15),
      _make('c2', 'خزان', cost: 25),
    ]) {
      products[p.id] = p;
    }
  }

  static Product _make(
    String id,
    String name, {
    double cost = 10,
    double price = 20,
    bool assembly = false,
  }) => Product(
    id: id,
    sku: 'SKU-$id',
    name: name,
    specs: const {},
    costPrice: cost,
    sellingPrice: price,
    minStock: 0,
    isActive: true,
    isAssembly: assembly,
    createdAt: DateTime(2026),
  );

  @override
  Future<List<ProductCategory>> getCategories({
    bool activeOnly = false,
  }) async => const [];

  @override
  Future<List<Product>> listProductsAdmin({
    String? search,
    String? categoryId,
  }) async => products.values.toList();

  @override
  Future<Product?> getProductByIdAdmin(String id) async => products[id];

  @override
  Future<List<ProductOption>> getProductOptions(String productId) async =>
      options[productId] ?? const [];

  @override
  Future<List<AssemblyComponent>> getAssemblyComponents(
    String productId,
  ) async => recipes[productId] ?? const [];

  @override
  Future<List<ProductImage>> getProductImages(String productId) async =>
      const [];

  @override
  Future<String> createProduct({
    required String sku,
    String? barcode,
    String? categoryId,
    required String name,
    String? description,
    required Map<String, String> specs,
    required double costPrice,
    required double sellingPrice,
    required int minStock,
  }) async {
    final id = 'new${_nextId++}';
    products[id] = Product(
      id: id,
      sku: sku,
      barcode: barcode,
      name: name,
      description: description,
      specs: specs,
      costPrice: costPrice,
      sellingPrice: sellingPrice,
      minStock: minStock,
      isActive: true,
      createdAt: DateTime(2026),
    );
    return id;
  }

  @override
  Future<void> updateProduct(
    String id, {
    required String sku,
    String? barcode,
    String? categoryId,
    required String name,
    String? description,
    required Map<String, String> specs,
    required double costPrice,
    required double sellingPrice,
    required int minStock,
  }) async {
    products[id] = products[id]!.copyWith(
      sku: sku,
      name: name,
      costPrice: costPrice,
      sellingPrice: sellingPrice,
      minStock: minStock,
    );
  }

  @override
  Future<void> setProductActive(String id, bool isActive) async {
    products[id] = products[id]!.copyWith(isActive: isActive);
  }

  /// Same semantics as the real one: rows without an id are inserted,
  /// rows with one updated, and anything not sent is deleted.
  @override
  Future<void> saveProductOptions(
    String productId,
    List<ProductOptionInput> input,
  ) async {
    final keep = input.map((o) => o.id).whereType<String>().toSet();
    final current = [
      for (final o in options[productId] ?? const <ProductOption>[])
        if (keep.contains(o.id)) o,
    ];
    for (var i = 0; i < input.length; i++) {
      final o = input[i];
      final row = ProductOption(
        id: o.id ?? 'opt${_nextId++}',
        productId: productId,
        name: o.name,
        extraPrice: o.extraPrice,
        sortOrder: i,
      );
      final at = current.indexWhere((c) => c.id == row.id);
      if (at >= 0) {
        current[at] = row;
      } else {
        current.add(row);
      }
    }
    options[productId] = current;
  }

  @override
  Future<void> setAssembly(
    String productId, {
    required bool isAssembly,
    required List<AssemblyComponent> components,
  }) async {
    setAssemblyCalls++;
    final ids = components.map((c) => c.productId).toList();
    if (ids.toSet().length != ids.length) {
      throw Exception('duplicate component');
    }
    recipes[productId] = isAssembly ? [...components] : [];
    products[productId] = products[productId]!.copyWith(isAssembly: isAssembly);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _open(
  WidgetTester tester,
  _FakeProductRepo repo, {
  String? productId,
}) async {
  await tester.binding.setSurfaceSize(const Size(700, 2400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        productRepositoryProvider.overrideWithValue(repo),
        outboxProvider.overrideWithValue(testOutbox()),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: AdminProductFormScreen(productId: productId),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _fillBasics(WidgetTester tester) async {
  await tester.enterText(
    find.widgetWithText(TextFormField, 'اسم المنتج'),
    ' مكواة جديدة ',
  );
  await tester.enterText(find.widgetWithText(TextFormField, 'SKU'), 'IR-9');
  await tester.enterText(
    find.widgetWithText(TextFormField, 'سعر التكلفة'),
    '60',
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, 'سعر البيع'),
    '100',
  );
}

Future<void> _save(WidgetTester tester) async {
  await tester.tap(find.byType(FilledButton).last);
  await tester.pumpAndSettle();
}

/// What each option's name field shows on screen.
List<String> _optionTexts(WidgetTester tester) => tester
    .widgetList<EditableText>(
      find.descendant(
        of: find.widgetWithText(TextFormField, 'الخيار'),
        matching: find.byType(EditableText),
      ),
    )
    .map((e) => e.controller.text)
    .toList();

Future<void> _addOption(WidgetTester tester, String name, String price) async {
  await tester.tap(find.text('إضافة خيار'));
  await tester.pumpAndSettle();
  await tester.enterText(
    find.widgetWithText(TextFormField, 'الخيار').last,
    name,
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, 'سعر إضافي').last,
    price,
  );
}

void main() {
  setUpAll(() => initializeDateFormatting('ar'));

  testWidgets('required fields are checked before anything is saved', (
    tester,
  ) async {
    final repo = _FakeProductRepo();
    await _open(tester, repo);
    await _save(tester);
    expect(repo.products.length, 2, reason: 'nothing created');
    expect(find.textContaining('اسم المنتج'), findsWidgets);
  });

  testWidgets('creating a product saves it and turns the form into edit mode', (
    tester,
  ) async {
    final repo = _FakeProductRepo();
    await _open(tester, repo);
    expect(find.text('منتج جديد'), findsOneWidget);
    await _fillBasics(tester);
    await _save(tester);

    final created = repo.products['new0']!;
    expect(created.name, 'مكواة جديدة');
    expect(created.sku, 'IR-9');
    expect(created.costPrice, 60);
    expect(created.sellingPrice, 100);
    expect(find.text('تعديل المنتج'), findsOneWidget);
    expect(find.text('الصور'), findsOneWidget, reason: 'images now allowed');
  });

  testWidgets('options added while creating show once afterwards, and '
      'saving again doesn\'t duplicate them', (tester) async {
    final repo = _FakeProductRepo();
    await _open(tester, repo);
    await _fillBasics(tester);
    await _addOption(tester, 'بخار إضافي', '15');
    await _save(tester);

    expect(_optionTexts(tester), ['بخار إضافي']);
    await _save(tester);
    await _save(tester);
    expect(repo.options['new0']!.map((o) => o.name), ['بخار إضافي']);
  });

  testWidgets('removing an option removes that one, on screen and saved', (
    tester,
  ) async {
    final repo = _FakeProductRepo();
    await _open(tester, repo);
    await _fillBasics(tester);
    await _addOption(tester, 'أحمر', '0');
    await _addOption(tester, 'أزرق', '5');
    await tester.tap(find.byIcon(Iconsax.minus_cirlce_copy).first);
    await tester.pumpAndSettle();
    expect(_optionTexts(tester), ['أزرق']);

    await _save(tester);
    expect(repo.options['new0']!.map((o) => o.name), ['أزرق']);
  });

  testWidgets('an assembly needs at least one component', (tester) async {
    final repo = _FakeProductRepo();
    await _open(tester, repo);
    await _fillBasics(tester);
    await tester.tap(find.text('صنف تجميع'));
    await tester.pumpAndSettle();
    await _save(tester);
    expect(
      find.text('صنف التجميع لازم يكون له مكون واحد على الأقل'),
      findsOneWidget,
    );
    expect(repo.products.containsKey('new0'), isFalse);
  });

  testWidgets('an assembly is costed from its components, which show once '
      'after creating and can be saved again', (tester) async {
    final repo = _FakeProductRepo();
    await _open(tester, repo);
    await _fillBasics(tester);
    await tester.tap(find.text('صنف تجميع'));
    await tester.pumpAndSettle();
    for (final name in ['مقبض', 'خزان']) {
      await tester.tap(find.text('إضافة مكون'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(name).last);
      await tester.pumpAndSettle();
    }
    await _save(tester);

    expect(repo.products['new0']!.costPrice, 40, reason: '15 + 25');
    expect(repo.recipes['new0']!.map((c) => c.productId), ['c1', 'c2']);
    expect(find.text('مقبض'), findsOneWidget);
    expect(find.text('خزان'), findsOneWidget);

    await _save(tester);
    expect(find.textContaining('duplicate'), findsNothing);
    expect(repo.recipes['new0']!.map((c) => c.productId), ['c1', 'c2']);
  });

  testWidgets('editing loads the product and saves the changes', (
    tester,
  ) async {
    final repo = _FakeProductRepo();
    repo.options['c1'] = const [
      ProductOption(
        id: 'o1',
        productId: 'c1',
        name: 'لون',
        extraPrice: 3,
        sortOrder: 0,
      ),
    ];
    await _open(tester, repo, productId: 'c1');
    expect(find.text('تعديل المنتج'), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(
            find.widgetWithText(TextFormField, 'اسم المنتج'),
          )
          .controller!
          .text,
      'مقبض',
    );
    expect(_optionTexts(tester), ['لون']);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'سعر البيع'),
      '35',
    );
    await tester.tap(find.text('المنتج نشط'));
    await tester.pumpAndSettle();
    await _save(tester);

    expect(repo.products['c1']!.sellingPrice, 35);
    expect(repo.products['c1']!.isActive, isFalse);
    expect(repo.options['c1']!.single.id, 'o1', reason: 'kept, not recreated');
    expect(find.text('تم حفظ التعديلات'), findsOneWidget);
  });
}
