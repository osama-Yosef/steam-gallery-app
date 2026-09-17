import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../../../products/presentation/widgets/product_card.dart';
import '../../providers/storefront_providers.dart';

/// One offer and its products. Prices shown are the products' normal prices —
/// an offer never changes them.
class OfferDetailScreen extends ConsumerWidget {
  final String offerId;
  const OfferDetailScreen({super.key, required this.offerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offerAsync = ref.watch(offerDetailProvider(offerId));
    final productsAsync = ref.watch(offerProductsProvider(offerId));

    return Scaffold(
      appBar: AppBar(title: Text(offerAsync.value?.title ?? 'العرض')),
      body: offerAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: 'تعذَّر تحميل العرض',
          onRetry: () => ref.invalidate(offerDetailProvider(offerId)),
        ),
        // Null = ended, switched off, or never existed: RLS only returns
        // live offers to customers.
        data: (offer) => offer == null
            ? const EmptyView(
                message: 'هذا العرض انتهى أو غير متاح',
                icon: Icons.local_offer_outlined,
              )
            : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (offer.imageUrl != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: AspectRatio(
                                aspectRatio: 2.2,
                                child: CachedNetworkImage(
                                  imageUrl: offer.imageUrl!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          const SizedBox(height: 12),
                          if (offer.badgeText != null)
                            Chip(
                              backgroundColor: AppColors.brandGold,
                              label: Text(
                                offer.badgeText!,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          Text(
                            offer.title,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          if (offer.subtitle != null)
                            Text(
                              offer.subtitle!,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          if (offer.description != null) ...[
                            const SizedBox(height: 8),
                            Text(offer.description!),
                          ],
                          if (offer.endsAt != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'ينتهي ${Formatters.date(offer.endsAt!)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  ...productsAsync.when(
                    loading: () => [
                      const SliverToBoxAdapter(child: LoadingView()),
                    ],
                    error: (e, _) => [
                      SliverToBoxAdapter(
                        child: ErrorView(
                          message: 'تعذَّر تحميل منتجات العرض',
                          onRetry: () =>
                              ref.invalidate(offerProductsProvider(offerId)),
                        ),
                      ),
                    ],
                    data: (products) => products.isEmpty
                        ? [
                            const SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.all(24),
                                child: Text(
                                  'لا توجد منتجات في هذا العرض حاليًا',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ]
                        : [
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                              sliver: SliverGrid.builder(
                                gridDelegate:
                                    const SliverGridDelegateWithMaxCrossAxisExtent(
                                      maxCrossAxisExtent: 220,
                                      mainAxisSpacing: 12,
                                      crossAxisSpacing: 12,
                                      childAspectRatio: 0.72,
                                    ),
                                itemCount: products.length,
                                itemBuilder: (context, i) =>
                                    ProductCard(product: products[i]),
                              ),
                            ),
                          ],
                  ),
                ],
              ),
      ),
    );
  }
}
