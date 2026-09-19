import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/app_exception.dart';
import '../models/cart.dart';

/// Server-side cart (0035). Every call returns the freshly priced cart.
/// [optionIds] (0049) identifies which line: a product with a different
/// combination of selected options is a different line.
abstract class CartRepository {
  Future<CartSummary> getCart();
  Future<CartSummary> addItem(
    String productId,
    int quantity, {
    List<String> optionIds = const [],
  });
  Future<CartSummary> setQuantity(
    String productId,
    int quantity, {
    List<String> optionIds = const [],
  });
  Future<CartSummary> clear();
  Future<CartSummary> acknowledgePrices();
}

class SupabaseCartRepository implements CartRepository {
  final SupabaseClient _client;
  SupabaseCartRepository(this._client);

  Future<CartSummary> _call(String fn, [Map<String, dynamic>? params]) async {
    try {
      final res = await _client.rpc(fn, params: params);
      return CartSummary.fromRpc(Map<String, dynamic>.from(res as Map));
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<CartSummary> getCart() => _call('rpc_get_my_cart');

  @override
  Future<CartSummary> addItem(
    String productId,
    int quantity, {
    List<String> optionIds = const [],
  }) => _call('rpc_cart_add_item', {
    'p_product_id': productId,
    'p_quantity': quantity,
    'p_option_ids': optionIds,
  });

  @override
  Future<CartSummary> setQuantity(
    String productId,
    int quantity, {
    List<String> optionIds = const [],
  }) => _call('rpc_cart_set_item', {
    'p_product_id': productId,
    'p_quantity': quantity,
    'p_option_ids': optionIds,
  });

  @override
  Future<CartSummary> clear() => _call('rpc_cart_clear');

  @override
  Future<CartSummary> acknowledgePrices() =>
      _call('rpc_cart_acknowledge_prices');
}
