import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../../../inventory/presentation/providers/inventory_providers.dart';
import '../../providers/product_providers.dart';

/// "عرض السعر" — one table of every active stock product: name, selling
/// price, purchase (cost) price and how many are in the warehouse. For an
/// assembly product the quantity is how many its components can build.
/// Admin only: it shows cost prices.
class AdminPriceListScreen extends ConsumerStatefulWidget {
  const AdminPriceListScreen({super.key});

  @override
  ConsumerState<AdminPriceListScreen> createState() =>
      _AdminPriceListScreenState();
}

class _PriceRow {
  final String name;
  final double sellingPrice;
  final double costPrice;
  final int quantity;
  const _PriceRow(this.name, this.sellingPrice, this.costPrice, this.quantity);
}

class _AdminPriceListScreenState extends ConsumerState<AdminPriceListScreen> {
  String _search = '';

  void _refresh() {
    ref.invalidate(adminProductsProvider);
    ref.invalidate(warehouseStockProvider);
    ref.invalidate(assemblyStockProvider);
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(adminProductsProvider());
    final stockAsync = ref.watch(warehouseStockProvider());
    final assemblies = ref.watch(assemblyStockProvider).value ?? const [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('عرض السعر'),
        actions: [
          IconButton(
            tooltip: 'تحديث',
            icon: const Icon(Iconsax.refresh_copy),
            onPressed: _refresh,
          ),
        ],
      ),
      body: switch ((productsAsync, stockAsync)) {
        (AsyncError(), _) || (_, AsyncError()) => ErrorView(
          message: 'تعذَّر تحميل الأسعار',
          onRetry: _refresh,
        ),
        (AsyncData(value: final products), AsyncData(value: final stock)) =>
          () {
            final quantities = {
              for (final s in stock) s.productId: s.quantity,
              for (final a in assemblies) a.productId: a.quantity,
            };
            final q = _search.toLowerCase();
            final rows =
                products
                    .where((p) => p.isActive && !p.isService)
                    .where(
                      (p) =>
                          q.isEmpty ||
                          p.name.toLowerCase().contains(q) ||
                          p.sku.toLowerCase().contains(q),
                    )
                    .map(
                      (p) => _PriceRow(
                        p.name,
                        p.sellingPrice,
                        p.costPrice,
                        quantities[p.id] ?? 0,
                      ),
                    )
                    .toList()
                  ..sort((a, b) => a.name.compareTo(b.name));
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'ابحث باسم الصنف...',
                      prefixIcon: Icon(Iconsax.search_normal_1_copy),
                    ),
                    onChanged: (v) => setState(() => _search = v.trim()),
                  ),
                ),
                Expanded(
                  child: rows.isEmpty
                      ? EmptyView(
                          message: _search.isEmpty
                              ? 'لا توجد أصناف'
                              : 'لا توجد نتائج لـ "$_search"',
                          icon: Iconsax.box_copy,
                        )
                      : RefreshIndicator(
                          onRefresh: () async => _refresh(),
                          child: _PriceTable(rows: rows),
                        ),
                ),
              ],
            );
          }(),
        _ => const LoadingView(),
      },
    );
  }
}

class _PriceTable extends StatelessWidget {
  final List<_PriceRow> rows;
  const _PriceTable({required this.rows});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final header = theme.textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.bold,
    );
    return LayoutBuilder(
      builder: (context, c) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            // Fill the screen when it's wide, scroll sideways on a phone.
            constraints: BoxConstraints(minWidth: c.maxWidth - 32),
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: DataTable(
                headingRowColor: WidgetStatePropertyAll(
                  theme.colorScheme.surfaceContainerHighest,
                ),
                columnSpacing: 16,
                horizontalMargin: 12,
                columns: [
                  DataColumn(label: Text('الصنف', style: header)),
                  DataColumn(
                    numeric: true,
                    label: Text('سعر البيع', style: header),
                  ),
                  DataColumn(
                    numeric: true,
                    label: Text('سعر الشراء', style: header),
                  ),
                  DataColumn(
                    numeric: true,
                    label: Text('الموجود بالمخزن', style: header),
                  ),
                ],
                rows: [
                  for (final r in rows)
                    DataRow(
                      cells: [
                        DataCell(Text(r.name)),
                        DataCell(Text(Formatters.currency(r.sellingPrice))),
                        DataCell(Text(Formatters.currency(r.costPrice))),
                        DataCell(
                          Text(
                            '${r.quantity}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: r.quantity == 0 ? AppColors.danger : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
