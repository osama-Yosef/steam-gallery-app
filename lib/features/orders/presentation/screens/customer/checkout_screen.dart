import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../../../core/errors/app_exception.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../auth/presentation/providers/auth_providers.dart';
import '../../../../cart/presentation/providers/cart_provider.dart';
import '../../../presentation/providers/order_providers.dart';

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

  Future<void> _placeOrder() async {
    final items = ref.read(cartProvider);
    final profile = ref.read(currentUserProfileProvider).value;
    if (profile == null || items.isEmpty) return;

    setState(() => _submitting = true);
    try {
      final orderId = await ref
          .read(orderRepositoryProvider)
          .createOrder(
            customerId: profile.id,
            items: items,
            deliveryAddress: _addressCtrl.text.trim().isEmpty
                ? null
                : _addressCtrl.text.trim(),
            notes: _notesCtrl.text.trim().isEmpty
                ? null
                : _notesCtrl.text.trim(),
            clientRequestId: _clientRequestId,
          );
      ref.read(cartProvider.notifier).clear();
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
    final items = ref.watch(cartProvider);
    final total = ref.watch(cartTotalProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('تأكيد الطلب')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
                  for (final item in items)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${item.name} × ${item.quantity}'),
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
                        Formatters.currency(total),
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
            onPressed: _submitting || items.isEmpty ? null : _placeOrder,
            child: _submitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('إرسال الطلب'),
          ),
        ],
      ),
    );
  }
}
