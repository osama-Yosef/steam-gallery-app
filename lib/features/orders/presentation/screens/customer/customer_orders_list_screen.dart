import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../../../auth/presentation/providers/auth_providers.dart';
import '../../../data/models/order.dart';
import '../../../presentation/providers/order_providers.dart';
import '../../widgets/order_status_chips.dart';

class CustomerOrdersListScreen extends ConsumerWidget {
  const CustomerOrdersListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentUserProfileProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('طلباتي')),
      body: profile == null
          ? const LoadingView()
          : ref
                .watch(customerOrdersProvider(profile.id))
                .when(
                  loading: () => const LoadingView(),
                  error: (e, _) =>
                      const ErrorView(message: 'تعذَّر تحميل الطلبات'),
                  data: (orders) {
                    if (orders.isEmpty) {
                      return const EmptyView(
                        message: 'لا توجد طلبات بعد',
                        icon: Iconsax.receipt_text_copy,
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: orders.length,
                      itemBuilder: (context, i) => _OrderTile(order: orders[i]),
                    );
                  },
                ),
    );
  }
}

/// A full-width, colour-coded card — matches the maintenance-request tiles:
/// the order number is the first thing you read, and the status colour says
/// what stage it's at before you read the label.
class _OrderTile extends StatelessWidget {
  final Order order;
  const _OrderTile({required this.order});

  @override
  Widget build(BuildContext context) {
    final color = orderStatusColor(order.status);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: color.withValues(alpha: 0.08),
          child: InkWell(
            onTap: () => context.push(Routes.customerOrderDetail(order.id)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
                    child: const Icon(
                      Iconsax.receipt_text_copy,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'طلب #${order.orderNumber}',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          Formatters.date(order.createdAt),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        Formatters.currency(order.total),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          orderStatusLabelAr(order.status),
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
