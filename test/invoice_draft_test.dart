import 'package:flutter_test/flutter_test.dart';
import 'package:steam_gallery_app/core/offline/outbox.dart';
import 'package:steam_gallery_app/features/cashbox/data/models/cashbox_balance.dart';
import 'package:steam_gallery_app/features/inventory/data/models/warehouse_stock_item.dart';
import 'package:steam_gallery_app/features/sales/data/models/invoice_line.dart';
import 'package:steam_gallery_app/features/sales/presentation/state/invoice_draft.dart';
import 'package:steam_gallery_app/features/sales/presentation/state/line_change.dart';
import 'package:steam_gallery_app/features/technician_account/data/models/sale.dart';

Sale _sale({PaymentMethod method = PaymentMethod.cash}) => Sale(
  id: 's1',
  saleNumber: 1,
  paymentMethod: method,
  subtotal: 250,
  discount: 10,
  total: 240,
  paidAmount: 240,
  status: SaleStatus.completed,
  createdAt: DateTime(2026),
);

const _iron = InvoiceLine(
  productId: 'iron',
  productName: 'مكواة',
  quantity: 2,
  unitPrice: 100,
);
const _base = InvoiceLine(
  productId: 'base',
  productName: 'قاعدة',
  quantity: 1,
  unitPrice: 50,
);
const _svc = InvoiceLine(
  productId: 'svc',
  productName: 'صيانة',
  quantity: 1,
  unitPrice: 30,
  isService: true,
);

WarehouseStockItem _stock(String id, int qty) => WarehouseStockItem(
  productId: id,
  productName: id,
  sku: id,
  quantity: qty,
  costPrice: 1,
  sellingPrice: 1,
  minStock: 0,
);

InvoiceDraft _draft() => InvoiceDraft.open(_sale(), const [_iron, _base]);

void main() {
  test('opens on the server\'s lines and discount', () {
    final d = _draft();
    expect(d.lines.map((l) => l.productId), ['iron', 'base']);
    expect(d.subtotal, 250);
    expect(d.initialDiscount, 10);
    expect(d.total(10), 240);
    expect(d.fromPending, isFalse);
  });

  test('can keep what was sold plus what is left in the warehouse', () {
    final d = _draft();
    final stock = [_stock('iron', 1)];
    expect(d.maxFor('iron', stock), 3);
    expect(d.changeQuantity('iron', 1, stock), LineChange.updated);
    expect(d.changeQuantity('iron', 1, stock), LineChange.overStock);
    expect(d.lines.first.quantity, 3);
  });

  test('a product with nothing left can still be kept, just not raised', () {
    final d = _draft();
    expect(d.changeQuantity('base', 1, const []), LineChange.overStock);
    expect(d.changeQuantity('base', -1, const []), LineChange.removed);
    expect(d.lines.map((l) => l.productId), ['iron']);
  });

  test('adding a new product, then the same one again', () {
    final d = _draft();
    final stock = [_stock('filter', 2)];
    const filter = InvoiceLine(
      productId: 'filter',
      productName: 'فلتر',
      quantity: 1,
      unitPrice: 20,
    );
    expect(d.add(filter, stock), LineChange.updated);
    expect(d.add(filter, stock), LineChange.updated);
    expect(d.add(filter, stock), LineChange.overStock);
    expect(d.lines.last.quantity, 2);
  });

  test('a service is not limited by stock', () {
    final d = _draft()..add(_svc, const []);
    expect(d.changeQuantity('svc', 4, const []), LineChange.updated);
    expect(d.subtotal, 250 + 5 * 30);
  });

  test('what can\'t be saved, and why', () {
    final d = _draft();
    expect(d.saveProblem(10), isNull);
    expect(d.saveProblem(-1), 'قيمة الخصم غير صحيحة');
    expect(d.saveProblem(251), 'قيمة الخصم غير صحيحة');
    d
      ..remove('iron')
      ..remove('base');
    expect(d.saveProblem(0), contains('الفاتورة فاضية'));
  });

  test('continues the latest edit still waiting offline', () {
    OutboxEntry edit(List<InvoiceLine> lines, double discount) => OutboxEntry(
      id: 'e${lines.length}',
      rpc: 'rpc_admin_edit_sale',
      params: const {},
      viaReplay: true,
      label: 'تعديل',
      kind: 'sale_edit',
      refId: 's1',
      meta: {
        'lines': [for (final l in lines) l.toJson()],
        'discount': discount,
      },
      userId: 'u',
      createdAt: DateTime(2026),
    );
    final d = InvoiceDraft.open(
      _sale(),
      const [_iron, _base],
      pendingEdits: [
        edit(const [_iron], 0),
        edit(const [_iron, _base, _svc], 5),
      ],
    );
    expect(d.fromPending, isTrue);
    expect(d.lines.map((l) => l.productId), ['iron', 'base', 'svc']);
    expect(d.initialDiscount, 5);
    // The server's quantities still bound what can be kept.
    expect(d.maxFor('iron', const []), 2);
  });

  test('money moves through the till the invoice was paid into', () {
    expect(defaultTillFor(_sale()), CashboxKind.cash);
    expect(
      defaultTillFor(_sale(method: PaymentMethod.transfer)),
      CashboxKind.transfer,
    );
    expect(
      defaultTillFor(_sale(method: PaymentMethod.card)),
      CashboxKind.transfer,
    );
    expect(
      defaultTillFor(_sale(method: PaymentMethod.wallet)),
      CashboxKind.wallet,
    );
  });
}
