import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/state_views.dart';
import '../providers/cart_provider.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(cartProvider);
    final total = ref.watch(cartTotalProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('السلة')),
      body: items.isEmpty
          ? const EmptyView(
              message: 'السلة فارغة',
              icon: Icons.shopping_cart_outlined,
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const Divider(height: 24),
                    itemBuilder: (context, i) {
                      final item = items[i];
                      return Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                const SizedBox(height: 4),
                                Text(Formatters.currency(item.unitPrice)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () => ref
                                .read(cartProvider.notifier)
                                .setQuantity(item.productId, item.quantity - 1),
                          ),
                          Text(
                            '${item.quantity}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () => ref
                                .read(cartProvider.notifier)
                                .setQuantity(item.productId, item.quantity + 1),
                          ),
                          SizedBox(
                            width: 80,
                            child: Text(
                              Formatters.currency(item.lineTotal),
                              textAlign: TextAlign.end,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'الإجمالي',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              Formatters.currency(total),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: () =>
                              context.push(Routes.customerCheckout),
                          child: const Text('تأكيد الطلب'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
