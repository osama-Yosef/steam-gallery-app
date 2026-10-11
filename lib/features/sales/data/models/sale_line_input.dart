/// One line being sent to a sale RPC (`rpc_technician_sale` /
/// `rpc_admin_walk_in_sale`).
///
/// [unitPrice] is the price agreed with the customer at sale time. A service
/// line (`products.is_service`) always needs one. For a stock product,
/// rpc_admin_walk_in_sale charges it when given (re-priced at the counter,
/// 0082) and the price of the day otherwise; rpc_technician_sale ignores it
/// and uses the catalogue's selling_price — see 0027.
class SaleLineInput {
  final String productId;
  final int quantity;
  final double? unitPrice;
  final double discount;

  const SaleLineInput({
    required this.productId,
    required this.quantity,
    this.unitPrice,
    this.discount = 0,
  });

  Map<String, dynamic> toJson() => {
    'product_id': productId,
    'quantity': quantity,
    if (unitPrice != null) 'unit_price': unitPrice,
    if (discount > 0) 'discount': discount,
  };
}
