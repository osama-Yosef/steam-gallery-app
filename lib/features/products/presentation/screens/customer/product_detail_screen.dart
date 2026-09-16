import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../../../cart/presentation/providers/cart_provider.dart';
import '../../../data/models/product_image.dart';
import '../../../data/models/product_public.dart';
import '../../../presentation/providers/product_providers.dart';
import '../../widgets/product_card.dart';

/// Product page: photo gallery, price and availability, the live offers it
/// belongs to, description, specs, similar products, and a sticky quantity +
/// «أضف للسلة» bar. Reads products_public only — never a cost column.
class ProductDetailScreen extends ConsumerWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(customerProductDetailProvider(productId));

    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل المنتج')),
      body: productAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: 'تعذَّر تحميل بيانات المنتج',
          onRetry: () =>
              ref.invalidate(customerProductDetailProvider(productId)),
        ),
        data: (product) {
          if (product == null) {
            return const EmptyView(
              message: 'هذا المنتج لم يعد متاحًا في المتجر',
              icon: Icons.inventory_2_outlined,
            );
          }
          return Column(
            children: [
              Expanded(child: _Body(product: product)),
              _AddToCartBar(product: product),
            ],
          );
        },
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  final ProductPublic product;
  const _Body({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final images = ref.watch(productImagesProvider(product.id));
    final offers = ref.watch(productOffersProvider(product.id)).value ?? [];
    final categories = ref.watch(categoriesProvider(activeOnly: true)).value;
    String? categoryName;
    for (final c in categories ?? const []) {
      if (c.id == product.categoryId) categoryName = c.name;
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        AspectRatio(
          aspectRatio: 1.2,
          child: images.when(
            data: (list) =>
                _Gallery(images: list, fallbackUrl: product.primaryImageUrl),
            loading: () => _Gallery(
              images: const [],
              fallbackUrl: product.primaryImageUrl,
            ),
            error: (_, _) => _Gallery(
              images: const [],
              fallbackUrl: product.primaryImageUrl,
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (categoryName != null)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: ActionChip(
              avatar: const Icon(Icons.category_outlined, size: 18),
              label: Text(categoryName),
              onPressed: () =>
                  context.go(Routes.customerStoreCategory(product.categoryId!)),
            ),
          ),
        Text(product.name, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                Formatters.currency(product.sellingPrice),
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            _AvailabilityChip(available: product.isAvailable),
          ],
        ),
        const SizedBox(height: 4),
        Text('كود المنتج: ${product.sku}', style: theme.textTheme.bodySmall),
        for (final o in offers) ...[
          const SizedBox(height: 12),
          Card(
            margin: EdgeInsets.zero,
            color: AppColors.brandGold.withValues(alpha: 0.15),
            child: ListTile(
              leading: const Icon(Icons.local_offer_outlined),
              title: Text(o.title),
              subtitle: o.badgeText == null ? null : Text(o.badgeText!),
              trailing: const Icon(Icons.chevron_left),
              onTap: () => context.push(Routes.customerOffer(o.id)),
            ),
          ),
        ],
        if (product.description?.trim().isNotEmpty ?? false) ...[
          const SizedBox(height: 20),
          Text('الوصف', style: theme.textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(product.description!.trim()),
        ],
        if (product.specs.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text('المواصفات', style: theme.textTheme.titleMedium),
          const SizedBox(height: 6),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                for (final (i, e) in product.specs.entries.indexed) ...[
                  if (i > 0) const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            e.key,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(flex: 3, child: Text(e.value)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
        if (product.categoryId != null)
          _Related(productId: product.id, categoryId: product.categoryId!),
      ],
    );
  }
}

class _AvailabilityChip extends StatelessWidget {
  final bool available;
  const _AvailabilityChip({required this.available});

  @override
  Widget build(BuildContext context) {
    final color = available ? AppColors.success : AppColors.danger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        available ? 'متوفر' : 'غير متوفر حاليًا',
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _Gallery extends StatefulWidget {
  final List<ProductImage> images;
  final String? fallbackUrl;
  const _Gallery({required this.images, required this.fallbackUrl});

  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final urls = widget.images.isNotEmpty
        ? [
            for (final i
                in [...widget.images]..sort((a, b) {
                  if (a.isPrimary != b.isPrimary) return a.isPrimary ? -1 : 1;
                  return a.sortOrder.compareTo(b.sortOrder);
                }))
              i.imageUrl,
          ]
        : [?widget.fallbackUrl];

    final placeholder = Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Icon(Icons.local_fire_department_outlined, size: 64),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: urls.isEmpty
          ? placeholder
          : Stack(
              children: [
                PageView.builder(
                  key: const Key('product-gallery'),
                  itemCount: urls.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (_, i) => CachedNetworkImage(
                    imageUrl: urls[i],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    placeholder: (_, _) => placeholder,
                    errorWidget: (_, _, _) => placeholder,
                  ),
                ),
                if (urls.length > 1)
                  Positioned(
                    bottom: 10,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < urls.length; i++)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: i == _index ? 18 : 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(
                                alpha: i == _index ? 1 : 0.6,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

class _Related extends ConsumerWidget {
  final String productId;
  final String categoryId;
  const _Related({required this.productId, required this.categoryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final related = ref
        .watch(
          relatedProductsProvider(productId: productId, categoryId: categoryId),
        )
        .value;
    if (related == null || related.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text('منتجات مشابهة', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        SizedBox(
          height: 230,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: related.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (_, i) =>
                SizedBox(width: 160, child: ProductCard(product: related[i])),
          ),
        ),
      ],
    );
  }
}

class _AddToCartBar extends ConsumerStatefulWidget {
  final ProductPublic product;
  const _AddToCartBar({required this.product});

  @override
  ConsumerState<_AddToCartBar> createState() => _AddToCartBarState();
}

class _AddToCartBarState extends ConsumerState<_AddToCartBar> {
  int _quantity = 1;

  void _add() {
    final p = widget.product;
    final notifier = ref.read(cartProvider.notifier);
    final before = notifier.quantityOf(p.id);
    final after = notifier.add(
      productId: p.id,
      name: p.name,
      unitPrice: p.sellingPrice,
      quantity: _quantity,
    );
    final added = after - before;
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          added <= 0
              ? 'وصلت للحد الأقصى ($maxCartLineQuantity) من هذا المنتج في السلة'
              : added < _quantity
              ? 'تمت إضافة $added فقط — الحد الأقصى $maxCartLineQuantity للمنتج'
              : 'تمت إضافة $added × ${p.name} إلى السلة',
        ),
        action: SnackBarAction(
          label: 'عرض السلة',
          onPressed: () => context.go(Routes.customerCart),
        ),
      ),
    );
    setState(() => _quantity = 1);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final inCart = ref.watch(
      cartProvider.select(
        (items) => items
            .where((e) => e.productId == p.id)
            .fold<int>(0, (s, e) => s + e.quantity),
      ),
    );
    final room = maxCartLineQuantity - inCart;
    final maxPick = room < 1 ? 1 : room;
    if (_quantity > maxPick) _quantity = maxPick;

    return Material(
      elevation: 8,
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (inCart > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    'في السلة الآن: $inCart',
                    key: const Key('in-cart-count'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              Row(
                children: [
                  if (p.isAvailable) ...[
                    QuantityStepper(
                      value: _quantity,
                      max: maxPick,
                      onChanged: (v) => setState(() => _quantity = v),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: FilledButton.icon(
                      key: const Key('add-to-cart'),
                      onPressed: !p.isAvailable || room < 1 ? null : _add,
                      icon: const Icon(Icons.add_shopping_cart_outlined),
                      label: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          !p.isAvailable
                              ? 'غير متوفر حاليًا'
                              : room < 1
                              ? 'الحد الأقصى في السلة'
                              : 'أضف للسلة • ${Formatters.currency(p.sellingPrice * _quantity)}',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// − value + control, bounded to [min]..[max].
class QuantityStepper extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  const QuantityStepper({
    super.key,
    required this.value,
    this.min = 1,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            key: const Key('qty-minus'),
            tooltip: 'إنقاص',
            icon: const Icon(Icons.remove),
            onPressed: value > min ? () => onChanged(value - 1) : null,
          ),
          SizedBox(
            width: 28,
            child: Text(
              '$value',
              key: const Key('qty-value'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          IconButton(
            key: const Key('qty-plus'),
            tooltip: 'زيادة',
            icon: const Icon(Icons.add),
            onPressed: value < max ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );
  }
}
