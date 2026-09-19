import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../products/data/models/product_option.dart';

part 'cart.freezed.dart';

/// Mirrors the limits in 0035 (private.cart_max_quantity / cart_max_lines).
const maxCartLineQuantity = 20;
const maxCartLines = 30;

/// One cart line as priced by the server (rpc_get_my_cart). The app never
/// computes money from its own numbers: [unitPrice], [lineTotal] and the
/// cart subtotal all come from the database at read time. A line is keyed
/// by (productId, optionIds) — 0049: picking a different combination of
/// options for the same product is a separate line, priced separately.
@freezed
abstract class CartLine with _$CartLine {
  const CartLine._();

  const factory CartLine({
    required String productId,
    required String name,
    String? sku,
    String? imageUrl,
    required int quantity,
    required double unitPrice,
    required double priceSeen,
    required bool priceChanged,
    required double lineTotal,
    required bool isActive,
    required bool isAvailable,
    required List<String> optionIds,
    required List<SelectedOption> options,
  }) = _CartLine;

  factory CartLine.fromRpc(Map<String, dynamic> j) => CartLine(
    productId: j['product_id'] as String,
    name: j['name'] as String,
    sku: j['sku'] as String?,
    imageUrl: j['image_url'] as String?,
    quantity: (j['quantity'] as num).toInt(),
    unitPrice: (j['unit_price'] as num).toDouble(),
    priceSeen: (j['price_seen'] as num).toDouble(),
    priceChanged: j['price_changed'] as bool? ?? false,
    lineTotal: (j['line_total'] as num).toDouble(),
    isActive: j['is_active'] as bool? ?? false,
    isAvailable: j['is_available'] as bool? ?? false,
    optionIds: [for (final id in (j['option_ids'] as List? ?? const [])) id as String],
    options: [
      for (final o in (j['options'] as List? ?? const []))
        SelectedOption.fromJson(Map<String, dynamic>.from(o as Map)),
    ],
  );

  /// Can't be checked out as-is: switched off, or more than is in stock.
  bool get blocksCheckout => !isActive || !isAvailable;
}

@freezed
abstract class CartSummary with _$CartSummary {
  const CartSummary._();

  const factory CartSummary({
    required List<CartLine> items,
    required int itemCount,
    required double subtotal,
    required String currency,
    required bool hasIssues,
  }) = _CartSummary;

  static const empty = CartSummary(
    items: [],
    itemCount: 0,
    subtotal: 0,
    currency: 'EGP',
    hasIssues: false,
  );

  factory CartSummary.fromRpc(Map<String, dynamic> j) => CartSummary(
    items: [
      for (final l in (j['items'] as List? ?? const []))
        CartLine.fromRpc(Map<String, dynamic>.from(l as Map)),
    ],
    itemCount: (j['item_count'] as num? ?? 0).toInt(),
    subtotal: (j['subtotal'] as num? ?? 0).toDouble(),
    currency: j['currency'] as String? ?? 'EGP',
    hasIssues: j['has_issues'] as bool? ?? false,
  );

  bool get isEmpty => items.isEmpty;
  bool get hasPriceChanges => items.any((l) => l.priceChanged);
  bool get canCheckout =>
      items.isNotEmpty && !items.any((l) => l.blocksCheckout);

  /// Total quantity of this product across every option combination —
  /// used for display badges ("في السلة: N"), not for line identity.
  int quantityOf(String productId) {
    var total = 0;
    for (final l in items) {
      if (l.productId == productId) total += l.quantity;
    }
    return total;
  }

  /// Quantity of the one line matching this exact option combination — this
  /// is what the per-line cap (`maxCartLineQuantity`) must be checked
  /// against, since a different combination is a separate line server-side
  /// and has its own room even if another combination is already maxed.
  int quantityOfLine(String productId, Iterable<String> optionIds) {
    final wanted = optionIds.toSet();
    for (final l in items) {
      if (l.productId == productId &&
          l.optionIds.length == wanted.length &&
          l.optionIds.toSet().containsAll(wanted)) {
        return l.quantity;
      }
    }
    return 0;
  }
}
