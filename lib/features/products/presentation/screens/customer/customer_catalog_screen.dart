import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/confirm_dialog.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../../../auth/presentation/providers/auth_providers.dart';
import '../../../../cart/presentation/providers/cart_provider.dart';
import '../../../data/models/product_public.dart';
import '../../../presentation/providers/product_providers.dart';

class CustomerCatalogScreen extends ConsumerStatefulWidget {
  const CustomerCatalogScreen({super.key});

  @override
  ConsumerState<CustomerCatalogScreen> createState() => _CustomerCatalogScreenState();
}

class _CustomerCatalogScreenState extends ConsumerState<CustomerCatalogScreen> {
  final _searchCtrl = TextEditingController();
  String _search = '';
  String? _categoryId;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider(activeOnly: true));
    final productsAsync = ref.watch(
      customerProductsProvider(search: _search.isEmpty ? null : _search, categoryId: _categoryId),
    );

    final cartCount = ref.watch(cartItemCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('معرض أجهزة البخار'),
        actions: [
          IconButton(
            icon: const Icon(Icons.build_outlined),
            tooltip: 'الصيانة',
            onPressed: () => context.push(Routes.customerMaintenance),
          ),
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined),
            tooltip: 'طلباتي',
            onPressed: () => context.push(Routes.customerOrders),
          ),
          IconButton(
            icon: Badge(
              label: Text('$cartCount'),
              isLabelVisible: cartCount > 0,
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            tooltip: 'السلة',
            onPressed: () => context.push(Routes.customerCart),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'تسجيل الخروج',
            onPressed: () async {
              final confirmed = await showConfirmDialog(
                context,
                title: 'تسجيل الخروج',
                message: 'هل تريد تسجيل الخروج من حسابك؟',
              );
              if (confirmed) await ref.read(authRepositoryProvider).signOut();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'ابحث عن منتج...',
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
              onSubmitted: (v) => setState(() => _search = v),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          categoriesAsync.when(
            data: (categories) => SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _CategoryChip(
                    label: 'الكل',
                    selected: _categoryId == null,
                    onTap: () => setState(() => _categoryId = null),
                  ),
                  const SizedBox(width: 8),
                  for (final c in categories) ...[
                    _CategoryChip(
                      label: c.name,
                      selected: _categoryId == c.id,
                      onTap: () => setState(() => _categoryId = c.id),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            loading: () => const SizedBox(height: 44),
            error: (_, _) => const SizedBox(height: 44),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: productsAsync.when(
              loading: () => const LoadingView(),
              error: (e, _) => ErrorView(
                message: 'تعذَّر تحميل المنتجات',
                onRetry: () => ref.invalidate(customerProductsProvider),
              ),
              data: (products) {
                if (products.isEmpty) {
                  return const EmptyView(message: 'لا توجد منتجات مطابقة', icon: Icons.inventory_2_outlined);
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, i) => _ProductCard(product: products[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _CategoryChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(label: Text(label), selected: selected, onSelected: (_) => onTap());
  }
}

class _ProductCard extends StatelessWidget {
  final ProductPublic product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(Routes.customerProductDetail(product.id)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Icon(Icons.local_fire_department_outlined, size: 40),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(Formatters.currency(product.sellingPrice),
                          style: Theme.of(context).textTheme.titleSmall),
                      if (!product.isAvailable)
                        Text('غير متاح',
                            style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
