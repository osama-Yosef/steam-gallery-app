import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../../../cart/presentation/providers/cart_provider.dart';
import '../../../presentation/providers/product_providers.dart';

class ProductDetailScreen extends ConsumerWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(customerProductDetailProvider(productId));
    final imagesAsync = ref.watch(productImagesProvider(productId));

    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل المنتج')),
      body: productAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: 'تعذَّر تحميل بيانات المنتج',
          onRetry: () => ref.invalidate(customerProductDetailProvider(productId)),
        ),
        data: (product) {
          if (product == null) {
            return const EmptyView(message: 'هذا المنتج غير متاح', icon: Icons.inventory_2_outlined);
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AspectRatio(
                aspectRatio: 1.3,
                child: imagesAsync.when(
                  data: (images) => images.isEmpty
                      ? _placeholder(context)
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: CachedNetworkImage(
                            imageUrl: images.first.imageUrl,
                            fit: BoxFit.cover,
                            errorWidget: (_, _, _) => _placeholder(context),
                          ),
                        ),
                  loading: () => _placeholder(context),
                  error: (_, _) => _placeholder(context),
                ),
              ),
              const SizedBox(height: 16),
              Text(product.name, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(Formatters.currency(product.sellingPrice),
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(width: 12),
                  Chip(
                    label: Text(product.isAvailable ? 'متاح' : 'غير متاح'),
                    backgroundColor: product.isAvailable
                        ? Colors.green.withValues(alpha: 0.15)
                        : Theme.of(context).colorScheme.error.withValues(alpha: 0.15),
                  ),
                ],
              ),
              if (product.description != null && product.description!.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('الوصف', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(product.description!),
              ],
              if (product.specs.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('المواصفات', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: product.specs.entries
                          .map((e) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(e.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Text(e.value),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: !product.isAvailable
                    ? null
                    : () {
                        ref.read(cartProvider.notifier).add(
                              productId: product.id,
                              name: product.name,
                              unitPrice: product.sellingPrice,
                            );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('تمت إضافة ${product.name} إلى السلة')),
                        );
                      },
                icon: const Icon(Icons.add_shopping_cart_outlined),
                label: Text(product.isAvailable ? 'أضف للسلة' : 'غير متاح حاليًا'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _placeholder(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.local_fire_department_outlined, size: 64),
      );
}
