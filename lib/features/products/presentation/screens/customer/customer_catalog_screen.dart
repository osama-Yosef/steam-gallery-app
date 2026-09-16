import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../../../notifications/presentation/widgets/notification_bell_icon.dart';
import '../../../data/models/catalog_query.dart';
import '../../../data/models/product_category.dart';
import '../../../presentation/providers/product_providers.dart';
import '../../widgets/catalog_filter_sheet.dart';
import '../../widgets/product_card.dart';

/// «المتجر»: server-side search, category / price / availability filters,
/// sorting and infinite scroll (rpc_browse_products). The home screen opens
/// it pre-filtered when a category is tapped ([initialCategoryId]).
class CustomerCatalogScreen extends ConsumerStatefulWidget {
  final String? initialCategoryId;
  const CustomerCatalogScreen({super.key, this.initialCategoryId});

  @override
  ConsumerState<CustomerCatalogScreen> createState() =>
      _CustomerCatalogScreenState();
}

class _CustomerCatalogScreenState extends ConsumerState<CustomerCatalogScreen> {
  static const _searchDebounce = Duration(milliseconds: 400);

  final _searchCtrl = TextEditingController();
  final _scroll = ScrollController();
  Timer? _debounce;
  late CatalogQuery _query = CatalogQuery(categoryId: widget.initialCategoryId);

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_maybeLoadMore);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _setQuery(CatalogQuery q) {
    if (q == _query) return;
    setState(() => _query = q);
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  void _onSearchChanged(String value) {
    setState(() {}); // clear button visibility
    _debounce?.cancel();
    _debounce = Timer(_searchDebounce, () {
      if (mounted) _setQuery(_query.copyWith(search: _term(value)));
    });
  }

  // '' and null are the same search; keep one provider key for both.
  static String? _term(String v) => v.trim().isEmpty ? null : v.trim();

  void _maybeLoadMore() {
    if (!_scroll.hasClients) return;
    final pos = _scroll.position;
    if (pos.pixels >= pos.maxScrollExtent - 600) {
      ref.read(catalogProductsProvider(_query).notifier).loadMore();
    }
  }

  void _clearAll() {
    _debounce?.cancel();
    _searchCtrl.clear();
    _setQuery(CatalogQuery(sort: _query.sort));
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider(activeOnly: true));
    final resultsAsync = ref.watch(catalogProductsProvider(_query));

    return Scaffold(
      appBar: AppBar(
        title: const Text('المتجر'),
        actions: const [NotificationBellIcon()],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              key: const Key('catalog-search'),
              controller: _searchCtrl,
              maxLength: 100,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'ابحث باسم المنتج أو الكود...',
                counterText: '',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        tooltip: 'مسح البحث',
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _debounce?.cancel();
                          _searchCtrl.clear();
                          _setQuery(_query.copyWith(search: null));
                        },
                      )
                    : null,
              ),
              onChanged: _onSearchChanged,
              onSubmitted: (v) {
                _debounce?.cancel();
                _setQuery(_query.copyWith(search: _term(v)));
              },
            ),
          ),
          categoriesAsync.maybeWhen(
            data: (all) => _CategoryBar(
              categories: all,
              selectedId: _query.categoryId,
              onSelected: (id) => _setQuery(_query.copyWith(categoryId: id)),
            ),
            orElse: () => const SizedBox(height: 52),
          ),
          _Toolbar(
            query: _query,
            count: resultsAsync.value?.items.length,
            hasMore: resultsAsync.value?.hasMore ?? false,
            onSort: (s) => _setQuery(_query.copyWith(sort: s)),
            onFilter: () async {
              final q = await showCatalogFilterSheet(context, _query);
              if (q != null) _setQuery(q);
            },
          ),
          Expanded(
            child: resultsAsync.when(
              // Keep showing the previous grid while a new query loads.
              skipLoadingOnReload: true,
              loading: () => const LoadingView(),
              error: (e, _) => ErrorView(
                message: 'تعذَّر تحميل المنتجات',
                onRetry: () => ref.invalidate(catalogProductsProvider(_query)),
              ),
              data: (page) {
                if (page.items.isEmpty) {
                  return EmptyView(
                    message: _query.hasAnyFilter
                        ? 'لا توجد منتجات مطابقة'
                        : 'لا توجد منتجات بعد',
                    icon: Icons.inventory_2_outlined,
                    action: _query.hasAnyFilter
                        ? OutlinedButton(
                            onPressed: _clearAll,
                            child: const Text('مسح البحث والفلاتر'),
                          )
                        : null,
                  );
                }
                return RefreshIndicator(
                  onRefresh: () =>
                      ref.refresh(catalogProductsProvider(_query).future),
                  child: CustomScrollView(
                    key: const Key('catalog-grid'),
                    controller: _scroll,
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                        sliver: SliverGrid.builder(
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 220,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 0.72,
                              ),
                          itemCount: page.items.length,
                          itemBuilder: (context, i) =>
                              ProductCard(product: page.items[i]),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: _PageFooter(
                          page: page,
                          onRetry: () => ref
                              .read(catalogProductsProvider(_query).notifier)
                              .loadMore(),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Top-level category chips, plus a second row with the sub-categories of the
/// selected one (the RPC includes sub-categories when a parent is chosen).
class _CategoryBar extends StatelessWidget {
  final List<ProductCategory> categories;
  final String? selectedId;
  final ValueChanged<String?> onSelected;
  const _CategoryBar({
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final grouped = groupCategories(categories);
    ProductCategory? selected;
    for (final c in categories) {
      if (c.id == selectedId) selected = c;
    }
    final rootId = selected == null
        ? null
        : grouped.roots.any((r) => r.id == selected!.id)
        ? selected.id
        : selected.parentId;
    final subs = rootId == null
        ? const <ProductCategory>[]
        : grouped.children[rootId] ?? const [];

    Widget row(List<Widget> chips) => SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) => chips[i],
      ),
    );

    return Column(
      children: [
        row([
          ChoiceChip(
            label: const Text('الكل'),
            selected: selectedId == null,
            onSelected: (_) => onSelected(null),
          ),
          for (final c in grouped.roots)
            ChoiceChip(
              label: Text(c.name),
              selected: rootId == c.id,
              onSelected: (_) => onSelected(c.id),
            ),
        ]),
        if (subs.isNotEmpty)
          row([
            ChoiceChip(
              label: const Text('الكل'),
              selected: selectedId == rootId,
              onSelected: (_) => onSelected(rootId),
            ),
            for (final c in subs)
              ChoiceChip(
                label: Text(c.name),
                selected: selectedId == c.id,
                onSelected: (_) => onSelected(c.id),
              ),
          ]),
      ],
    );
  }
}

class _Toolbar extends StatelessWidget {
  final CatalogQuery query;
  final int? count;
  final bool hasMore;
  final ValueChanged<CatalogSort> onSort;
  final VoidCallback onFilter;
  const _Toolbar({
    required this.query,
    required this.count,
    required this.hasMore,
    required this.onSort,
    required this.onFilter,
  });

  @override
  Widget build(BuildContext context) {
    final filters = query.sheetFilterCount;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              count == null
                  ? ''
                  : hasMore
                  ? 'يتم عرض $count منتج'
                  : '$count منتج',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          PopupMenuButton<CatalogSort>(
            key: const Key('catalog-sort'),
            initialValue: query.sort,
            onSelected: onSort,
            itemBuilder: (_) => [
              for (final s in CatalogSort.values)
                PopupMenuItem(value: s, child: Text(s.labelAr)),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.sort, size: 20),
                  const SizedBox(width: 4),
                  Text(query.sort.labelAr),
                ],
              ),
            ),
          ),
          TextButton.icon(
            key: const Key('catalog-filter'),
            onPressed: onFilter,
            icon: Badge(
              isLabelVisible: filters > 0,
              label: Text('$filters'),
              child: const Icon(Icons.tune, size: 20),
            ),
            label: const Text('فلترة'),
          ),
        ],
      ),
    );
  }
}

class _PageFooter extends StatelessWidget {
  final CatalogPage page;
  final VoidCallback onRetry;
  const _PageFooter({required this.page, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    if (page.loadingMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (page.loadMoreFailed) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('تعذَّر تحميل المزيد — إعادة المحاولة'),
          ),
        ),
      );
    }
    if (page.hasMore) {
      // Short first pages don't scroll, so offer an explicit button too.
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Center(
          child: TextButton(
            onPressed: onRetry,
            child: const Text('عرض المزيد'),
          ),
        ),
      );
    }
    return const SizedBox(height: 16);
  }
}
