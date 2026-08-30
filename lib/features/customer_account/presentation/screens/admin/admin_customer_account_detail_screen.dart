import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/money_text.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../../data/models/customer_account_transaction.dart';
import '../../providers/customer_account_providers.dart';

class AdminCustomerAccountDetailScreen extends ConsumerWidget {
  final String customerId;
  const AdminCustomerAccountDetailScreen({super.key, required this.customerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(customerAccountSummaryProvider(customerId));
    final txnsAsync = ref.watch(customerAccountTransactionsProvider(customerId));

    return Scaffold(
      appBar: AppBar(title: const Text('كشف حساب العميل')),
      body: summaryAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: 'تعذَّر تحميل الحساب',
          onRetry: () => ref.invalidate(customerAccountSummaryProvider(customerId)),
        ),
        data: (summary) {
          if (summary == null) return const EmptyView(message: 'لا يوجد حساب لهذا العميل');
          return Column(
            children: [
              Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(summary.customerName, style: Theme.of(context).textTheme.titleLarge),
                      const Divider(height: 24),
                      _row(context, 'إجمالي المشتريات', summary.totalPurchases),
                      const SizedBox(height: 8),
                      _row(context, 'إجمالي المدفوع', summary.totalPaid),
                      const SizedBox(height: 8),
                      _row(context, 'الرصيد المتبقي', summary.remainingBalance, emphasize: true),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: FilledButton.icon(
                  onPressed: summary.remainingBalance <= 0
                      ? null
                      : () async {
                          await context.push(Routes.adminCustomerPayment(customerId));
                          ref.invalidate(customerAccountSummaryProvider(customerId));
                          ref.invalidate(customerAccountTransactionsProvider(customerId));
                        },
                  icon: const Icon(Icons.payments_outlined),
                  label: const Text('تسجيل دفعة'),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text('سجل الحركات', style: Theme.of(context).textTheme.titleMedium),
                ),
              ),
              Expanded(
                child: txnsAsync.when(
                  loading: () => const LoadingView(),
                  error: (e, _) => const ErrorView(message: 'تعذَّر تحميل الحركات'),
                  data: (txns) {
                    if (txns.isEmpty) {
                      return const EmptyView(message: 'لا توجد حركات بعد', icon: Icons.receipt_long_outlined);
                    }
                    return ListView.separated(
                      itemCount: txns.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final t = txns[i];
                        return ListTile(
                          leading: Icon(
                            t.amount > 0 ? Icons.add_circle_outline : Icons.remove_circle_outline,
                            color: t.amount > 0
                                ? Theme.of(context).colorScheme.error
                                : Colors.green.shade700,
                          ),
                          title: Text(custAccountTxnTypeLabelAr(t.type)),
                          subtitle: Text(
                            Formatters.dateTime(t.createdAt) + (t.notes != null ? ' · ${t.notes}' : ''),
                          ),
                          trailing: MoneyText(t.amount.abs()),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _row(BuildContext context, String label, double amount, {bool emphasize = false}) {
    final style = emphasize ? Theme.of(context).textTheme.titleMedium : null;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        MoneyText(amount, style: style),
      ],
    );
  }
}
