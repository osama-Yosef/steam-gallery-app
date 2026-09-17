import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:steam_gallery_app/core/theme/app_theme.dart';
import 'package:steam_gallery_app/features/notifications/presentation/providers/notification_providers.dart';
import 'package:steam_gallery_app/features/products/data/models/catalog_query.dart';
import 'package:steam_gallery_app/features/products/data/models/product_category.dart';
import 'package:steam_gallery_app/features/products/data/models/product_image.dart';
import 'package:steam_gallery_app/features/products/data/models/product_public.dart';
import 'package:steam_gallery_app/features/products/data/repositories/product_repository.dart';
import 'package:steam_gallery_app/features/products/presentation/providers/product_providers.dart';
import 'package:steam_gallery_app/features/products/presentation/screens/customer/customer_catalog_screen.dart';

ProductPublic _product(
  String id, {
  double price = 100,
  bool available = true,
  String? categoryId,
}) => ProductPublic(
  id: id,
  sku: 'SKU-$id',
  name: 'منتج $id',
  categoryId: categoryId,
  specs: const {'القدرة': '2400 وات'},
  sellingPrice: price,
  isAvailable: available,
  createdAt: DateTime(2026, 9, 1),
);

ProductCategory _cat(String id, String name, {String? parent}) =>
    ProductCategory(
      id: id,
      name: name,
      parentId: parent,
      sortOrder: 0,
      isActive: true,
    );

/// Serves [total] products in pages and records every browse call.
class _FakeRepo implements ProductRepository {
  _FakeRepo({this.total = 0, this.categories = const []});

  final int total;
  final List<ProductCategory> categories;
  final calls = <({CatalogQuery query, int limit, int offset})>[];

  @override
  Future<List<ProductPublic>> browseCatalog(
    CatalogQuery query, {
    required int limit,
    required int offset,
  }) async {
    calls.add((query: query, limit: limit, offset: offset));
    final end = (offset + limit).clamp(0, total);
    return [for (var i = offset; i < end; i++) _product('$i')];
  }

  @override
  Future<List<ProductCategory>> getCategories({
    bool activeOnly = false,
  }) async => categories;

  @override
  Future<ProductPublic?> getProductPublicById(String id) async => null;

