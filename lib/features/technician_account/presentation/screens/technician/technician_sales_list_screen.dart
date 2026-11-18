import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../../core/offline/outbox.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/money_text.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../../../auth/presentation/providers/auth_providers.dart';
import '../../../data/models/sale.dart';
import '../../../data/repositories/technician_account_repository.dart';
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
    final outbox = ref.watch(outboxProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('سجل مبيعاتي')),
      body: salesAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: 'تعذَّر تحميل المبيعات',
          onRetry: () => ref.invalidate(technicianSalesProvider(technicianId)),
        ),
        data: (sales) => ListenableBuilder(
          listenable: outbox,
          builder: (context, _) {
            // Sales made with no connection, newest first, until they sync.
            final waiting = outbox
                .pendingOf(technicianSaleKind)
                .reversed
                .toList();
            if (sales.isEmpty && waiting.isEmpty) {
              return const EmptyView(
                message: 'لا توجد مبيعات بعد',
                icon: Iconsax.shop_copy,
              );
            }
            return ListView.separated(
              itemCount: waiting.length + sales.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                if (i < waiting.length) {
                  final e = waiting[i];
                  final meta = e.meta ?? const {};
                  final total = (meta['total'] as num?)?.toDouble();
                  return ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.cloud_upload_outlined, size: 20),
                    ),
                    title: Text(
                      (meta['customer_name'] as String?) ?? 'عميل نقدي',
                    ),
                    subtitle: Text(
                      'في الانتظار · ${Formatters.dateTime(e.createdAt)}',
                    ),
                    trailing: total == null ? null : MoneyText(total),
                    onTap: () => context.push(Routes.technicianSync),
                  );
                }
                final s = sales[i - waiting.length];
                return ListTile(
                  leading: CircleAvatar(child: Text('#${s.saleNumber}')),
                  title: Text(s.customerName ?? 'عميل نقدي'),
                  subtitle: Text(
                    '${paymentMethodLabelAr(s.paymentMethod)} · ${Formatters.dateTime(s.createdAt)}',
                  ),
                  trailing: MoneyText(s.total),
                  onTap: () => context.push(Routes.technicianSaleDetail(s.id)),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
