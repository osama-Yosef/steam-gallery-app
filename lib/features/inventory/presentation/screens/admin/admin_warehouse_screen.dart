import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/widgets/money_text.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../providers/inventory_providers.dart';

class AdminWarehouseScreen extends ConsumerStatefulWidget {
  const AdminWarehouseScreen({super.key});

  @override
  ConsumerState<AdminWarehouseScreen> createState() => _AdminWarehouseScreenState();
}

class _AdminWarehouseScreenState extends ConsumerState<AdminWarehouseScreen> {
  final _searchCtrl = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _openActions() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.add_box_outlined),
              title: const Text('استلام بضاعة'),
              onTap: () => Navigator.of(ctx).pop('receive'),
            ),
            ListTile(
              leading: const Icon(Icons.outbox_outlined),
              title: const Text('صرف لصنايعي'),
              onTap: () => Navigator.of(ctx).pop('issue'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    final route = action == 'receive' ? Routes.adminReceivePurchase : Routes.adminIssueStock;
    await context.push(route);
    ref.invalidate(warehouseStockProvider);
  }

  @override
  Widget build(BuildContext context) {
    final stockAsync = ref.watch(warehouseStockProvider(search: _search.isEmpty ? null : _search));
    final totalValue = stockAsync.value?.fold<double>(0, (sum, i) => sum + i.value);

    return Scaffold(
      appBar: AppBar(
        title: const Text('المخزن الرئيسي'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'حركات المخزون',
            onPressed: () => context.push(Routes.adminStockMovements),
          ),
          IconButton(
            icon: const Icon(Icons.badge_outlined),
            tooltip: 'شنط الصنايعية',
            onPressed: () => context.push(Routes.adminTechnicianBags),
          ),
          IconButton(
            icon: const Icon(Icons.checklist_outlined),
            tooltip: 'الجرد',
            onPressed: () => context.push(Routes.adminInventoryCounts),
          ),
        ],
        // A fixed footer would sit under the FAB (which floats independently
        // of body layout), so the running total lives in the AppBar instead.
        bottom: totalValue == null
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(36),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('إجمالي قيمة المخزن (تكلفة): '),
                      MoneyText(totalValue, style: Theme.of(context).textTheme.titleSmall),
                    ],
                  ),
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openActions,
        icon: const Icon(Icons.swap_horiz),
        label: const Text('حركة مخزون'),
      ),
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
            child: stockAsync.when(
              loading: () => const LoadingView(),
              error: (e, _) => ErrorView(
                message: 'تعذَّر تحميل المخزون',
                onRetry: () => ref.invalidate(warehouseStockProvider),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return const EmptyView(message: 'لا توجد أصناف بالمخزن', icon: Icons.warehouse_outlined);
                }
                return ListView.separated(
                  padding: const EdgeInsets.only(bottom: 88),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final item = items[i];
                    return ListTile(
                      leading: item.isLow
                          ? Icon(Icons.warning_amber_rounded, color: Theme.of(context).colorScheme.error)
                          : const Icon(Icons.inventory_2_outlined),
                      title: Text(item.productName),
                      subtitle: Text('SKU: ${item.sku} · الكمية: ${item.quantity}'),
                      trailing: MoneyText(item.value),
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
