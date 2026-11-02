import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:steam_gallery_app/core/offline/outbox.dart';
import 'package:steam_gallery_app/core/theme/app_theme.dart';
import 'package:steam_gallery_app/core/utils/formatters.dart';
import 'package:steam_gallery_app/features/reports/data/models/report_models.dart';
import 'package:steam_gallery_app/features/reports/data/repositories/reports_repository.dart';
import 'package:steam_gallery_app/features/reports/presentation/providers/reports_providers.dart';
import 'package:steam_gallery_app/features/reports/presentation/screens/admin_report_detail_screen.dart';

import 'helpers/test_outbox.dart';

const _rpc = <String, dynamic>{
  'month': '2026-10-01',
  'sales': 505,
  'sales_walk_in': 280,
  'sales_technician': 100,
  'sales_online': 125,
  'invoices': 4,
  'cost': 200,
  'gross_profit': 305,
  'expenses': 150,
  'expense_categories': [
    {'name': 'مرتبات', 'total': 100},
    {'name': 'كهرباء', 'total': 50},
  ],
  'net_profit': 155,
  'purchases': 800,
  'purchase_invoices': 1,
  'supplier_payments': 400,
  'supplier_debt': 400,
  'supplier_debts': [
    {'name': 'مورد', 'balance': 400},
  ],
  'stock_warehouse': 520,
  'stock_bags': 80,
};

class _FakeRepo implements ReportsRepository {
  final asked = <DateTime>[];

  @override
  Future<MonthReport> getMonthReport(DateTime month) async {
    asked.add(month);
    return MonthReport.fromRpc(
      _rpc,
      stockOverMonth: StockValue.pairFromRpc({
        'start_at': '2026-09-30T21:00:00Z',
        'end_at': '2026-10-31T22:00:00Z',
        'start': {'warehouse': 1000, 'bags': 200},
        'end': {'warehouse': 1350, 'bags': 250},
      }),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<_FakeRepo> _open(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(500, 1500));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final repo = _FakeRepo();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        reportsRepositoryProvider.overrideWithValue(repo),
        outboxProvider.overrideWithValue(testOutbox()),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: const AdminReportDetailScreen(reportType: 'month'),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  setUpAll(() => initializeDateFormatting('ar'));

  test('reads what the server sends', () {
    final r = MonthReport.fromRpc(_rpc);
    expect(r.month, DateTime(2026, 10));
    expect(r.expenseCategories.first.categoryName, 'مرتبات');
    expect(r.supplierDebts.single.balance, 400);
    expect(r.stockTotal, 600);
  });

  testWidgets('shows everything the owner asked for', (tester) async {
    await _open(tester);
    for (final label in [
      'مبيعات الشهر',
      'تكلفة المبيعات',
      'مصاريف الشهر',
      'مشتريات الشهر (1 فاتورة)',
      'دفعات الشهر',
      'باقي ديون علينا',
      'جرد المخزن',
      'إجمالي الأرباح (المبيعات − التكلفة)',
      'الأرباح الصافية (بعد المصاريف)',
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    expect(find.textContaining('305'), findsOneWidget);
    expect(find.textContaining('155'), findsOneWidget);
  });

  testWidgets('the stock on the 1st of the month and at its end (0096)', (
    tester,
  ) async {
    await _open(tester);
    expect(find.text('رصيد المخزن بالتكلفة'), findsOneWidget);
    expect(find.textContaining('أول الشهر'), findsOneWidget);
    expect(find.textContaining('1,200'), findsOneWidget);
    expect(find.textContaining('1,600'), findsOneWidget);
    expect(find.textContaining('400'), findsWidgets);
  });

  testWidgets('moves between months, never past this one', (tester) async {
    final repo = await _open(tester);
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month);
    expect(repo.asked.last, thisMonth);

    final next = find.ancestor(
      of: find.byTooltip('الشهر التالي'),
      matching: find.byType(IconButton),
    );
    expect(tester.widget<IconButton>(next).onPressed, isNull);

    await tester.tap(find.byTooltip('الشهر السابق'));
    await tester.pumpAndSettle();
    final last = DateTime(now.year, now.month - 1);
    expect(repo.asked.last, last);
    expect(find.text(Formatters.month(last)), findsWidgets);
  });
}
