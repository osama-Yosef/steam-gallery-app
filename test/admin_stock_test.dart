import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:steam_gallery_app/core/errors/app_exception.dart';
import 'package:steam_gallery_app/core/theme/app_theme.dart';
import 'package:steam_gallery_app/features/inventory/data/models/warehouse_stock_item.dart';
import 'package:steam_gallery_app/features/inventory/data/repositories/inventory_repository.dart';
import 'package:steam_gallery_app/features/inventory/presentation/providers/inventory_providers.dart';
import 'package:steam_gallery_app/features/inventory/presentation/screens/admin/admin_issue_stock_screen.dart';
import 'package:steam_gallery_app/features/inventory_count/data/models/inventory_count.dart';
import 'package:steam_gallery_app/features/inventory_count/data/models/inventory_count_item.dart';
import 'package:steam_gallery_app/features/inventory_count/data/repositories/inventory_count_repository.dart';
import 'package:steam_gallery_app/features/inventory_count/presentation/providers/inventory_count_providers.dart';
import 'package:steam_gallery_app/features/inventory_count/presentation/screens/admin/admin_inventory_count_detail_screen.dart';
import 'package:steam_gallery_app/features/maintenance/data/models/technician_option.dart';
import 'package:steam_gallery_app/features/maintenance/presentation/providers/maintenance_providers.dart';

WarehouseStockItem _stock(String id, String name, int qty) =>
    WarehouseStockItem(
      productId: id,
      productName: name,
      sku: 'SKU-$id',
      quantity: qty,
      costPrice: 10,
      sellingPrice: 20,
      minStock: 0,
    );

class _FakeInventoryRepo implements InventoryRepository {
  final issues =
      <
        ({String technicianId, List<({String productId, int quantity})> items})
      >[];
  Object? error;

