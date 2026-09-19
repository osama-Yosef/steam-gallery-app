import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/money_text.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../../../auth/data/models/app_user.dart';
import '../../../../auth/presentation/providers/auth_providers.dart';
import '../../../data/models/cash_transaction.dart';
import '../../../data/models/cashbox_balance.dart';
import '../../providers/cashbox_providers.dart';

/// Four clearly distinct colours so the kind of money movement reads at a
/// glance: sales/technician deposits are genuine income (green), a manual
/// cash deposit tops up the till (teal), a manual withdrawal takes cash out
/// (amber), and an expense is the one that hits the profit reports (red).
/// Refunds/adjustments/purchases are rarer edge cases, kept neutral.
Color cashTxnTypeColor(CashTxnType t) => switch (t) {
  CashTxnType.sale || CashTxnType.technicianDeposit => AppColors.success,
  CashTxnType.otherIncome => AppColors.info,
  CashTxnType.otherExpense => AppColors.warning,
  CashTxnType.expense => AppColors.danger,
  CashTxnType.refund ||
  CashTxnType.adjustment ||
  CashTxnType.purchase => AppColors.textSecondary,
};

IconData _cashTxnTypeIcon(CashTxnType t) => switch (t) {
  CashTxnType.sale => Iconsax.card_pos_copy,
  CashTxnType.technicianDeposit => Iconsax.wallet_add_copy,
  CashTxnType.otherIncome => Iconsax.arrow_down_2_copy,
  CashTxnType.otherExpense => Iconsax.arrow_up_2_copy,
  CashTxnType.expense => Iconsax.receipt_minus_copy,
  CashTxnType.refund => Iconsax.receipt_2_copy,
  CashTxnType.adjustment => Iconsax.arrow_swap_horizontal_copy,
  CashTxnType.purchase => Iconsax.box_add_copy,
};

/// Two tills since 0059 (cash + transfer) — this screen shows both balances
/// and lets the transaction list be filtered to just one, "الكل" (both
/// mixed, sorted by date) being the default.
class AdminCashboxScreen extends ConsumerStatefulWidget {
  const AdminCashboxScreen({super.key});

  @override
  ConsumerState<AdminCashboxScreen> createState() =>
      _AdminCashboxScreenState();
}

class _AdminCashboxScreenState extends ConsumerState<AdminCashboxScreen> {
  // null = both tills mixed together.
  String? _cashboxFilter;

  Future<void> _openMovementSheet(bool isSales) async {
    final route = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Iconsax.receipt_minus_copy,
                color: AppColors.danger,
              ),
              title: const Text('تسجيل مصروف'),
              subtitle: const Text('يخصم من الخزنة ويُحتسب في المصروفات'),
              onTap: () => Navigator.of(sheetContext).pop(
                isSales ? Routes.salesExpenseNew : Routes.adminExpenseNew,
              ),
            ),
            ListTile(
              leading: const Icon(
                Iconsax.arrow_down_2_copy,
                color: AppColors.info,
              ),
              title: const Text('إيداع في الخزنة'),
              subtitle: const Text('يزوّد الرصيد فقط، بدون أي أثر على الأرباح'),
              onTap: () => Navigator.of(sheetContext).pop(
                isSales ? Routes.salesCashDeposit : Routes.adminCashDeposit,
              ),
            ),
            ListTile(
              leading: const Icon(
                Iconsax.arrow_up_2_copy,
                color: AppColors.warning,
              ),
              title: const Text('سحب من الخزنة'),
              subtitle: const Text(
                'يخصم من الرصيد فقط، بدون أي أثر على الأرباح',
              ),
              onTap: () => Navigator.of(sheetContext).pop(
                isSales ? Routes.salesCashWithdraw : Routes.adminCashWithdraw,
              ),
            ),
          ],
        ),
      ),
    );
    if (route == null || !mounted) return;
    await context.push(route);
    ref.invalidate(cashboxBalancesProvider);
    ref.invalidate(cashTransactionsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final balancesAsync = ref.watch(cashboxBalancesProvider);
    final txnsAsync = ref.watch(cashTransactionsProvider(_cashboxFilter));
    final isSales =
        ref.watch(currentUserProfileProvider).value?.role == AppRole.sales;

    return Scaffold(
      appBar: AppBar(
        title: const Text('الخزنة'),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.receipt_text_copy),
            tooltip: 'المصروفات',
            onPressed: () => context.push(
              isSales ? Routes.salesExpenses : Routes.adminExpenses,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openMovementSheet(isSales),
        icon: const Icon(Iconsax.add_copy),
        label: const Text('حركة جديدة'),
      ),
      body: Column(
        children: [
          balancesAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => const Padding(
              padding: EdgeInsets.all(24),
              child: Text('تعذَّر تحميل رصيد الخزنة'),
            ),
            data: (balances) {
              if (balances.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  children: [
                    for (final b in balances) ...[
                      Expanded(child: _BalanceCard(balance: b)),
                      if (b != balances.last) const SizedBox(width: 12),
                    ],
                  ],
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'كل الحركات المالية',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                DropdownButton<String?>(
                  value: _cashboxFilter,
                  underline: const SizedBox.shrink(),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('الكل')),
                    ...?balancesAsync.value?.map(
                      (b) => DropdownMenuItem(
                        value: b.cashboxId,
                        child: Text(cashboxKindLabelAr(b.kind)),
                      ),
                    ),
                  ],
                  onChanged: (v) => setState(() => _cashboxFilter = v),
                ),
              ],
            ),
          ),
          Expanded(
            child: txnsAsync.when(
              loading: () => const LoadingView(),
              error: (e, _) => ErrorView(
                message: 'تعذَّر تحميل الحركات',
                onRetry: () =>
                    ref.invalidate(cashTransactionsProvider(_cashboxFilter)),
              ),
              data: (txns) {
                if (txns.isEmpty) {
                  return const EmptyView(
                    message: 'لا توجد حركات مالية بعد',
                    icon: Iconsax.receipt_text_copy,
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(0, 8, 0, 88),
                  itemCount: txns.length,
                  itemBuilder: (context, i) => _TxnTile(txn: txns[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final CashboxBalance balance;
  const _BalanceCard({required this.balance});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              cashboxKindLabelAr(balance.kind),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            MoneyText(
              balance.balance,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      ),
    );
  }
}

/// A full-width, colour-coded card — same visual language as the admin
/// orders/maintenance/products tiles, with [cashTxnTypeColor] making the
/// kind of movement (income/deposit/withdrawal/expense) read at a glance.
class _TxnTile extends StatelessWidget {
  final CashTransaction txn;
  const _TxnTile({required this.txn});

  @override
  Widget build(BuildContext context) {
    final color = cashTxnTypeColor(txn.type);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: color.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: color),
                  child: Icon(
                    _cashTxnTypeIcon(txn.type),
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
                        cashTxnTypeLabelAr(txn.type),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        Formatters.dateTime(txn.createdAt) +
                            (txn.notes != null ? ' · ${txn.notes}' : ''),
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                MoneyText(
                  txn.amount,
                  colorBySign: true,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
