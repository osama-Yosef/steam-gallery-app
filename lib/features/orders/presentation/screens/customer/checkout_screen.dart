import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../../../core/errors/app_exception.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../../../auth/presentation/providers/auth_providers.dart';
import '../../../../cart/data/models/cart.dart';
import '../../../../cart/presentation/providers/cart_provider.dart';
import '../../../presentation/providers/order_providers.dart';

/// Order summary and address/notes. The lines and their prices come from the
/// server cart (0035) — this screen never computes or sends money itself.
/// Address/payment-method selection is Phase 8's job; for now this collects
/// free-text delivery details, same as before.
class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _addressCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  // Generated once and reused across retries of the SAME checkout attempt
  // so a flaky connection can't create duplicate orders (NFR-11).
  final String _clientRequestId = const Uuid().v4();
  bool _submitting = false;

  @override
  void dispose() {
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _placeOrder(CartSummary cart) async {
    final profile = ref.read(currentUserProfileProvider).value;
    if (profile == null || !cart.canCheckout) return;

    setState(() => _submitting = true);
    try {
      final orderId = await ref
          .read(orderRepositoryProvider)
          .createOrder(
            customerId: profile.id,
            items: [
              for (final line in cart.items)
                (productId: line.productId, quantity: line.quantity),
            ],
            deliveryAddress: _addressCtrl.text.trim().isEmpty
                ? null
                : _addressCtrl.text.trim(),
            notes: _notesCtrl.text.trim().isEmpty
                ? null
                : _notesCtrl.text.trim(),
            clientRequestId: _clientRequestId,
          );
      // The order snapshotted its own prices server-side; the cart's job is
      // done, so empty it (best-effort — a failure here shouldn't block
      // navigating to the order that was already created).
      unawaited(ref.read(cartProvider.notifier).clear());
      if (mounted) {
        context.pushReplacement(Routes.customerOrderDetail(orderId));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppException.from(e).messageAr)));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartAsync = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('تأكيد الطلب')),
      body: cartAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: 'تعذَّر تحميل السلة',
          onRetry: () => ref.invalidate(cartProvider),
        ),
        data: (cart) {
          if (cart.isEmpty) {
            return const EmptyView(
              message: 'السلة فارغة',
              icon: Icons.shopping_cart_outlined,
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (!cart.canCheckout)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'في منتجات بالسلة مش متاحة بالكمية دي. ارجع للسلة وعدّلها الأول.',
                  ),
                ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ملخص الطلب',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Divider(),
                      for (final item in cart.items)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text('${item.name} × ${item.quantity}'),
                              ),
                              Text(Formatters.currency(item.lineTotal)),
                            ],
                          ),
                        ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'الإجمالي',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            Formatters.currency(cart.subtotal),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _addressCtrl,
                decoration: const InputDecoration(labelText: 'عنوان التوصيل'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notesCtrl,
                decoration: const InputDecoration(labelText: 'ملاحظات (اختياري)'),
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _submitting || !cart.canCheckout
                    ? null
                    : () => _placeOrder(cart),
                child: _submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('إرسال الطلب'),
              ),
            ],
          );
        },
      ),
    );
  }
}
