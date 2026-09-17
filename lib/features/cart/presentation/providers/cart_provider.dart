import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/supabase/supabase_client_provider.dart';
import '../../../auth/data/models/app_user.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/models/cart.dart';
import '../../data/repositories/cart_repository.dart';

part 'cart_provider.g.dart';

@Riverpod(keepAlive: true)
CartRepository cartRepository(Ref ref) {
  return SupabaseCartRepository(ref.watch(supabaseClientProvider));
}

/// The signed-in customer's cart, stored and priced by the server (0035).
/// Rebuilds on every sign-in/out, so one account never sees another's cart.
/// Mutations replace the state with the cart the server returns.
@Riverpod(keepAlive: true)
class Cart extends _$Cart {
  @override
  Future<CartSummary> build() async {
    final profile = await ref.watch(currentUserProfileProvider.future);
    if (profile == null || profile.role != AppRole.customer) {
      return CartSummary.empty;
    }
    return ref.watch(cartRepositoryProvider).getCart();
  }

  Future<CartSummary> _apply(Future<CartSummary> Function() op) async {
    final next = await op();
    if (ref.mounted) state = AsyncData(next);
    return next;
  }

  /// Adds [quantity] to the line (the server caps it). Returns the new cart.
  Future<CartSummary> add(String productId, {int quantity = 1}) =>
      _apply(() => ref.read(cartRepositoryProvider).addItem(productId, quantity));

  /// Sets the line's quantity; 0 removes it.
  Future<CartSummary> setQuantity(String productId, int quantity) => _apply(
    () => ref.read(cartRepositoryProvider).setQuantity(productId, quantity),
  );

  Future<CartSummary> remove(String productId) => setQuantity(productId, 0);

  Future<CartSummary> clear() =>
      _apply(() => ref.read(cartRepositoryProvider).clear());

  Future<CartSummary> acknowledgePrices() =>
      _apply(() => ref.read(cartRepositoryProvider).acknowledgePrices());
}

/// Badge count on the «السلة» tab.
@riverpod
int cartItemCount(Ref ref) => ref.watch(cartProvider).value?.itemCount ?? 0;
