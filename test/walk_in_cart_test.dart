import 'package:flutter_test/flutter_test.dart';
import 'package:steam_gallery_app/core/offline/outbox.dart';
import 'package:steam_gallery_app/features/inventory/data/models/warehouse_stock_item.dart';
import 'package:steam_gallery_app/features/products/data/models/product.dart';
import 'package:steam_gallery_app/features/sales/presentation/state/register_stock.dart';
import 'package:steam_gallery_app/features/sales/presentation/state/line_change.dart';
import 'package:steam_gallery_app/features/sales/presentation/state/walk_in_cart.dart';

WarehouseStockItem _item(
  String id,
  int qty,
  double price, {
  String? name,
  double? offer,
  bool assembly = false,
}) => WarehouseStockItem(
  productId: id,
  productName: name ?? 'منتج $id',
  sku: 'SKU-$id',
  quantity: qty,
  costPrice: 1,
  sellingPrice: price,
  minStock: 0,
  effectivePrice: offer,
  isAssembly: assembly,
);

OutboxEntry _queuedSale(Map<String, int> items) => OutboxEntry(
  id: 'q',
  rpc: 'rpc_admin_walk_in_sale',
  params: {
    'p_items': [
      for (final e in items.entries) {'product_id': e.key, 'quantity': e.value},
    ],
  },
  viaReplay: false,
  label: 'بيع',
  kind: 'walk_in_sale',
  userId: 'u',
  createdAt: DateTime(2026),
);

void main() {
  group('WalkInCart', () {
    test('adding the same product twice is one line of two', () {
      final cart = WalkInCart();
      cart.addProduct(_item('a', 5, 10));
      cart.addProduct(_item('a', 5, 10));
      expect(cart.lines, hasLength(1));
      expect(cart.quantityOf('a'), 2);
      expect(cart.itemCount, 2);
      expect(cart.subtotal, 20);
    });

    test('never more than the warehouse has', () {
      final cart = WalkInCart();
      final item = _item('a', 1, 10);
      expect(cart.addProduct(item), LineChange.updated);
      expect(cart.addProduct(item), LineChange.overStock);
      expect(cart.quantityOf('a'), 1);
      expect(cart.changeQuantity('a', 1), LineChange.overStock);
      expect(cart.quantityOf('a'), 1);
    });

    test('charges the live offer price when there is one', () {
      final cart = WalkInCart()..addProduct(_item('a', 3, 20, offer: 15));
      expect(cart.subtotal, 15);
    });

    test('down to zero removes the line', () {
      final cart = WalkInCart()
        ..addProduct(_item('a', 3, 10))
        ..addProduct(_item('b', 3, 5));
      expect(cart.changeQuantity('a', -1), LineChange.removed);
      expect(cart.quantityOf('a'), 0);
      expect(cart.lines.single.productId, 'b');
    });

    test('a service carries its agreed price; stock products never do', () {
      final cart = WalkInCart()
        ..addProduct(_item('a', 3, 10))
        ..addService(
          Product(
            id: 'svc',
            sku: 'S',
            name: 'صيانة',
            specs: const {},
            costPrice: 0,
            sellingPrice: 0,
            minStock: 0,
            isActive: true,
            isService: true,
            createdAt: DateTime(2026),
          ),
          80,
        );
      // A service isn't limited by stock.
      expect(cart.changeQuantity('svc', 5), LineChange.updated);
      expect(cart.subtotal, 10 + 6 * 80);
      final inputs = cart.toSaleInputs();
      expect(inputs[0].unitPrice, isNull);
      expect(inputs[1].unitPrice, 80);
      expect(inputs[1].quantity, 6);
    });

    test('clear empties it', () {
      final cart = WalkInCart()..addProduct(_item('a', 3, 10));
      cart.clear();
      expect(cart.isEmpty, isTrue);
      expect(cart.subtotal, 0);
    });

    test('lines can\'t be changed from outside', () {
      final cart = WalkInCart()..addProduct(_item('a', 3, 10));
      expect(() => cart.lines.clear(), throwsUnsupportedError);
    });
  });

  group('registerStock', () {
    test('queued offline sales are taken off, never below zero', () {
      final stock = registerStock(
        [_item('a', 5, 10), _item('b', 1, 10)],
        [_item('kit', 2, 50, assembly: true)],
        queuedSales: [
          _queuedSale({'a': 2, 'b': 3}),
          _queuedSale({'a': 1, 'kit': 1}),
        ],
      );
      int qty(String id) => stock.firstWhere((s) => s.productId == id).quantity;
      expect(qty('a'), 2);
      expect(qty('b'), 0);
      expect(qty('kit'), 1);
    });

    test('warehouse and assemblies together, sorted by name', () {
      final stock = registerStock(
        [_item('a', 1, 1, name: 'مكواة')],
        [_item('k', 1, 1, name: 'أطقم', assembly: true)],
        queuedSales: const [],
      );
      expect(stock.map((s) => s.productName), ['أطقم', 'مكواة']);
    });
  });

  group('sellableMatching', () {
    final stock = [
      _item('a', 3, 1, name: 'Steam Iron'),
      _item('b', 0, 1, name: 'Steam Hose'),
      _item('c', 2, 1, name: 'Base'),
    ];

    test('only what can still be sold', () {
      expect(sellableMatching(stock, '').map((s) => s.productId), ['a', 'c']);
    });

    test('by name or SKU, ignoring case and spaces around', () {
      expect(sellableMatching(stock, '  steam ').single.productId, 'a');
      expect(sellableMatching(stock, 'sku-c').single.productId, 'c');
      expect(sellableMatching(stock, 'nothing'), isEmpty);
    });
  });
}
