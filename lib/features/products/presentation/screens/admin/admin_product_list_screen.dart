import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/errors/app_exception.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../../presentation/providers/product_providers.dart';

class AdminProductListScreen extends ConsumerStatefulWidget {
  const AdminProductListScreen({super.key});

  @override
  ConsumerState<AdminProductListScreen> createState() =>
      _AdminProductListScreenState();
}

class _AdminProductListScreenState
    extends ConsumerState<AdminProductListScreen> {
  final _searchCtrl = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(
      adminProductsProvider(search: _search.isEmpty ? null : _search),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('المنتجات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.category_outlined),
            tooltip: 'الأقسام',
            onPressed: () => context.push(Routes.adminCategories),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // Refresh only once we're actually back on this screen — see the
          // comment on AdminProductFormScreen for why a cross-screen
          // invalidate() alone isn't reliable here.
          await context.push(Routes.adminProductNew);
          ref.invalidate(adminProductsProvider);
        },
        icon: const Icon(Icons.add),
        label: const Text('منتج جديد'),
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
            child: productsAsync.when(
              loading: () => const LoadingView(),
              error: (e, _) => ErrorView(
                message: 'تعذَّر تحميل المنتجات',
                onRetry: () => ref.invalidate(adminProductsProvider),
              ),
              data: (products) {
                if (products.isEmpty) {
                  return const EmptyView(
                    message: 'لا توجد منتجات بعد',
                    icon: Icons.inventory_2_outlined,
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.only(bottom: 88),
                  itemCount: products.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final p = products[i];
                    return ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          width: 44,
                          height: 44,
                          child: p.primaryImageUrl == null
                              ? ColoredBox(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
                                  child: const Icon(
                                    Icons.inventory_2_outlined,
                                    size: 20,
                                  ),
                                )
                              : CachedNetworkImage(
                                  imageUrl: p.primaryImageUrl!,
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ),
                      title: Text(p.name),
                      subtitle: Text(
                        'SKU: ${p.sku}${p.isActive ? '' : ' — معطَّل'}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(Formatters.currency(p.sellingPrice)),
                          // Services never appear in the storefront.
                          if (!p.isService)
                            IconButton(
                              tooltip: p.isFeatured
                                  ? 'إزالة من مختارات مكوجي'
                                  : 'إضافة لمختارات مكوجي',
                              icon: Icon(
                                p.isFeatured
                                    ? Icons.star_rounded
                                    : Icons.star_border_rounded,
                                color: p.isFeatured
                                    ? AppColors.brandGold
                                    : null,
                              ),
                              onPressed: () async {
                                try {
                                  await ref
                                      .read(productRepositoryProvider)
                                      .setProductFeatured(p.id, !p.isFeatured);
                                  ref.invalidate(adminProductsProvider);
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          AppException.from(e).messageAr,
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                        ],
                      ),
                      onTap: () async {
                        await context.push(Routes.adminProductEdit(p.id));
                        ref.invalidate(adminProductsProvider);
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
