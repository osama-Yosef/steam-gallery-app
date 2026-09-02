import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/money_text.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../../../auth/presentation/providers/auth_providers.dart';
import '../../../data/models/technician_account_transaction.dart';
import '../../providers/technician_account_providers.dart';

class TechnicianAccountHistoryScreen extends ConsumerWidget {
  final String? technicianId;
  const TechnicianAccountHistoryScreen({super.key, this.technicianId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resolvedId = technicianId ?? ref.watch(currentUserProfileProvider).value?.id;
    if (resolvedId == null) {
      return const Scaffold(body: LoadingView());
    }

    final txnsAsync = ref.watch(technicianAccountTransactionsProvider(resolvedId));

    return Scaffold(
      appBar: AppBar(title: const Text('سجل حركات الحساب')),
      body: txnsAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: 'تعذَّر تحميل السجل',
          onRetry: () => ref.invalidate(technicianAccountTransactionsProvider(resolvedId)),
        ),
        data: (txns) {
          if (txns.isEmpty) {
            return const EmptyView(message: 'لا توجد حركات بعد', icon: Icons.receipt_long_outlined);
          }
          return ListView.separated(
            itemCount: txns.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final t = txns[i];
              final increases = techAccountTxnIncreasesDue(t.type);
              return ListTile(
                leading: Icon(
                  increases ? Icons.add_circle_outline : Icons.remove_circle_outline,
                  color: increases ? Theme.of(context).colorScheme.error : AppColors.success,
                ),
                title: Text(techAccountTxnTypeLabelAr(t.type)),
                subtitle: Text(
                  Formatters.dateTime(t.createdAt) + (t.notes != null ? ' · ${t.notes}' : ''),
                ),
                trailing: MoneyText(t.amount),
              );
            },
          );
        },
      ),
    );
  }
}
