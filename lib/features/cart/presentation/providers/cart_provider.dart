import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/models/cart_item.dart';

part 'cart_provider.g.dart';

@Riverpod(keepAlive: true)
class Cart extends _$Cart {
  @override
  List<CartItem> build() => [];

  void add({
    required String productId,
    required String name,
    required double unitPrice,
  }) {
    final i = state.indexWhere((e) => e.productId == productId);
    if (i == -1) {
      state = [
        ...state,
        CartItem(
          productId: productId,
          name: name,
          unitPrice: unitPrice,
          quantity: 1,
        ),
      ];
    } else {
      state = [
        for (final item in state)
          if (item.productId == productId)
            item.copyWith(quantity: item.quantity + 1)
          else
            item,
      ];
    }
  }

  void setQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      remove(productId);
      return;
    }
    state = [
      for (final item in state)
        if (item.productId == productId)
          item.copyWith(quantity: quantity)
        else
          item,
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
