import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/money_text.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../../data/models/cash_transaction.dart';
import '../../providers/cashbox_providers.dart';

class AdminCashboxScreen extends ConsumerWidget {
  const AdminCashboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(cashboxBalanceProvider);
    final txnsAsync = ref.watch(cashTransactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الخزنة'),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined),
            tooltip: 'المصروفات',
            onPressed: () => context.push(Routes.adminExpenses),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openMovementSheet(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('حركة جديدة'),
      ),
      body: Column(
        children: [
          balanceAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => const Padding(
              padding: EdgeInsets.all(24),
              child: Text('تعذَّر تحميل رصيد الخزنة'),
            ),
            data: (balance) {
              if (balance == null) return const SizedBox.shrink();
              return Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        balance.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      MoneyText(
                        balance.balance,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                'كل الحركات المالية',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          Expanded(
            child: txnsAsync.when(
              loading: () => const LoadingView(),
              error: (e, _) => ErrorView(
                message: 'تعذَّر تحميل الحركات',
                onRetry: () => ref.invalidate(cashTransactionsProvider),
              ),
              data: (txns) {
                if (txns.isEmpty) {
                  return const EmptyView(
                    message: 'لا توجد حركات مالية بعد',
                    icon: Icons.receipt_long_outlined,
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.only(bottom: 88),
                  itemCount: txns.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final t = txns[i];
                    return ListTile(
                      leading: _typeIcon(context, t.type),
                      title: Text(cashTxnTypeLabelAr(t.type)),
                      subtitle: Text(
                        Formatters.dateTime(t.createdAt) +
                            (t.notes != null ? ' · ${t.notes}' : ''),
                      ),
                      trailing: MoneyText(t.amount, colorBySign: true),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Three ways money moves by hand: an expense (hits the profit reports) and
  /// a deposit/withdrawal (till balance only). They're listed together so the
  /// difference is a deliberate choice at the moment of recording, not
  /// something the admin discovers later in the reports.
  Future<void> _openMovementSheet(BuildContext context, WidgetRef ref) async {
    final route = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.remove_circle_outline),
              title: const Text('تسجيل مصروف'),
              subtitle: const Text('يخصم من الخزنة ويُحتسب في المصروفات'),
              onTap: () =>
                  Navigator.of(sheetContext).pop(Routes.adminExpenseNew),
            ),
            ListTile(
              leading: const Icon(
                Icons.south_west_rounded,
                color: AppColors.success,
              ),
              title: const Text('إيداع في الخزنة'),
              subtitle: const Text('يزوّد الرصيد فقط، بدون أي أثر على الأرباح'),
              onTap: () =>
                  Navigator.of(sheetContext).pop(Routes.adminCashDeposit),
            ),
            ListTile(
              leading: const Icon(Icons.north_east_rounded),
              title: const Text('سحب من الخزنة'),
              subtitle: const Text(
                'يخصم من الرصيد فقط، بدون أي أثر على الأرباح',
              ),
              onTap: () =>
                  Navigator.of(sheetContext).pop(Routes.adminCashWithdraw),
            ),
          ],
        ),
      ),
    );
    if (route == null || !context.mounted) return;
    await context.push(route);
    ref.invalidate(cashboxBalanceProvider);
    ref.invalidate(cashTransactionsProvider);
  }

  Widget _typeIcon(BuildContext context, CashTxnType type) {
    final isIncome = switch (type) {
      CashTxnType.sale ||
      CashTxnType.technicianDeposit ||
      CashTxnType.otherIncome => true,
      CashTxnType.expense || CashTxnType.otherExpense => false,
      CashTxnType.refund ||
      CashTxnType.adjustment ||
      CashTxnType.purchase => null,
    };
    if (isIncome == null) return const Icon(Icons.swap_horiz);
    return Icon(
      isIncome ? Icons.arrow_downward : Icons.arrow_upward,
      color: isIncome ? AppColors.success : Theme.of(context).colorScheme.error,
    );
  }
}
