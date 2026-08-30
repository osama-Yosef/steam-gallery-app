import 'package:freezed_annotation/freezed_annotation.dart';

part 'cart_item.freezed.dart';

/// Local-only — the cart never touches the database until checkout, per
/// docs/03-business-logic.md §1: prices/quantities are only committed
/// (and price-snapshotted server-side) when rpc_create_order runs.
@freezed
abstract class CartItem with _$CartItem {
  const factory CartItem({
    required String productId,
    required String name,
    required double unitPrice,
    required int quantity,
  }) = _CartItem;

  const CartItem._();

  double get lineTotal => unitPrice * quantity;
}
