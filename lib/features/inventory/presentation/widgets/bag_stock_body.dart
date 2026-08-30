import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/money_text.dart';
import '../../../../core/widgets/state_views.dart';
import '../providers/inventory_providers.dart';

/// Shared list body for "what's in this technician's bag right now" —
/// used by both the technician's own view and the admin's per-technician view.
class BagStockBody extends ConsumerWidget {
  final String technicianId;
  const BagStockBody({super.key, required this.technicianId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stockAsync = ref.watch(technicianBagStockProvider(technicianId));

    return stockAsync.when(
      loading: () => const LoadingView(),
      error: (e, _) => ErrorView(
        message: 'تعذَّر تحميل الشنطة',
        onRetry: () => ref.invalidate(technicianBagStockProvider(technicianId)),
      ),
      data: (items) {
        if (items.isEmpty) {
          return const EmptyView(message: 'الشنطة فارغة حاليًا', icon: Icons.work_outline);
        }
        final totalValue = items.fold<double>(0, (sum, i) => sum + i.value);
        return Column(
          children: [
            Expanded(
              child: ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final item = items[i];
                  return ListTile(
                    title: Text(item.productName),
                    subtitle: Text('SKU: ${item.sku} · الكمية: ${item.quantity}'),
                    trailing: MoneyText(item.sellingPrice),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('إجمالي قيمة الشنطة (تكلفة)'),
                  MoneyText(totalValue, style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
