import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../../data/models/wallet_models.dart';
import '../../providers/wallet_providers.dart';

/// Customer's "المحفظة": balance and transaction history. A separate
/// financial system from customer_accounts (deferred payment/debt) — never
/// shown mixed together (master prompt §5, §38).
class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(myWalletProvider);
    final txnsAsync = ref.watch(myWalletTransactionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('المحفظة')),
      body: walletAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: 'تعذَّر تحميل المحفظة',
          onRetry: () => ref.invalidate(myWalletProvider),
        ),
        data: (wallet) => RefreshIndicator(
          onRefresh: () async {
            await ref.read(myWalletProvider.notifier).refresh();
            ref.invalidate(myWalletTransactionsProvider);
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                color: AppColors.primaryDark,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'رصيدك',
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        Formatters.currency(wallet.balance),
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        key: const Key('wallet-topup'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primaryDark,
                        ),
                        onPressed: () =>
                            context.push(Routes.customerWalletTopup),
                        icon: const Icon(Icons.add),
                        label: const Text('شحن الرصيد'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'العمليات',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              txnsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => const Text('تعذَّر تحميل العمليات'),
                data: (txns) {
                  if (txns.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: Text('لا توجد عمليات بعد')),
                    );
                  }
                  return Column(
                    children: txns.map((t) => _TxnTile(txn: t)).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TxnTile extends StatelessWidget {
  final WalletTransaction txn;
  const _TxnTile({required this.txn});

  @override
  Widget build(BuildContext context) {
    final isCredit = txn.amount > 0;
    final color = isCredit ? AppColors.success : AppColors.textPrimary;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        isCredit ? Icons.add_circle_outline : Icons.remove_circle_outline,
        color: color,
      ),
      title: Text(walletTxnTypeLabelAr(txn.type)),
      subtitle: Text(Formatters.dateTime(txn.createdAt)),
      trailing: Text(
        '${isCredit ? '+' : ''}${Formatters.currency(txn.amount)}',
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
