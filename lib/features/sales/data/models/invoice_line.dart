/// What's currently on a walk-in invoice for one product — every sale_items
/// row of that product net of returns (0058/0075), merged into one line for
/// the invoice editor.
class InvoiceLine {
  final String productId;
  final String productName;
  final int quantity;

  /// Average price per unit still on the invoice (lines of one product only
  /// differ in price if an offer started or ended between edits).
  final double unitPrice;
  final bool isService;
  final bool isAssembly;

  const InvoiceLine({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    this.isService = false,
    this.isAssembly = false,
  });

  double get lineTotal => quantity * unitPrice;

  InvoiceLine copyWith({int? quantity, double? unitPrice}) => InvoiceLine(
    productId: productId,
    productName: productName,
    quantity: quantity ?? this.quantity,
    unitPrice: unitPrice ?? this.unitPrice,
    isService: isService,
    isAssembly: isAssembly,
  );

  Map<String, dynamic> toJson() => {
    'product_id': productId,
    'name': productName,
    'quantity': quantity,
    'unit_price': unitPrice,
    'is_service': isService,
    'is_assembly': isAssembly,
  };

  factory InvoiceLine.fromJson(Map<String, dynamic> j) => InvoiceLine(
    productId: j['product_id'] as String,
    productName: j['name'] as String,
    quantity: (j['quantity'] as num).toInt(),
    unitPrice: (j['unit_price'] as num).toDouble(),
    isService: j['is_service'] as bool? ?? false,
    isAssembly: j['is_assembly'] as bool? ?? false,
  );

  /// One p_items element for rpc_admin_edit_sale — the invoice's final
  /// state, so the price only matters for a service (it's ignored for stock
  /// products, which the server prices itself).
  Map<String, dynamic> toEditJson() => {
    'product_id': productId,
    'quantity': quantity,
    if (isService) 'unit_price': double.parse(unitPrice.toStringAsFixed(2)),
  };
}
