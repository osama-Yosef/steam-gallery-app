import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/widgets/money_text.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../providers/wallet_providers.dart';

/// Admin-only, read-only view of every customer wallet (Phase 15) — the
/// wallet balance is a liability the shop owes back, invisible anywhere
/// else (it deliberately never touches cashbox_balances, 0040/0041).
class AdminWalletsListScreen extends ConsumerStatefulWidget {
  const AdminWalletsListScreen({super.key});

  @override
  ConsumerState<AdminWalletsListScreen> createState() =>
      _AdminWalletsListScreenState();
}

class _AdminWalletsListScreenState
    extends ConsumerState<AdminWalletsListScreen> {
  final _searchCtrl = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final liabilityAsync = ref.watch(walletLiabilityProvider);
    final walletsAsync = ref.watch(
      adminWalletsProvider(search: _search.isEmpty ? null : _search),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('محافظ العملاء')),
      body: Column(
        children: [
          liabilityAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (e, _) => const SizedBox.shrink(),
            data: (l) => Card(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              color: Theme.of(context).colorScheme.primaryContainer,
              child: ListTile(
                leading: const Icon(Icons.account_balance_outlined),
                title: const Text('إجمالي أرصدة المحافظ'),
                subtitle: Text('${l.walletCount} محفظة نشطة'),
                trailing: MoneyText(
                  l.totalLiability,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'ابحث بالاسم...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _search = '');
                        },
                      )
                    : null,
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          Expanded(
            child: walletsAsync.when(
              loading: () => const LoadingView(),
              error: (e, _) => ErrorView(
                message: 'تعذَّر تحميل المحافظ',
                onRetry: () => ref.invalidate(adminWalletsProvider),
              ),
              data: (wallets) {
                if (wallets.isEmpty) {
                  return const EmptyView(
                    message: 'لا توجد محافظ بعد',
                    icon: Icons.account_balance_wallet_outlined,
                  );
                }
                return ListView.separated(
                  itemCount: wallets.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final w = wallets[i];
                    return ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.person_outline),
                      ),
                      title: Text(w.customerName),
                      subtitle: w.isActive
                          ? null
                          : const Text('محفظة موقوفة'),
                      trailing: MoneyText(
                        w.balance,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: w.balance > 0
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                      ),
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
}