  @override
  Future<void> issueStock({
    required String technicianId,
    required List<({String productId, int quantity})> items,
    String? notes,
  }) async {
    if (error != null) throw error!;
    issues.add((technicianId: technicianId, items: items));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeCountRepo implements InventoryCountRepository {
  final saved = <({String itemId, int qty, String? reason})>[];
  int completed = 0;

  @override
  Future<void> saveItem({
    required String itemId,
    required int actualQuantity,
    String? reason,
    String? notes,
  }) async => saved.add((itemId: itemId, qty: actualQuantity, reason: reason));

  @override
  Future<void> completeCount(String countId) async => completed++;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _pushed(WidgetTester tester, Widget screen, List overrides) async {
  await tester.binding.setSurfaceSize(const Size(600, 1200));
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

  group('صرف لصنايعي', () {
    List overrides(_FakeInventoryRepo repo) => [
      inventoryRepositoryProvider.overrideWithValue(repo),
      assignableTechniciansProvider.overrideWith(
        (ref) async => const [
          TechnicianOption(id: 't1', fullName: 'محمود', employeeCode: 'T-01'),
        ],
      ),
      warehouseStockProvider().overrideWith(
        (ref) async => [
          _stock('p1', 'مكواة', 4),
          _stock('p2', 'فلتر', 0),
          _stock('p3', 'قاعدة', 2),
        ],
      ),
    ];

    Future<void> addLine(WidgetTester tester, String qty) async {
      await tester.tap(find.text('إضافة'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'الكمية'), qty);
      await tester.tap(find.text('إضافة').last);
      await tester.pumpAndSettle();
    }

    testWidgets('needs a technician first', (tester) async {
      final repo = _FakeInventoryRepo();
      await _pushed(tester, const AdminIssueStockScreen(), overrides(repo));
      await addLine(tester, '1');
      await tester.tap(find.text('تأكيد الصرف'));
      await tester.pumpAndSettle();
      expect(find.text('اختر الصنايعي أولًا'), findsOneWidget);
      expect(repo.issues, isEmpty);
    });

    testWidgets('can\'t issue more than the warehouse has', (tester) async {
      final repo = _FakeInventoryRepo();
      await _pushed(tester, const AdminIssueStockScreen(), overrides(repo));
      await addLine(tester, '5');
      expect(find.text('كمية غير صحيحة'), findsOneWidget);
      expect(find.text('لم تُضف منتجات بعد'), findsOneWidget);
    });

    testWidgets('issues the chosen products to the chosen technician', (
      tester,
    ) async {
      final repo = _FakeInventoryRepo();
      await _pushed(tester, const AdminIssueStockScreen(), overrides(repo));
      await tester.tap(find.text('الصنايعي'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('محمود (T-01)').last);
      await tester.pumpAndSettle();
      await addLine(tester, '3');
      // The same product can't be added twice; the next pick offers the rest
      // (and never the one with nothing left).
      await tester.tap(find.text('إضافة'));
      await tester.pumpAndSettle();
      expect(find.textContaining('فلتر'), findsNothing);
      await tester.tap(find.text('إضافة').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('تأكيد الصرف'));
      await tester.pumpAndSettle();
      final issue = repo.issues.single;
      expect(issue.technicianId, 't1');
      expect(issue.items.map((i) => (i.productId, i.quantity)).toList(), [
        ('p1', 3),
        ('p3', 1),
      ]);
      expect(find.text('افتح'), findsOneWidget, reason: 'closed after issuing');
    });

    testWidgets('a refusal keeps the form with its message', (tester) async {
      final repo = _FakeInventoryRepo()
        ..error = const AppException('الكمية المطلوبة غير متوفرة');
      await _pushed(tester, const AdminIssueStockScreen(), overrides(repo));
      await tester.tap(find.text('الصنايعي'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('محمود (T-01)').last);
      await tester.pumpAndSettle();
      await addLine(tester, '1');
      await tester.tap(find.text('تأكيد الصرف'));
      await tester.pumpAndSettle();
      expect(find.text('الكمية المطلوبة غير متوفرة'), findsOneWidget);
    });
  });

  group('الجرد', () {
    InventoryCountItem item(
      String id,
      String name,
      int system, {
      int? actual,
      String? reason,
    }) => InventoryCountItem(
      id: id,
      productId: 'p-$id',
      productName: name,
      sku: 'SKU-$id',
      systemQuantity: system,
      actualQuantity: actual,
      difference: actual == null ? 0 : actual - system,
      reason: reason,
    );

    List overrides(
      _FakeCountRepo repo, {
      InventoryCountStatus status = InventoryCountStatus.draft,
    }) => [
      inventoryCountRepositoryProvider.overrideWithValue(repo),
      inventoryCountDetailProvider('k1').overrideWith(
        (ref) async => InventoryCount(
          id: 'k1',
          countNumber: 3,
          status: status,
          startedAt: DateTime(2026, 10, 1),
        ),
      ),
      inventoryCountItemsProvider('k1').overrideWith(
        (ref) async => [
          item('a', 'مكواة', 10, actual: 8, reason: 'تالف'),
          item('b', 'فلتر', 5),
        ],
      ),
    ];

    testWidgets('shows progress and each difference', (tester) async {
      await _pushed(
        tester,
        const AdminInventoryCountDetailScreen(countId: 'k1'),
        overrides(_FakeCountRepo()),
      );
      expect(find.text('1 / 2 مُدخَل'), findsOneWidget);
      expect(find.text('8 (-2)'), findsOneWidget);
    });

    testWidgets('a counted quantity that differs needs a reason', (
      tester,
    ) async {
      final repo = _FakeCountRepo();
      await _pushed(
        tester,
        const AdminInventoryCountDetailScreen(countId: 'k1'),
        overrides(repo),
      );
      await tester.tap(find.text('فلتر'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'الكمية الفعلية'),
        '7',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('حفظ'));
      await tester.pumpAndSettle();
      expect(repo.saved, isEmpty, reason: 'no reason given yet');

      await tester.enterText(
        find.widgetWithText(TextField, 'سبب الفرق (مطلوب)'),
        'وصل زيادة',
      );
      await tester.tap(find.text('حفظ'));
      await tester.pumpAndSettle();
      expect(repo.saved.single, (itemId: 'b', qty: 7, reason: 'وصل زيادة'));
    });

    testWidgets('matching the system needs no reason', (tester) async {
      final repo = _FakeCountRepo();
      await _pushed(
        tester,
        const AdminInventoryCountDetailScreen(countId: 'k1'),
        overrides(repo),
      );
      await tester.tap(find.text('فلتر'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('حفظ'));
      await tester.pumpAndSettle();
      expect(repo.saved.single.qty, 5);
      expect(repo.saved.single.reason, isNull);
    });

    testWidgets('approving warns about uncounted items first', (tester) async {
      final repo = _FakeCountRepo();
      await _pushed(
        tester,
        const AdminInventoryCountDetailScreen(countId: 'k1'),
        overrides(repo),
      );
      await tester.tap(find.text('اعتماد الجرد'));
      await tester.pumpAndSettle();
      expect(find.textContaining('يوجد 1 صنف لم تُدخَل'), findsOneWidget);
      await tester.tap(find.text('تأكيد'));
      await tester.pumpAndSettle();
      expect(repo.completed, 1);
    });

    testWidgets('an approved count is read-only', (tester) async {
      await _pushed(
        tester,
        const AdminInventoryCountDetailScreen(countId: 'k1'),
        overrides(_FakeCountRepo(), status: InventoryCountStatus.completed),
      );
      expect(find.text('اعتماد الجرد'), findsNothing);
      await tester.tap(find.text('فلتر'));
      await tester.pumpAndSettle();
      expect(find.text('حفظ'), findsNothing, reason: 'no edit dialog');
    });
  });
}
