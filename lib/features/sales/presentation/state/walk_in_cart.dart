import '../../../inventory/data/models/warehouse_stock_item.dart';
import '../../../products/data/models/product.dart';
import '../../data/models/sale_line_input.dart';
import 'line_change.dart';

/// One product (or service) rung up at the register.
class CartLine {
  final String productId;
  final String productName;

  /// What one unit is charged: the register's display price for a stock
  /// product unless re-priced at the counter, or the price agreed with the
  /// customer for a service.
  final double unitPrice;

  /// The price the product was rung up at, before any change at the
  /// counter (0082). Equal to [unitPrice] for a service.
  final double listPrice;

  /// How many the warehouse had when the line was added — the most this
  /// line can be raised to. Not used for a service.
  final int available;
  final bool isService;
  final int quantity;

  const CartLine({
    required this.productId,
    required this.productName,
    required this.unitPrice,
    double? listPrice,
    required this.available,
    required this.quantity,
    this.isService = false,
  }) : listPrice = listPrice ?? unitPrice;

  double get lineTotal => quantity * unitPrice;

  /// Re-priced at the counter, up or down.
  bool get priceChanged => !isService && unitPrice != listPrice;

  CartLine _copy({int? quantity, double? unitPrice}) => CartLine(
    productId: productId,
    productName: productName,
    unitPrice: unitPrice ?? this.unitPrice,
    listPrice: listPrice,
    available: available,
    quantity: quantity ?? this.quantity,
    isService: isService,
  );

  CartLine withQuantity(int quantity) => _copy(quantity: quantity);

  CartLine withPrice(double unitPrice) => _copy(unitPrice: unitPrice);

  /// The line as sent to rpc_admin_walk_in_sale. A service always carries
  /// its price; a stock product only when it was re-priced — otherwise the
  /// server charges its price today (offer included), as it always has.
  SaleLineInput toSaleInput() => SaleLineInput(
    productId: productId,
    quantity: quantity,
    unitPrice: isService || priceChanged ? unitPrice : null,
  );
}

/// The walk-in register's cart: what is being sold right now and what it
/// comes to. Plain Dart, so the selling rules are tested without a screen
/// (test/walk_in_cart_test.dart); the screen only shows it and reports
/// [LineChange.overStock].
class WalkInCart {
  final List<CartLine> _lines = [];

  List<CartLine> get lines => List.unmodifiable(_lines);
  bool get isEmpty => _lines.isEmpty;

  /// Units across all lines, e.g. "السلة (3 صنف)".
  int get itemCount => _lines.fold<int>(0, (sum, l) => sum + l.quantity);

  double get subtotal => _lines.fold<double>(0, (sum, l) => sum + l.lineTotal);

  /// How many of [productId] are rung up (0 when it isn't).
  int quantityOf(String productId) =>
      _lines.where((l) => l.productId == productId).firstOrNull?.quantity ?? 0;

  /// Tapping a product adds one of it; tapping again adds another, up to
  /// what is in stock.
  LineChange addProduct(WarehouseStockItem item) {
    final i = _lines.indexWhere((l) => l.productId == item.productId);
    if (i < 0) {
      _lines.add(
        CartLine(
          productId: item.productId,
          productName: item.productName,
          unitPrice: item.displayPrice,
          available: item.quantity,
          quantity: 1,
        ),
      );
      return LineChange.updated;
    }
    final line = _lines[i];
    if (line.quantity >= item.quantity) return LineChange.overStock;
    _lines[i] = line.withQuantity(line.quantity + 1);
    return LineChange.updated;
  }

  /// A labour line at the price agreed for this sale.
  void addService(Product service, double price) {
    _lines.add(
      CartLine(
        productId: service.id,
        productName: service.name,
        unitPrice: price,
        available: 1,
        quantity: 1,
        isService: true,
      ),
    );
  }

  /// The −/+ buttons in the cart. Down to zero removes the line; a stock
  /// product can't go past what was available. Looked up by product rather
  /// than by the line object, so two quick taps both count even if the
  /// screen hasn't rebuilt in between.
  LineChange changeQuantity(String productId, int delta) {
    final i = _lines.indexWhere((l) => l.productId == productId);
    if (i < 0) return LineChange.removed;
    final line = _lines[i];
    final next = line.quantity + delta;
    if (next <= 0) {
      _lines.removeAt(i);
      return LineChange.removed;
    }
    if (!line.isService && next > line.available) return LineChange.overStock;
    _lines[i] = line.withQuantity(next);
    return LineChange.updated;
  }

  /// Charges [price] per unit on [line] instead of its list price. The line
  /// is found by identity, so two service lines of the same product stay
  /// apart.
  void setPrice(CartLine line, double price) {
    final i = _lines.indexWhere((l) => identical(l, line));
    if (i >= 0) _lines[i] = line.withPrice(price);
  }

  List<SaleLineInput> toSaleInputs() => [
    for (final l in _lines) l.toSaleInput(),
  ];

  void clear() => _lines.clear();
}
