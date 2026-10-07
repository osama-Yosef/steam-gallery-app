import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/app_network_image.dart';
import '../../../../inventory/data/models/warehouse_stock_item.dart';

/// The register's product grid: one card per sellable product, tap to ring
/// one up. The count already in the cart is badged on each card, so the
/// grid doubles as the "what have I rung up so far" view.
class RegisterProductGrid extends StatelessWidget {
  final List<WarehouseStockItem> items;
  final int Function(String productId) quantityInCart;
  final ValueChanged<WarehouseStockItem> onTap;

  const RegisterProductGrid({
    super.key,
    required this.items,
    required this.quantityInCart,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final columns = (c.maxWidth / 180).floor().clamp(2, 6);
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.78,
          ),
          itemCount: items.length,
          itemBuilder: (context, i) {
            final item = items[i];
            return _ProductCard(
              item: item,
              inCart: quantityInCart(item.productId),
              onTap: () => onTap(item),
            );
          },
        );
      },
    );
  }
}

class _ProductCard extends StatelessWidget {
  final WarehouseStockItem item;
  final int inCart;
  final VoidCallback onTap;
  const _ProductCard({
    required this.item,
    required this.inCart,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: item.imageUrl == null
                      ? ColoredBox(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: const Icon(Iconsax.box_copy, size: 32),
                        )
                      : AppNetworkImage(
                          imageUrl: item.imageUrl!,
                          fit: BoxFit.cover,
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.isAssembly
                            ? '${item.productName} (تجميع)'
                            : item.productName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      // A narrow card (two columns beside the admin rail)
                      // can't fit a four-digit price and the stock side by
                      // side — the price wins and the stock is shortened,
                      // instead of the row overflowing.
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              Formatters.currency(item.displayPrice),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'متاح ${item.quantity}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (inCart > 0)
              Positioned(
                top: 6,
                right: 6,
                child: CircleAvatar(
                  radius: 13,
                  backgroundColor: theme.colorScheme.primary,
                  child: Text(
                    '$inCart',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
