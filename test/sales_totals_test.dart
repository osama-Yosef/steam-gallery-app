import 'package:flutter_test/flutter_test.dart';
import 'package:steam_gallery_app/features/reports/data/sales_totals.dart';

/// The sales report counts each invoice as it stands after its last edit.
void main() {
  Map<String, dynamic> line(
    String saleId, {
    required int qty,
    int returned = 0,
    required double price,
    double cost = 0,
    double discount = 0,
  }) => {
    'sale_id': saleId,
    'quantity': qty,
    'returned_quantity': returned,
    'unit_price_snapshot': price,
    'unit_cost_snapshot': cost,
    'discount': discount,
  };

  test('a plain invoice counts at its total', () {
    final t = SalesTotals.from(
      sales: [
        {'id': 's1', 'total': 300, 'discount': 0},
      ],
      saleLines: [line('s1', qty: 3, price: 100, cost: 60)],
      orders: const [],
    );
    expect(t.net, 300);
    expect(t.gross, 300);
    expect(t.cost, 180);
    expect(t.removed, 0);
  });

  test('an invoice edited from 5 units down to 2 counts 2 — once', () {
    // Sold 5 × 100, then edited to 2: the edit returns 3 units and the
    // server brings the invoice total down to 200.
    final t = SalesTotals.from(
      sales: [
        {'id': 's1', 'total': 200, 'discount': 0},
      ],
      saleLines: [line('s1', qty: 5, returned: 3, price: 100, cost: 60)],
      orders: const [],
    );
    expect(t.net, 200);
    expect(t.gross, 200);
    expect(t.cost, 120);
    expect(t.removed, 300);
  });

  test('a re-priced invoice counts at the new price only', () {
    // 2 units at 100 re-priced to 80: the old line is returned in full
    // and a new line is added at 80.
    final t = SalesTotals.from(
      sales: [
        {'id': 's1', 'total': 160, 'discount': 0},
      ],
      saleLines: [
        line('s1', qty: 2, returned: 2, price: 100, cost: 50),
        line('s1', qty: 2, price: 80, cost: 50),
      ],
      orders: const [],
    );
    expect(t.net, 160);
    expect(t.cost, 100);
  });

  test('the invoice discount after the edit is the one counted', () {
    final t = SalesTotals.from(
      sales: [
        {'id': 's1', 'total': 450, 'discount': 50},
      ],
      saleLines: [line('s1', qty: 5, price: 100)],
      orders: const [],
    );
    expect(t.net, 450);
    expect(t.discounts, 50);
    expect(t.gross, 500);
  });

  test('a line discount counts only on the units still sold', () {
    final t = SalesTotals.from(
      sales: [
        {'id': 's1', 'total': 190, 'discount': 0},
      ],
      saleLines: [line('s1', qty: 4, returned: 2, price: 100, discount: 20)],
      orders: const [],
    );
    expect(t.discounts, 10);
    expect(t.gross, 200);
  });

  test('lines of a sale outside the range are ignored', () {
    final t = SalesTotals.from(
      sales: const [],
      saleLines: [line('other', qty: 1, price: 100, cost: 50)],
      orders: const [],
    );
    expect(t.net, 0);
    expect(t.cost, 0);
  });

  test('online orders count at their total, shipping included', () {
    final t = SalesTotals.from(
      sales: const [],
      saleLines: const [],
      orders: [
        {
          'total': 330,
          'discount': 20,
          'order_items': [
            {'quantity': 2, 'unit_cost_snapshot': 90, 'discount': 0},
          ],
        },
      ],
    );
    expect(t.net, 330);
    expect(t.discounts, 20);
    expect(t.cost, 180);
  });
}
