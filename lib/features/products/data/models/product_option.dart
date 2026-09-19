import 'package:freezed_annotation/freezed_annotation.dart';

part 'product_option.freezed.dart';

/// A priced, selectable add-on for a product (0049) — e.g. "ضمان سنتين
/// +200ج". The customer ticks any combination on the product page; each
/// ticked option's [extraPrice] adds to the base selling price. No cost —
/// this is a pure price add-on, not inventory.
@freezed
abstract class ProductOption with _$ProductOption {
  const factory ProductOption({
    required String id,
    required String productId,
    required String name,
    required double extraPrice,
    required int sortOrder,
  }) = _ProductOption;

  factory ProductOption.fromRow(Map<String, dynamic> row) => ProductOption(
    id: row['id'] as String,
    productId: row['product_id'] as String,
    name: row['name'] as String,
    extraPrice: (row['extra_price'] as num).toDouble(),
    sortOrder: row['sort_order'] as int? ?? 0,
  );
}

/// What's editable in the admin product form — [id] null means "new, not
/// saved yet" (assigned a fresh id server-side on insert).
class ProductOptionInput {
  final String? id;
  final String name;
  final double extraPrice;

  const ProductOptionInput({
    this.id,
    required this.name,
    required this.extraPrice,
  });
}

/// The lightweight shape carried on a cart line / order item — just enough
/// to show what was picked, not the full admin-editable row.
class SelectedOption {
  final String name;
  final double extraPrice;
  const SelectedOption({required this.name, required this.extraPrice});

  factory SelectedOption.fromJson(Map<String, dynamic> json) =>
      SelectedOption(
        name: json['name'] as String,
        extraPrice: (json['extra_price'] as num).toDouble(),
      );
}
