import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../../core/errors/app_exception.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../../data/models/product.dart';
import '../../../presentation/providers/product_providers.dart';

/// Admin-only (0046) — sales no longer sees products or the warehouse at
/// all, so this screen dropped the isSales branching it used to need.
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
            icon: const Icon(Iconsax.category_copy),
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
        icon: const Icon(Iconsax.add_copy),
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
                    icon: Iconsax.box_copy,
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(0, 8, 0, 88),
                  itemCount: products.length,
                  itemBuilder: (context, i) {
                    final p = products[i];
                    return _ProductTile(
                      product: p,
                      onTap: () async {
                        await context.push(Routes.adminProductEdit(p.id));
                        ref.invalidate(adminProductsProvider);
                      },
                      onToggleFeatured: () async {
                        try {
                          await ref
                              .read(productRepositoryProvider)
                              .setProductFeatured(p.id, !p.isFeatured);
                          ref.invalidate(adminProductsProvider);
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(AppException.from(e).messageAr),
                              ),
                            );
                          }
                        }
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

/// A full-width, colour-coded card — same visual language as the admin
/// orders/maintenance tiles: a tinted "bar" per product whose colour marks
/// its state (disabled/featured/service/active) at a glance, instead of the
/// bare text-only row this used to be.
class _ProductTile extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback onToggleFeatured;

  const _ProductTile({
    required this.product,
    required this.onTap,
    required this.onToggleFeatured,
  });

  @override
  Widget build(BuildContext context) {
    final p = product;
    final Color color;
    final String statusLabel;
    if (!p.isActive) {
      color = AppColors.textSecondary;
      statusLabel = 'معطَّل';
    } else if (p.isFeatured) {
      color = AppColors.brandGold;
      statusLabel = 'مميز';
    } else if (p.isService) {
      color = AppColors.info;
      statusLabel = 'خدمة';
    } else {
      color = AppColors.primary;
      statusLabel = 'نشط';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: color.withValues(alpha: 0.08),
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      width: 52,
                      height: 52,
                      child: p.primaryImageUrl == null
                          ? Container(
                              color: color.withValues(alpha: 0.18),
                              child: Icon(
                                p.isService
                                    ? Iconsax.setting_2_copy
                                    : Iconsax.box_copy,
                                color: color,
                              ),
                            )
                          : CachedNetworkImage(
                              imageUrl: p.primaryImageUrl!,
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'SKU: ${p.sku}',
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        Formatters.currency(p.sellingPrice),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Services never appear in the storefront, so there's
                  // nothing to feature.
                  if (!p.isService)
                    IconButton(
                      tooltip: p.isFeatured
                          ? 'إزالة من مختارات مكوجي'
                          : 'إضافة لمختارات مكوجي',
                      icon: Icon(
                        p.isFeatured
                            ? Iconsax.star_1
                            : Iconsax.star_1_copy,
                        color: p.isFeatured ? AppColors.brandGold : null,
                      ),
                      onPressed: onToggleFeatured,
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
