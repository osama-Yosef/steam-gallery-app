/// One line being sent to a sale RPC (`rpc_technician_sale` /
/// `rpc_admin_walk_in_sale`).
///
/// [unitPrice] is only meaningful for a service line (`products.is_service`),
/// where the price is agreed with the customer at sale time. For a stock
/// product the server ignores it and uses the catalogue's selling_price, so a
/// client can never quietly re-price the catalogue — see 0027.
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
