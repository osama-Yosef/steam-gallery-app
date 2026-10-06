/// One ingredient of an assembly product ("صنف تجميع", 0075): [quantity] of
/// [productId] go into each unit sold.
class AssemblyComponent {
  final String productId;
  final String productName;
  final int quantity;
  final double costPrice;

  const AssemblyComponent({
    required this.productId,
    required this.productName,
    required this.quantity,
    this.costPrice = 0,
  });

  factory AssemblyComponent.fromRow(Map<String, dynamic> row) {
    final product = row['products'] as Map<String, dynamic>;
    return AssemblyComponent(
      productId: row['component_id'] as String,
      productName: product['name'] as String,
      quantity: row['quantity'] as int,
      costPrice: (product['cost_price'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'product_id': productId,
    'quantity': quantity,
  };
}
