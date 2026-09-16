import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/models/cart_item.dart';

part 'cart_provider.g.dart';

/// Per-line cap in the app. The server allows up to 999 (rpc_create_order)
/// and checks stock itself; this only keeps the stepper sensible.
const maxCartLineQuantity = 20;

@Riverpod(keepAlive: true)
class Cart extends _$Cart {
  @override
  List<CartItem> build() => [];

  /// Adds [quantity] (default 1) to the line, capped at
  /// [maxCartLineQuantity]. Returns the line's quantity afterwards.
  int add({
    required String productId,
    required String name,
    required double unitPrice,
    int quantity = 1,
  }) {
    if (quantity <= 0) return quantityOf(productId);
    final i = state.indexWhere((e) => e.productId == productId);
    if (i == -1) {
      final q = quantity.clamp(1, maxCartLineQuantity);
      state = [
        ...state,
        CartItem(
          productId: productId,
          name: name,
          unitPrice: unitPrice,
          quantity: q,
        ),
      ];
      return q;
    }
    final q = (state[i].quantity + quantity).clamp(1, maxCartLineQuantity);
    state = [
      for (final item in state)
        if (item.productId == productId)
          item.copyWith(quantity: q, name: name, unitPrice: unitPrice)
        else
          item,
    ];
    return q;
  }

  int quantityOf(String productId) {
    for (final item in state) {
      if (item.productId == productId) return item.quantity;
    }
    return 0;
  }

  void setQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      remove(productId);
      return;
    }
    final q = quantity > maxCartLineQuantity ? maxCartLineQuantity : quantity;
    state = [
      for (final item in state)
        if (item.productId == productId) item.copyWith(quantity: q) else item,
    ];
  }

  void remove(String productId) {
    state = state.where((e) => e.productId != productId).toList();
  }

  void clear() => state = [];
}

@riverpod
double cartTotal(Ref ref) {
  final items = ref.watch(cartProvider);
  return items.fold<double>(0, (sum, e) => sum + e.lineTotal);
}

@riverpod
int cartItemCount(Ref ref) {
  final items = ref.watch(cartProvider);
  return items.fold<int>(0, (sum, e) => sum + e.quantity);
}
