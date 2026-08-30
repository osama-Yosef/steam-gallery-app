import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../../../auth/presentation/providers/auth_providers.dart';
import '../../../data/models/order.dart';
import '../../../presentation/providers/order_providers.dart';

class CustomerOrdersListScreen extends ConsumerWidget {
  const CustomerOrdersListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentUserProfileProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('طلباتي')),
      body: profile == null
          ? const LoadingView()
          : ref.watch(customerOrdersProvider(profile.id)).when(
                loading: () => const LoadingView(),
                error: (e, _) => const ErrorView(message: 'تعذَّر تحميل الطلبات'),
                data: (orders) {
                  if (orders.isEmpty) {
                    return const EmptyView(message: 'لا توجد طلبات بعد', icon: Icons.receipt_long_outlined);
                  }
                  return ListView.separated(
                    itemCount: orders.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final o = orders[i];
                      return ListTile(
                        title: Text('طلب #${o.orderNumber}'),
                        subtitle: Text('${orderStatusLabelAr(o.status)} · ${Formatters.date(o.createdAt)}'),
                        trailing: Text(Formatters.currency(o.total)),
                        onTap: () => context.push(Routes.customerOrderDetail(o.id)),
                      );
                    },
                  );
                },
              ),
    );
  }
}
