import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:steam_gallery_app/core/errors/app_exception.dart';
import 'package:steam_gallery_app/core/offline/network_status.dart';
import 'package:steam_gallery_app/core/theme/app_theme.dart';
import 'package:steam_gallery_app/features/auth/data/models/app_user.dart';
import 'package:steam_gallery_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:steam_gallery_app/features/inventory/data/models/technician_bag_stock_item.dart';
import 'package:steam_gallery_app/features/inventory/data/repositories/inventory_repository.dart';
import 'package:steam_gallery_app/features/inventory/presentation/providers/inventory_providers.dart';
import 'package:steam_gallery_app/features/inventory/presentation/screens/technician/technician_bag_transfer_screen.dart';

typedef _Call = ({
  BagTransferDirection direction,
  List<({String productId, int quantity})> items,
  String requestId,
});

class _FakeRepo implements InventoryRepository {
  final calls = <_Call>[];
  Object? error;

  @override
  Future<List<BagTransferStock>> getWarehouseStockForTechnician() async => [
    (productId: 'p1', productName: 'مكواة', sku: 'S1', quantity: 4),
    (productId: 'p2', productName: 'فلتر', sku: 'S2', quantity: 1),
  ];

  @override
  Future<List<TechnicianBagStockItem>> getBagStock(String technicianId) async =>
      [
        const TechnicianBagStockItem(
          productId: 'p3',
          productName: 'خرطوم',
          sku: 'S3',
          quantity: 2,
          costPrice: 10,
          sellingPrice: 20,
        ),
      ];

  @override
  Future<void> transferBagStock({
    required BagTransferDirection direction,
    required List<({String productId, int quantity})> items,
    required String clientRequestId,
    String? notes,
  }) async {
    calls.add((direction: direction, items: items, requestId: clientRequestId));
    if (error != null) throw error!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _open(WidgetTester tester, _FakeRepo repo) async {
  await tester.binding.setSurfaceSize(const Size(500, 1000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        inventoryRepositoryProvider.overrideWithValue(repo),
        currentUserProfileProvider.overrideWith(
          (ref) async => const AppUser(
            id: 'tech-1',
            role: AppRole.technician,
            fullName: 'محمود',
            isActive: true,
          ),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const TechnicianBagTransferScreen(),
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

Future<void> _plus(WidgetTester tester, String name, [int times = 1]) async {
  for (var i = 0; i < times; i++) {
    await tester.tap(
      find.descendant(
        of: find.widgetWithText(ListTile, name),
        matching: find.byTooltip('أكتر'),
      ),
    );
    await tester.pump();
  }
}

Future<void> _send(WidgetTester tester) async {
  await tester.tap(find.textContaining('تحويل 1 صنف'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('حوّل'));
  await tester.pumpAndSettle();
}

void main() {
  tearDown(NetworkStatus.instance.markOnline);

  testWidgets('warehouse → bag, sent at once', (tester) async {
    final repo = _FakeRepo();
    await _open(tester, repo);
    expect(find.text('المتاح: 4'), findsOneWidget);

    await _plus(tester, 'مكواة', 2);
    await _send(tester);

    expect(repo.calls, hasLength(1));
    expect(repo.calls.single.direction, BagTransferDirection.toBag);
    expect(repo.calls.single.items, [(productId: 'p1', quantity: 2)]);
    expect(find.byType(TechnicianBagTransferScreen), findsNothing);
  });

  testWidgets("can't pick more than is there", (tester) async {
    final repo = _FakeRepo();
    await _open(tester, repo);
    await _plus(tester, 'فلتر', 3);
    final line = find.widgetWithText(ListTile, 'فلتر');
    expect(find.descendant(of: line, matching: find.text('1')), findsOneWidget);
  });

  testWidgets('bag → warehouse lists the bag', (tester) async {
    final repo = _FakeRepo();
    await _open(tester, repo);
    await tester.tap(find.text('من شنطتي للمخزن'));
    await tester.pumpAndSettle();
    expect(find.text('خرطوم'), findsOneWidget);
    expect(find.text('مكواة'), findsNothing);

    await _plus(tester, 'خرطوم');
    await _send(tester);
    expect(repo.calls.single.direction, BagTransferDirection.toWarehouse);
    expect(repo.calls.single.items, [(productId: 'p3', quantity: 1)]);
  });

  testWidgets('a refusal is shown; retrying sends the same request id', (
    tester,
  ) async {
    final repo = _FakeRepo()
      ..error = const AppException('الكمية المطلوبة غير متوفرة');
    await _open(tester, repo);
    await _plus(tester, 'مكواة');
    await _send(tester);
    expect(find.text('الكمية المطلوبة غير متوفرة'), findsOneWidget);
    expect(find.byType(TechnicianBagTransferScreen), findsOneWidget);

    // Let the message go away so it doesn't cover the button.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    // The same transfer again (say the first answer was lost): same id, so
    // the server moves it once.
    repo.error = null;
    await _send(tester);
    expect(repo.calls, hasLength(2));
    expect(repo.calls[1].requestId, repo.calls[0].requestId);
    expect(find.byType(TechnicianBagTransferScreen), findsNothing);
  });

  testWidgets('changing a quantity makes it a new transfer', (tester) async {
    final repo = _FakeRepo()..error = const AppException('x');
    await _open(tester, repo);
    await _plus(tester, 'مكواة');
    await _send(tester);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    repo.error = null;
    await _plus(tester, 'مكواة');
    await _send(tester);
    expect(repo.calls[1].requestId, isNot(repo.calls[0].requestId));
    expect(repo.calls[1].items, [(productId: 'p1', quantity: 2)]);
  });

  testWidgets('needs a connection', (tester) async {
    final repo = _FakeRepo();
    await _open(tester, repo);
    await _plus(tester, 'مكواة');
    NetworkStatus.instance.markOffline();
    await tester.tap(find.textContaining('تحويل 1 صنف'));
    await tester.pumpAndSettle();
    expect(find.text('التحويل محتاج نت'), findsOneWidget);
    expect(repo.calls, isEmpty);
  });
}
