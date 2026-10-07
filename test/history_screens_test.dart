import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:steam_gallery_app/core/router/route_names.dart';
import 'package:steam_gallery_app/core/theme/app_theme.dart';
import 'package:steam_gallery_app/core/utils/history_query.dart';
import 'package:steam_gallery_app/features/auth/data/models/app_user.dart';
import 'package:steam_gallery_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:steam_gallery_app/features/maintenance/data/models/maintenance_request.dart';
import 'package:steam_gallery_app/features/maintenance/data/repositories/maintenance_repository.dart';
import 'package:steam_gallery_app/features/maintenance/presentation/providers/maintenance_providers.dart';
import 'package:steam_gallery_app/features/maintenance/presentation/screens/admin/admin_maintenance_history_screen.dart';
import 'package:steam_gallery_app/features/maintenance/presentation/screens/admin/admin_maintenance_list_screen.dart';
import 'package:steam_gallery_app/features/orders/data/models/order.dart';
import 'package:steam_gallery_app/features/orders/data/repositories/order_repository.dart';
import 'package:steam_gallery_app/features/orders/presentation/providers/order_providers.dart';
import 'package:steam_gallery_app/features/orders/presentation/screens/admin/admin_orders_history_screen.dart';
import 'package:steam_gallery_app/features/orders/presentation/screens/admin/admin_orders_list_screen.dart';

Order _order(int n, OrderStatus status) => Order.fromRow({
  'id': 'o$n',
  'order_number': n,
  'customer_id': 'c1',
  'status': status.name,
  'subtotal': 100,
  'discount': 0,
  'total': 100,
  'paid_amount': 0,
  'payment_status': 'unpaid',
  'delivery_recipient_name': 'عميل $n',
  'created_at': '2026-09-01T10:00:00Z',
});

MaintenanceRequest _request(int n, String status) =>
    MaintenanceRequest.fromRow({
      'id': 'm$n',
      'ticket_number': n,
      'customer_id': 'c1',
      'customer_name': 'عميل صيانة $n',
      'phone': '0100000000$n',
      'problem_description': 'عطل',
      'status': status,
      'created_at': '2026-09-01T10:00:00Z',
    });

class _FakeOrderRepo implements OrderRepository {
  final searches = <({HistoryQuery query, int offset})>[];

  /// Total results the "server" has for any search.
  int available = 45;

  @override
  Future<List<Order>> searchOrders(
    HistoryQuery query, {
    required int limit,
    required int offset,
  }) async {
    searches.add((query: query, offset: offset));
    final count = (available - offset).clamp(0, limit);
    return [
      for (var i = 0; i < count; i++)
        _order(1000 - offset - i, OrderStatus.completed),
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeMaintenanceRepo implements MaintenanceRepository {
  final searches = <HistoryQuery>[];

  @override
  Future<List<MaintenanceRequest>> searchRequests(
    HistoryQuery query, {
    required int limit,
    required int offset,
  }) async {
    searches.add(query);
    return [_request(5, 'completed')];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _admin = AppUser(
  id: 'a1',
  role: AppRole.admin,
  fullName: 'أدمن',
  isActive: true,
);

Widget _app(Widget home, List overrides) => ProviderScope(
  overrides: [
    currentUserProfileProvider.overrideWith((ref) async => _admin),
    ...overrides,
  ],
  child: MaterialApp(theme: AppTheme.light(), home: home),
);

void main() {
  setUpAll(() => initializeDateFormatting('ar'));

  group('سجل الطلبات', () {
    testWidgets('opens on the newest orders, a page at a time', (tester) async {
      final repo = _FakeOrderRepo();
      await tester.binding.setSurfaceSize(const Size(500, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        _app(const AdminOrdersHistoryScreen(), [
          orderRepositoryProvider.overrideWithValue(repo),
        ]),
      );
      await tester.pumpAndSettle();
      expect(find.text('طلب #1000'), findsOneWidget);
      expect(repo.searches.single.offset, 0);

      // Scrolling to the end loads the next page, and stops when done.
      await tester.drag(find.byType(ListView), const Offset(0, -20000));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView), const Offset(0, -20000));
      await tester.pumpAndSettle();
      expect(repo.searches.map((s) => s.offset), [0, 30]);
      expect(find.text('طلب #956'), findsOneWidget, reason: 'the 45th');
    });

    testWidgets('typing searches once the typing pauses', (tester) async {
      final repo = _FakeOrderRepo();
      await tester.pumpWidget(
        _app(const AdminOrdersHistoryScreen(), [
          orderRepositoryProvider.overrideWithValue(repo),
        ]),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'م');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(find.byType(TextField), 'منى');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(repo.searches.map((s) => s.query.text), ['', 'منى']);
    });

    testWidgets('nothing found says so', (tester) async {
      final repo = _FakeOrderRepo()..available = 0;
      await tester.pumpWidget(
        _app(const AdminOrdersHistoryScreen(), [
          orderRepositoryProvider.overrideWithValue(repo),
        ]),
      );
      await tester.pumpAndSettle();
      expect(find.text('لا توجد طلبات مطابقة'), findsOneWidget);
    });
  });

  testWidgets('سجل الصيانة: searches by ticket, name or phone', (tester) async {
    final repo = _FakeMaintenanceRepo();
    await tester.pumpWidget(
      _app(const AdminMaintenanceHistoryScreen(), [
        maintenanceRepositoryProvider.overrideWithValue(repo),
      ]),
    );
    await tester.pumpAndSettle();
    expect(find.text('عميل صيانة 5'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '#5');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(repo.searches.last.number, 5);
  });

  group('the working lists', () {
    GoRouter router(Widget list, String path, String historyPath) => GoRouter(
      initialLocation: path,
      routes: [
        GoRoute(
          path: path,
          builder: (_, _) => list,
          routes: [
            GoRoute(
              path: historyPath.substring(path.length + 1),
              builder: (_, _) => const Scaffold(body: Text('صفحة السجل')),
            ),
          ],
        ),
      ],
    );

    testWidgets('orders: open ones and today\'s, with the history a tap '
        'away', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProfileProvider.overrideWith((ref) async => _admin),
            openOrdersProvider.overrideWith(
              (ref) => Stream.value([
                _order(3, OrderStatus.pending),
                _order(2, OrderStatus.completed),
              ]),
            ),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light(),
            routerConfig: router(
              const AdminOrdersListScreen(),
              Routes.adminOrders,
              Routes.adminOrdersHistory,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('طلب #3'), findsOneWidget);
      expect(find.text('طلب #2'), findsOneWidget);
      await tester.tap(find.text('السجل'));
      await tester.pumpAndSettle();
      expect(find.text('صفحة السجل'), findsOneWidget);
    });

    testWidgets('maintenance: the active queue, with the history a tap away', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            openMaintenanceRequestsProvider.overrideWith(
              (ref) => Stream.value([
                _request(1, 'waiting'),
                _request(2, 'completed'),
              ]),
            ),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light(),
            routerConfig: router(
              const AdminMaintenanceListScreen(),
              Routes.adminMaintenance,
              Routes.adminMaintenanceHistory,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('عميل صيانة 1'), findsOneWidget);
      // "النشط" is the default: today's finished one is under its status.
      expect(find.text('عميل صيانة 2'), findsNothing);
      await tester.tap(find.text('السجل'));
      await tester.pumpAndSettle();
      expect(find.text('صفحة السجل'), findsOneWidget);
    });
  });
}
