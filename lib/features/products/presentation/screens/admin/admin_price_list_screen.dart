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

/// The price table: a fixed header row over rows built only as they
/// scroll into view, so hundreds of products open as fast as ten. On a
/// narrow screen the whole table scrolls sideways rather than squeezing
/// its columns.
class _PriceTable extends StatelessWidget {
  final List<_PriceRow> rows;
  const _PriceTable({required this.rows});

  /// Column widths, name first. The name column takes any spare width.
  static const _numberColumn = 120.0;
  static const _minNameColumn = 180.0;
  static const _rowHeight = 48.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headerStyle = theme.textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.bold,
    );
    return LayoutBuilder(
      builder: (context, c) {
        final available = c.maxWidth - 32;
        final width = available < _minNameColumn + 3 * _numberColumn
            ? _minNameColumn + 3 * _numberColumn
            : available;

        Widget row(List<Widget> cells, {Color? color}) => Container(
          height: _rowHeight,
          color: color,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Expanded(child: cells[0]),
              for (final cell in cells.skip(1))
                SizedBox(
                  width: _numberColumn,
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: cell,
                  ),
                ),
            ],
          ),
        );

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: SizedBox(
            width: width,
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  row([
                    Text('الصنف', style: headerStyle),
                    Text('سعر البيع', style: headerStyle),
                    Text('سعر الشراء', style: headerStyle),
                    Text('الموجود بالمخزن', style: headerStyle),
                  ], color: theme.colorScheme.surfaceContainerHighest),
                  Expanded(
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: rows.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final r = rows[i];
                        return row([
                          Text(
                            r.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(Formatters.currency(r.sellingPrice)),
                          Text(Formatters.currency(r.costPrice)),
                          Text(
                            '${r.quantity}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: r.quantity == 0 ? AppColors.danger : null,
                            ),
                          ),
                        ]);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