  @override
  Future<List<ProductImage>> getProductImages(String productId) async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _pump(
  WidgetTester tester,
  _FakeRepo repo,
  Widget screen, {
  List overrides = const [],
}) async {
  await tester.binding.setSurfaceSize(const Size(420, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        productRepositoryProvider.overrideWithValue(repo),
        unreadNotificationCountProvider.overrideWith((ref) => 0),
        ...overrides,
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: Directionality(textDirection: TextDirection.rtl, child: screen),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('CatalogQuery', () {
    test('is value-equal, so identical filters reuse loaded pages', () {
      expect(
        const CatalogQuery(categoryId: 'c', sort: CatalogSort.priceAsc),
        const CatalogQuery(categoryId: 'c', sort: CatalogSort.priceAsc),
      );
    });

    test('maps to the RPC parameters; blank search is no search', () {
      final p = const CatalogQuery(
        search: '   ',
        minPrice: 10,
        availableOnly: true,
        sort: CatalogSort.priceDesc,
      ).toRpcParams(limit: 20, offset: 40);
      expect(p['p_search'], isNull);
      expect(p['p_min_price'], 10);
      expect(p['p_max_price'], isNull);
      expect(p['p_available_only'], isTrue);
      expect(p['p_sort'], 'price_desc');
      expect(p['p_limit'], 20);
      expect(p['p_offset'], 40);
      expect(
        const CatalogQuery(
          search: ' مكواة ',
        ).toRpcParams(limit: 1, offset: 0)['p_search'],
        'مكواة',
      );
    });

    test('sort values are exactly the ones the RPC accepts', () {
      expect(CatalogSort.values.map((s) => s.rpcValue).toSet(), {
        'newest',
        'price_asc',
        'price_desc',
        'name',
      });
    });

    test('filter counts', () {
      expect(const CatalogQuery().hasAnyFilter, isFalse);
      expect(const CatalogQuery(sort: CatalogSort.name).hasAnyFilter, isFalse);
      expect(
        const CatalogQuery(
          minPrice: 1,
          maxPrice: 9,
          availableOnly: true,
        ).sheetFilterCount,
        2,
      );
      expect(const CatalogQuery(search: 'x').hasAnyFilter, isTrue);
    });

    test('price range validation mirrors INVALID_PRICE_RANGE', () {
      expect(priceRangeError(null, null), isNull);
      expect(priceRangeError(10, 10), isNull);
      expect(priceRangeError(20, 10), isNotNull);
      expect(priceRangeError(-1, null), isNotNull);
    });
  });

  group('Categories', () {
    test('groups roots and children; orphans become roots', () {
      final g = groupCategories([
        _cat('a', 'مكاوي'),
        _cat('b', 'مكاوي بخار', parent: 'a'),
        _cat('c', 'فرعي لقسم مخفي', parent: 'hidden'),
      ]);
      expect(g.roots.map((c) => c.id), ['a', 'c']);
      expect(g.children['a']!.map((c) => c.id), ['b']);
    });

    test('CategoryInput validation', () {
      expect(const CategoryInput(name: 'مكاوي').error, isNull);
      expect(const CategoryInput(name: '  ').error, isNotNull);
      expect(CategoryInput(name: 'x' * 61).error, isNotNull);
      expect(
        const CategoryInput(id: 'a', name: 'x', parentId: 'a').error,
        isNotNull,
      );
    });
  });

  group('CustomerCatalogScreen', () {
    testWidgets('loads the first page only, then the next on demand', (
      tester,
    ) async {
      final repo = _FakeRepo(total: catalogPageSize + 5);
      await _pump(tester, repo, const CustomerCatalogScreen());

      expect(repo.calls, hasLength(1));
      expect(repo.calls.single.offset, 0);
      expect(repo.calls.single.limit, catalogPageSize);
      expect(find.text('يتم عرض $catalogPageSize منتج'), findsOneWidget);

      await tester.drag(
        find.byKey(const Key('catalog-grid')),
        const Offset(0, -4000),
      );
      await tester.pumpAndSettle();
      // Scrolling near the end already requested page 2.
      expect(repo.calls.last.offset, catalogPageSize);
      expect(find.text('${catalogPageSize + 5} منتج'), findsOneWidget);
      expect(
        repo.calls.where((c) => c.offset == catalogPageSize),
        hasLength(1),
      );
    });

    testWidgets('search is debounced and sent to the server', (tester) async {
      final repo = _FakeRepo(total: 3);
      await _pump(tester, repo, const CustomerCatalogScreen());

      await tester.enterText(find.byKey(const Key('catalog-search')), 'مك');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(find.byKey(const Key('catalog-search')), 'مكواة');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      final searches = repo.calls.map((c) => c.query.search).toList();
      expect(searches, [null, 'مكواة']);
    });

    testWidgets('category chips filter, with a sub-category row', (
      tester,
    ) async {
      final repo = _FakeRepo(
        total: 2,
        categories: [
          _cat('a', 'مكاوي'),
          _cat('b', 'بخار', parent: 'a'),
        ],
      );
      await _pump(tester, repo, const CustomerCatalogScreen());
      expect(find.text('بخار'), findsNothing);

      await tester.tap(find.text('مكاوي'));
      await tester.pumpAndSettle();
      expect(repo.calls.last.query.categoryId, 'a');
      expect(find.text('بخار'), findsOneWidget);

      await tester.tap(find.text('بخار'));
      await tester.pumpAndSettle();
      expect(repo.calls.last.query.categoryId, 'b');
    });

    testWidgets('filter sheet applies price and availability', (tester) async {
      final repo = _FakeRepo(total: 2);
      await _pump(tester, repo, const CustomerCatalogScreen());

      await tester.tap(find.byKey(const Key('catalog-filter')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('filter-min-price')), '500');
      await tester.enterText(find.byKey(const Key('filter-max-price')), '100');
      await tester.tap(find.text('عرض النتائج'));
      await tester.pumpAndSettle();
      expect(find.text('أقل سعر يجب ألا يتجاوز أعلى سعر'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('filter-max-price')), '900');
      await tester.tap(find.text('المتاح فقط'));
      await tester.tap(find.text('عرض النتائج'));
      await tester.pumpAndSettle();

      final q = repo.calls.last.query;
      expect((q.minPrice, q.maxPrice, q.availableOnly), (500, 900, true));
      expect(find.text('2'), findsOneWidget); // badge: price + availability
    });

    testWidgets('empty results offer to clear filters', (tester) async {
      final repo = _FakeRepo(total: 0);
      await _pump(
        tester,
        repo,
        const CustomerCatalogScreen(initialCategoryId: 'a'),
      );
      expect(find.text('لا توجد منتجات مطابقة'), findsOneWidget);
      await tester.tap(find.text('مسح البحث والفلاتر'));
      await tester.pumpAndSettle();
      expect(repo.calls.last.query.categoryId, isNull);
      expect(find.text('لا توجد منتجات بعد'), findsOneWidget);
    });
  });
}
