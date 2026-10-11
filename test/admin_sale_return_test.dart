import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:steam_gallery_app/core/errors/app_exception.dart';
import 'package:steam_gallery_app/core/theme/app_theme.dart';
import 'package:steam_gallery_app/features/cashbox/data/models/cashbox_balance.dart';
import 'package:steam_gallery_app/features/sales/data/models/sale_return_item.dart';
import 'package:steam_gallery_app/features/sales/data/repositories/sales_repository.dart';
import 'package:steam_gallery_app/features/sales/presentation/providers/sales_providers.dart';
import 'package:steam_gallery_app/features/sales/presentation/screens/admin/admin_sale_return_detail_screen.dart';
import 'package:steam_gallery_app/features/technician_account/data/models/sale.dart';

SaleReturnItem _item(String id, String name, int qty, {int returned = 0}) =>
    SaleReturnItem(
      id: id,
      productNameSnapshot: name,
      quantity: qty,
      unitPriceSnapshot: 50,
      discount: 0,
      lineTotal: qty * 50,
      returnedQuantity: returned,
    );

class _FakeSalesRepo implements SalesRepository {
  final itemReturns =
      <({String id, int qty, String reason, CashboxKind? kind})>[];
  final saleReturns = <({String reason, CashboxKind? kind})>[];
  Object? error;

  @override
  Future<void> returnSaleItem({
    required String saleItemId,
    required int quantity,
    required String reason,
    CashboxKind? refundKind,
  }) async {
    if (error != null) throw error!;
    itemReturns.add((
      id: saleItemId,
      qty: quantity,
      reason: reason,
      kind: refundKind,
    ));
  }

  @override
  Future<void> returnSale({
    required String saleId,
    required String reason,
    CashboxKind? refundKind,
  }) async {
    if (error != null) throw error!;
    saleReturns.add((reason: reason, kind: refundKind));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _pump(
  WidgetTester tester,
  _FakeSalesRepo repo, {
  List<SaleReturnItem>? items,
  PaymentMethod method = PaymentMethod.cash,
}) async {
  await tester.binding.setSurfaceSize(const Size(600, 1000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        salesRepositoryProvider.overrideWithValue(repo),
        saleReturnItemsProvider('s1').overrideWith(
          (ref) async =>
              items ??
              [_item('i1', 'مكواة', 3), _item('i2', 'فلتر', 2, returned: 2)],
        ),
        saleByIdProvider('s1').overrideWith(
          (ref) async => Sale(
            id: 's1',
            saleNumber: 4,
            paymentMethod: method,
            subtotal: 250,
            discount: 0,
            total: 250,
            paidAmount: 250,
            status: SaleStatus.completed,
            createdAt: DateTime(2026, 10, 1),
          ),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: const AdminSaleReturnDetailScreen(saleId: 's1'),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => initializeDateFormatting('ar'));

  testWidgets('each line shows what is left to return', (tester) async {
    await _pump(tester, _FakeSalesRepo());
    expect(find.text('مكواة'), findsOneWidget);
    expect(find.text('اتُرجع بالكامل (2)'), findsOneWidget);
    // Only the line with something left has a return button.
    expect(find.text('إرجاع'), findsOneWidget);
    expect(find.text('إرجاع باقي الفاتورة'), findsOneWidget);
  });

  testWidgets('returning part of a line: quantity capped by what is left, '
      'refund from the till the sale was paid into', (tester) async {
    final repo = _FakeSalesRepo();
    await _pump(tester, repo, method: PaymentMethod.transfer);
    await tester.tap(find.text('إرجاع'));
    await tester.pumpAndSettle();
    expect(find.text('الكمية (المتاح 3)'), findsOneWidget);

    for (var i = 0; i < 5; i++) {
      await tester.tap(find.byIcon(Iconsax.add_copy));
      await tester.pump();
    }
    expect(find.text('3'), findsOneWidget, reason: 'never past what is left');
    await tester.tap(find.byIcon(Iconsax.minus_copy));
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'عيب صناعة');
    await tester.tap(find.text('تأكيد الإرجاع'));
    await tester.pumpAndSettle();

    final r = repo.itemReturns.single;
    expect((r.id, r.qty, r.reason), ('i1', 2, 'عيب صناعة'));
    expect(r.kind, CashboxKind.transfer);
    expect(find.text('تم تسجيل المرتجع'), findsOneWidget);
  });

  testWidgets('no reason, no return', (tester) async {
    final repo = _FakeSalesRepo();
    await _pump(tester, repo);
    await tester.tap(find.text('إرجاع'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('تأكيد الإرجاع'));
    await tester.pumpAndSettle();
    expect(repo.itemReturns, isEmpty);
  });

  testWidgets('the refund till can be changed', (tester) async {
    final repo = _FakeSalesRepo();
    await _pump(tester, repo);
    await tester.tap(find.text('إرجاع'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('حساب CIB'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'غلط');
    await tester.tap(find.text('تأكيد الإرجاع'));
    await tester.pumpAndSettle();
    expect(repo.itemReturns.single.kind, CashboxKind.transfer);
  });

  testWidgets('returning the rest of the invoice asks twice', (tester) async {
    final repo = _FakeSalesRepo();
    await _pump(tester, repo);
    await tester.tap(find.text('إرجاع باقي الفاتورة'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'العميل رجع');
    await tester.tap(find.text('تأكيد الإرجاع'));
    await tester.pumpAndSettle();
    expect(find.text('تأكيد نهائي'), findsOneWidget);
    expect(repo.saleReturns, isEmpty, reason: 'not before the final yes');

    await tester.tap(find.text('إرجاع الكل'));
    await tester.pumpAndSettle();
    expect(repo.saleReturns.single.reason, 'العميل رجع');
    expect(repo.saleReturns.single.kind, CashboxKind.cash);
    expect(find.text('تم إرجاع الفاتورة'), findsOneWidget);
  });

  testWidgets('a fully returned invoice has nothing left to return', (
    tester,
  ) async {
    await _pump(
      tester,
      _FakeSalesRepo(),
      items: [_item('i1', 'مكواة', 1, returned: 1)],
    );
    expect(find.text('إرجاع'), findsNothing);
    expect(find.text('إرجاع باقي الفاتورة'), findsNothing);
  });

  testWidgets('a refusal shows the server\'s message', (tester) async {
    final repo = _FakeSalesRepo()
      ..error = const AppException('رصيد الخزنة لا يكفي');
    await _pump(tester, repo, items: [_item('i1', 'مكواة', 1)]);
    await tester.tap(find.text('إرجاع'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'x');
    await tester.tap(find.text('تأكيد الإرجاع'));
    await tester.pumpAndSettle();
    expect(find.text('رصيد الخزنة لا يكفي'), findsOneWidget);
  });
}
