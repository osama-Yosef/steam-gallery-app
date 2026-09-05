import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/widgets/money_text.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../providers/customer_account_providers.dart';

class AdminCustomersListScreen extends ConsumerStatefulWidget {
  const AdminCustomersListScreen({super.key});

  @override
  ConsumerState<AdminCustomersListScreen> createState() =>
      _AdminCustomersListScreenState();
}

class _AdminCustomersListScreenState
    extends ConsumerState<AdminCustomersListScreen> {
  final _searchCtrl = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(
      customerAccountsProvider(search: _search.isEmpty ? null : _search),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('العملاء')),
      body: Column(
        children: [
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
            child: accountsAsync.when(
              loading: () => const LoadingView(),
              error: (e, _) => ErrorView(
                message: 'تعذَّر تحميل العملاء',
                onRetry: () => ref.invalidate(customerAccountsProvider),
              ),
              data: (accounts) {
                if (accounts.isEmpty) {
                  return const EmptyView(
                    message: 'لا يوجد عملاء بعد',
                    icon: Icons.people_outline,
                  );
                }
                return ListView.separated(
                  itemCount: accounts.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final a = accounts[i];
                    return ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.person_outline),
                      ),
                      title: Text(a.customerName),
                      subtitle: Text(
                        'إجمالي المشتريات: ${a.totalPurchases.toStringAsFixed(2)} ج.م',
                      ),
                      trailing: MoneyText(
                        a.remainingBalance,
                        style: a.remainingBalance > 0
                            ? TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontWeight: FontWeight.bold,
                              )
                            : null,
                      ),
                      onTap: () async {
                        // Refresh only once we're actually back on this
                        // screen — see AdminProductFormScreen for why a
                        // cross-screen invalidate() alone isn't reliable.
                        await context.push(
                          Routes.adminCustomerDetail(a.customerId),
                        );
                        ref.invalidate(customerAccountsProvider);
                      },
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
