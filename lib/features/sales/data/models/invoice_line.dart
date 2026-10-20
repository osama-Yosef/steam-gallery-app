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

  /// The price was changed in the editor: every unit of the product is set
  /// to [unitPrice] when saved (0087).
  final bool repriced;

  const InvoiceLine({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    this.isService = false,
    this.isAssembly = false,
    this.repriced = false,
  });

  double get lineTotal => quantity * unitPrice;

  InvoiceLine copyWith({int? quantity, double? unitPrice, bool? repriced}) =>
      InvoiceLine(
        productId: productId,
        productName: productName,
        quantity: quantity ?? this.quantity,
        unitPrice: unitPrice ?? this.unitPrice,
        isService: isService,
        isAssembly: isAssembly,
        repriced: repriced ?? this.repriced,
      );

  Map<String, dynamic> toJson() => {
    'product_id': productId,
    'name': productName,
    'quantity': quantity,
    'unit_price': unitPrice,
    'is_service': isService,
    'is_assembly': isAssembly,
    if (repriced) 'repriced': true,
  };

  factory InvoiceLine.fromJson(Map<String, dynamic> j) => InvoiceLine(
    productId: j['product_id'] as String,
    productName: j['name'] as String,
    quantity: (j['quantity'] as num).toInt(),
    unitPrice: (j['unit_price'] as num).toDouble(),
    isService: j['is_service'] as bool? ?? false,
    isAssembly: j['is_assembly'] as bool? ?? false,
    repriced: j['repriced'] as bool? ?? false,
  );

  /// One p_items element for rpc_admin_edit_sale / rpc_edit_technician_sale
  /// — the invoice's final state. The price is sent for a service, and for
  /// any line whose price was changed ("reprice", 0087); otherwise the
  /// server keeps the price already on the invoice.
  Map<String, dynamic> toEditJson() => {
    'product_id': productId,
    'quantity': quantity,
    if (isService || repriced)
      'unit_price': double.parse(unitPrice.toStringAsFixed(2)),
    if (repriced) 'reprice': true,
  };
}
