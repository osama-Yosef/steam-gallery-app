import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:steam_gallery_app/core/supabase/all_rows.dart';
import 'package:steam_gallery_app/core/theme/app_theme.dart';
import 'package:steam_gallery_app/core/utils/formatters.dart';
import 'package:steam_gallery_app/features/sales/data/month_invoices.dart';
import 'package:steam_gallery_app/features/sales/presentation/screens/admin/admin_month_sales_screen.dart';

import 'helpers/app_fonts.dart';

MonthInvoice _invoice(
  int number,
  InvoiceSource source, {
  double total = 100,
  double paid = 100,
  bool counted = true,
  String? customer,
  String? technician,
  List<InvoiceLine> lines = const [],
}) => MonthInvoice(
  id: 'id-$number',
  source: source,
  number: number,
  createdAt: DateTime(2026, 10, 10 + number),
  customerName: customer,
  technicianName: technician,
  paymentLabel: 'نقدي',
  statusLabel: counted ? 'مكتملة' : 'ملغاة',
  counted: counted,
  subtotal: total,
  discount: 0,
  total: total,
  paid: paid,
  lines: lines,
);

Future<void> _pump(
  WidgetTester tester,
  List<MonthInvoice> invoices, {
  Map<int, List<MonthInvoice>> earlier = const {},
}) async {
  await tester.binding.setSurfaceSize(const Size(420, 2000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        monthInvoicesProvider.overrideWith(
          (ref, monthsAgo) async =>
              monthsAgo == 0 ? invoices : earlier[monthsAgo] ?? const [],
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: const AdminMonthSalesScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ar');
    await loadAppFonts();
  });

  final invoices = [
    _invoice(
      1,
      InvoiceSource.walkIn,
      total: 250,
      paid: 100,
      customer: 'أحمد',
      lines: const [
        InvoiceLine(
          name: 'مكواة',
          quantity: 2,
          unitPrice: 100,
          discount: 0,
          lineTotal: 200,
        ),
        InvoiceLine(
          name: 'فلتر',
          quantity: 1,
          unitPrice: 50,
          discount: 0,
          lineTotal: 50,
          returnedQuantity: 1,
        ),
      ],
    ),
    _invoice(2, InvoiceSource.technician, total: 80, technician: 'محمود'),
    _invoice(3, InvoiceSource.online, total: 40),
    _invoice(4, InvoiceSource.walkIn, total: 999, counted: false),
  ];

  testWidgets('every invoice in full: customer, lines, paid and owed', (
    tester,
  ) async {
    await _pump(tester, invoices);
    expect(find.text('فاتورة #1 · بيع مباشر'), findsOneWidget);
    expect(find.textContaining('العميل: أحمد'), findsOneWidget);
    expect(find.text('مكواة'), findsOneWidget);
    expect(find.text('2 × ${Formatters.currency(100)}'), findsOneWidget);
    expect(find.textContaining('مرتجع 1'), findsOneWidget);
    expect(find.text('الباقي على العميل'), findsOneWidget);
    expect(find.text('الصنايعي: محمود'), findsOneWidget);
    expect(find.text('طلب #3 · أونلاين'), findsOneWidget);
    // Cancelled invoices are listed but left out of the total.
    expect(find.text('فاتورة #4 · بيع مباشر'), findsOneWidget);
    expect(find.text('إجمالي الفواتير المكتملة: 3'), findsOneWidget);
    expect(find.text(Formatters.currency(370)), findsOneWidget);
    if (const bool.fromEnvironment('SHOTS')) {
      await expectLater(
        find.byType(AdminMonthSalesScreen),
        matchesGoldenFile('../build/screen_shots/month_sales_data.png'),
      );
    }
  });

  testWidgets('filters by source', (tester) async {
    await _pump(tester, invoices);
    await tester.tap(find.text('صنايعي (1)'));
    await tester.pumpAndSettle();
    expect(find.text('فاتورة #2 · صنايعي'), findsOneWidget);
    expect(find.text('فاتورة #1 · بيع مباشر'), findsNothing);
    expect(find.text('طلب #3 · أونلاين'), findsNothing);
  });

  testWidgets('last month and the one before', (tester) async {
    final now = DateTime.now();
    await _pump(
      tester,
      invoices,
      earlier: {
        1: [_invoice(50, InvoiceSource.walkIn, total: 700)],
        2: [_invoice(60, InvoiceSource.online, total: 30)],
      },
    );
    expect(
      find.text(
        'مبيعات شهر ${Formatters.month(DateTime(now.year, now.month))}',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('الشهر اللي فات'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'مبيعات شهر ${Formatters.month(DateTime(now.year, now.month - 1))}',
      ),
      findsOneWidget,
    );
    expect(find.text('فاتورة #50 · بيع مباشر'), findsOneWidget);
    expect(find.text('فاتورة #1 · بيع مباشر'), findsNothing);
    expect(find.text('إجمالي الفواتير المكتملة: 1'), findsOneWidget);

    final before = Formatters.month(DateTime(now.year, now.month - 2));
    await tester.tap(find.widgetWithText(ChoiceChip, before));
    await tester.pumpAndSettle();
    expect(find.text('مبيعات شهر $before'), findsOneWidget);
    expect(find.text('طلب #60 · أونلاين'), findsOneWidget);
    expect(find.text('فاتورة #50 · بيع مباشر'), findsNothing);

    await tester.tap(find.text('الشهر ده'));
    await tester.pumpAndSettle();
    expect(find.text('فاتورة #1 · بيع مباشر'), findsOneWidget);
  });

  group('monthRange', () {
    test('a whole calendar month, end exclusive', () {
      final r = monthRange(DateTime(2026, 11, 3, 14), 1);
      expect(r.from, DateTime(2026, 10));
      expect(r.to, DateTime(2026, 11));
    });

    test('this month runs to the 1st of next month', () {
      final r = monthRange(DateTime(2026, 11, 30), 0);
      expect(r.from, DateTime(2026, 11));
      expect(r.to, DateTime(2026, 12));
    });

    test('crosses the year', () {
      final r = monthRange(DateTime(2027, 2, 1), 2);
      expect(r.from, DateTime(2026, 12));
      expect(r.to, DateTime(2027, 1));
    });
  });

  group('reading a month past 1000 rows', () {
    Future<List<int>> Function(int, int) server(int total, List<String> asks) =>
        (from, to) async {
          asks.add('$from-$to');
          final end = to + 1 > total ? total : to + 1;
          return from >= total
              ? []
              : List.generate(end - from, (i) => from + i);
        };

    test('keeps asking until a short page', () async {
      final asks = <String>[];
      final rows = await readAllPages(server(2345, asks));
      expect(rows, hasLength(2345));
      expect(rows.toSet(), hasLength(2345));
      expect(asks, ['0-999', '1000-1999', '2000-2999']);
    });

    test('exactly a full page asks once more', () async {
      final asks = <String>[];
      final rows = await readAllPages(server(1000, asks));
      expect(rows, hasLength(1000));
      expect(asks, ['0-999', '1000-1999']);
    });

    test('a small month is one request', () async {
      final asks = <String>[];
      expect(await readAllPages(server(12, asks)), hasLength(12));
      expect(asks, ['0-999']);
    });
  });

  test('amounts are written in English digits', () {
    expect(Formatters.currency(1234.5), contains('1,234.50'));
    // Whole amounts carry no .00.
    expect(Formatters.currency(1500), contains('1,500'));
    expect(Formatters.currency(1500), isNot(contains('.00')));
    expect(Formatters.plain(1500), '1500');
    expect(Formatters.plain(12.5), '12.50');
  });
}
