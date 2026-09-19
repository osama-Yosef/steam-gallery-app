import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/money_text.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../../data/models/warehouse_stock_item.dart';
import '../../providers/inventory_providers.dart';

/// Admin-only (0046) — sales no longer sees the warehouse at all, so this
/// screen dropped the isSales branching it used to need.
class AdminWarehouseScreen extends ConsumerStatefulWidget {
  const AdminWarehouseScreen({super.key});

  @override
  ConsumerState<AdminWarehouseScreen> createState() =>
      _AdminWarehouseScreenState();
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
              leading: const Icon(
                Iconsax.box_add_copy,
                color: AppColors.success,
              ),
              title: const Text('استلام بضاعة'),
              onTap: () => Navigator.of(ctx).pop('receive'),
            ),
            ListTile(
              leading: const Icon(
                Iconsax.box_remove_copy,
                color: AppColors.warning,
              ),
              title: const Text('صرف لصنايعي'),
              onTap: () => Navigator.of(ctx).pop('issue'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    final route = action == 'receive'
        ? Routes.adminReceivePurchase
        : Routes.adminIssueStock;
    await context.push(route);
    ref.invalidate(warehouseStockProvider);
  }

  @override
  Widget build(BuildContext context) {
    final stockAsync = ref.watch(
      warehouseStockProvider(search: _search.isEmpty ? null : _search),
    );
    final totalValue = stockAsync.value?.fold<double>(
      0,
      (sum, i) => sum + i.value,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('المخزن الرئيسي'),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.clock_copy),
            tooltip: 'حركات المخزون',
            onPressed: () => context.push(Routes.adminStockMovements),
          ),
          IconButton(
            icon: const Icon(Iconsax.personalcard_copy),
            tooltip: 'شنط الصنايعية',
            onPressed: () => context.push(Routes.adminTechnicianBags),
          ),
          IconButton(
            icon: const Icon(Iconsax.task_square_copy),
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
                      MoneyText(
                        totalValue,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ],
                  ),
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openActions,
        icon: const Icon(Iconsax.arrow_swap_horizontal_copy),
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
                prefixIcon: const Icon(Iconsax.search_normal_1_copy),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Iconsax.close_circle_copy),
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
                  return const EmptyView(
                    message: 'لا توجد أصناف بالمخزن',
                    icon: Iconsax.buildings_2_copy,
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 88),
                  itemCount: items.length,
                  itemBuilder: (context, i) => _StockTile(item: items[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// A full-width, colour-tinted card — same visual language as the redesigned
/// maintenance/order lists — red-tinted for low stock, neutral otherwise.
class _StockTile extends StatelessWidget {
  final WarehouseStockItem item;
  const _StockTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final color = item.isLow ? AppColors.danger : AppColors.primary;
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
                    item.isLow ? Iconsax.warning_2_copy : Iconsax.box_copy,
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
                        item.productName,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'SKU: ${item.sku} · الكمية: ${item.quantity}',
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                MoneyText(
                  item.value,
                  style: TextStyle(color: color, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
