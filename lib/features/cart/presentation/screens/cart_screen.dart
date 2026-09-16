import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../products/presentation/screens/customer/product_detail_screen.dart'
    show QuantityStepper;
import '../../data/models/cart.dart';
import '../providers/cart_provider.dart';

/// «السلة»: lines priced by the server, with price-change and availability
/// warnings. Checkout stays disabled while any line can't be bought.
class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  /// Product ids with a request in flight (their controls are disabled).
  final _busy = <String>{};

  Future<void> _run(String key, Future<void> Function() op) async {
    setState(() => _busy.add(key));
    try {
      await op();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppException.from(e).messageAr)));
      }
    } finally {
      if (mounted) setState(() => _busy.remove(key));
    }
  }

  Future<void> _confirmClear() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تفريغ السلة؟'),
        content: const Text('هيتم حذف كل المنتجات من السلة.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('تفريغ'),
          ),
        ],
      ),
    );
    if (yes == true) {
      await _run('*', () => ref.read(cartProvider.notifier).clear());
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartAsync = ref.watch(cartProvider);
    final cart = cartAsync.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('السلة'),
        actions: [
          if (cart != null && !cart.isEmpty)
            IconButton(
              tooltip: 'تفريغ السلة',
              onPressed: _busy.isEmpty ? _confirmClear : null,
              icon: const Icon(Icons.delete_sweep_outlined),
            ),
        ],
      ),
      body: cartAsync.when(
        skipLoadingOnRefresh: true,
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: 'تعذَّر تحميل السلة',
          onRetry: () => ref.invalidate(cartProvider),
        ),
        data: (cart) {
          if (cart.isEmpty) {
            return EmptyView(
              message: 'السلة فارغة',
              icon: Icons.shopping_cart_outlined,
              action: FilledButton.icon(
                onPressed: () => context.go(Routes.customerStore),
                icon: const Icon(Icons.storefront_outlined),
                label: const Text('تصفح المتجر'),
              ),
            );
          }
          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => ref.refresh(cartProvider.future),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (cart.hasPriceChanges)
                        _Notice(
                          key: const Key('cart-price-notice'),
                          icon: Icons.info_outline,
                          color: AppColors.warning,
                          text:
                              'أسعار بعض المنتجات اتغيرت من وقت ما ضفتها. الإجمالي محسوب بالأسعار الحالية.',
                          action: TextButton(
                            onPressed: _busy.isEmpty
                                ? () => _run(
                                    '*',
                                    () => ref
                                        .read(cartProvider.notifier)
                                        .acknowledgePrices(),
                                  )
                                : null,
                            child: const Text('تمام'),
                          ),
                        ),
                      if (cart.items.any((l) => l.blocksCheckout))
                        const _Notice(
                          key: Key('cart-blocked-notice'),
                          icon: Icons.error_outline,
                          color: AppColors.danger,
                          text:
                              'في منتجات مش متاحة بالكمية دي. عدّل الكمية أو احذفها عشان تكمل.',
                        ),
                      for (final line in cart.items)
                        _LineTile(
                          line: line,
                          busy: _busy.contains(line.productId) ||
                              _busy.contains('*'),
                          onQuantity: (q) => _run(
                            line.productId,
                            () => ref
                                .read(cartProvider.notifier)
                                .setQuantity(line.productId, q),
                          ),
                          onRemove: () => _run(
                            line.productId,
                            () => ref
                                .read(cartProvider.notifier)
                                .remove(line.productId),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              _Totals(cart: cart, enabled: _busy.isEmpty),
            ],
          );
        },
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  final Widget? action;
  const _Notice({
    super.key,
    required this.icon,
    required this.color,
    required this.text,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
          ?action,
        ],
      ),
    );
  }
}

class _LineTile extends StatelessWidget {
  final CartLine line;
  final bool busy;
  final ValueChanged<int> onQuantity;
  final VoidCallback onRemove;
  const _LineTile({
    required this.line,
    required this.busy,
    required this.onQuantity,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () =>
                  context.push(Routes.customerProductDetail(line.productId)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: line.imageUrl == null
                      ? ColoredBox(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: const Icon(
                            Icons.local_fire_department_outlined,
                          ),
                        )
                      : CachedNetworkImage(
                          imageUrl: line.imageUrl!,
                          fit: BoxFit.cover,
                        ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    line.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(Formatters.currency(line.unitPrice)),
                      if (line.priceChanged)
                        Text(
                          Formatters.currency(line.priceSeen),
                          style: theme.textTheme.bodySmall?.copyWith(
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                    ],
                  ),
                  if (!line.isActive)
                    const _Tag('لم يعد متاحًا في المتجر', AppColors.danger)
                  else if (!line.isAvailable)
                    const _Tag('الكمية غير متوفرة', AppColors.danger),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (line.isActive)
                        QuantityStepper(
                          value: line.quantity,
                          max: maxCartLineQuantity,
                          onChanged: busy ? (_) {} : onQuantity,
                        ),
                      const Spacer(),
                      if (busy)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        IconButton(
                          tooltip: 'حذف',
                          onPressed: onRemove,
                          icon: const Icon(Icons.delete_outline),
                        ),
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

class _Tag extends StatelessWidget {
  final String text;
  final Color color;
  const _Tag(this.text, this.color);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Text(
      text,
      style: TextStyle(color: color, fontWeight: FontWeight.w600),
    ),
  );
}

class _Totals extends StatelessWidget {
  final CartSummary cart;
  final bool enabled;
  const _Totals({required this.cart, required this.enabled});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'المجموع (${cart.itemCount} قطعة)',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // A large subtotal or titleLarge's bigger font can outgrow
                  // narrow screens — shrink rather than overflow (same fix as
                  // ProductCard's price).
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerEnd,
                      child: Text(
                        Formatters.currency(cart.subtotal),
                        key: const Key('cart-subtotal'),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'رسوم التوصيل بتتحسب في الخطوة الجاية حسب عنوانك.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 10),
              FilledButton(
                key: const Key('cart-checkout'),
                onPressed: enabled && cart.canCheckout
                    ? () => context.push(Routes.customerCheckout)
                    : null,
                child: const Text('متابعة الطلب'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
