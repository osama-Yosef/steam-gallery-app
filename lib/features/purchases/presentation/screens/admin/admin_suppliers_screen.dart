import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../providers/purchases_providers.dart';
import '../../widgets/pay_supplier_dialog.dart';

/// Suppliers and what the gallery owes each (unpaid purchase invoices).
class AdminSuppliersScreen extends ConsumerWidget {
  const AdminSuppliersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suppliersAsync = ref.watch(suppliersProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('الموردين')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(suppliersProvider),
        child: suppliersAsync.when(
          loading: () => const LoadingView(),
          error: (e, _) => ErrorView(
            message: 'تعذَّر تحميل الموردين',
            onRetry: () => ref.invalidate(suppliersProvider),
          ),
          data: (suppliers) {
            if (suppliers.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  EmptyView(
                    message:
                        'لا يوجد موردين بعد — المورد بيتسجل تلقائيًا مع أول فاتورة شراء له',
                    icon: Iconsax.profile_2user_copy,
                  ),
                ],
              );
            }
            final totalDue = suppliers.fold<double>(
              0,
              (s, x) => s + (x.balance > 0 ? x.balance : 0),
            );
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: ListTile(
                    leading: const Icon(Iconsax.card_send_copy),
                    title: const Text('إجمالي المستحق للموردين'),
                    trailing: Text(
                      Formatters.currency(totalDue),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: totalDue > 0 ? AppColors.danger : null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                for (final s in suppliers)
                  Card(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => context.push(
                        Routes.adminSupplierInvoices(s.id, s.name),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.name,
                                    style: theme.textTheme.titleSmall,
                                  ),
                                  if (s.phone != null)
                                    Text(
                                      s.phone!,
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  Text(
                                    '${s.invoicesCount} فاتورة · مشتريات ${Formatters.currency(s.totalInvoices)}',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    s.balance > 0
                                        ? 'مستحق له ${Formatters.currency(s.balance)}'
                                        : 'لا يوجد مستحق',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: s.balance > 0
                                          ? AppColors.danger
                                          : AppColors.success,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (s.balance > 0)
                              FilledButton.tonal(
                                onPressed: () async {
                                  await showPaySupplierDialog(
                                    context,
                                    ref,
                                    supplierId: s.id,
                                    supplierName: s.name,
                                    maxAmount: s.balance,
                                  );
                                },
                                child: const Text('سداد'),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
