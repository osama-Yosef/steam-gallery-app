import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/money_text.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../../../auth/presentation/providers/auth_providers.dart';
import '../../../data/models/sale.dart';
import '../../providers/technician_account_providers.dart';

class TechnicianSalesListScreen extends ConsumerWidget {
  const TechnicianSalesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final technicianId = ref.watch(currentUserProfileProvider).value?.id;
    if (technicianId == null) {
      return const Scaffold(body: LoadingView());
    }

    final salesAsync = ref.watch(technicianSalesProvider(technicianId));

    return Scaffold(
      appBar: AppBar(title: const Text('سجل مبيعاتي')),
      body: salesAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: 'تعذَّر تحميل المبيعات',
          onRetry: () => ref.invalidate(technicianSalesProvider(technicianId)),
        ),
        data: (sales) {
          if (sales.isEmpty) {
            return const EmptyView(message: 'لا توجد مبيعات بعد', icon: Icons.point_of_sale_outlined);
          }
          return ListView.separated(
            itemCount: sales.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final s = sales[i];
              return ListTile(
                leading: CircleAvatar(child: Text('#${s.saleNumber}')),
                title: Text(s.customerName ?? 'عميل نقدي'),
                subtitle: Text('${paymentMethodLabelAr(s.paymentMethod)} · ${Formatters.dateTime(s.createdAt)}'),
                trailing: MoneyText(s.total),
                onTap: () => context.push(Routes.technicianSaleDetail(s.id)),
              );
            },
          );
        },
      ),
    );
  }
}
