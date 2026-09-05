import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/money_text.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../../data/models/stock_movement.dart';
import '../../providers/inventory_providers.dart';

class AdminStockMovementsScreen extends ConsumerWidget {
  const AdminStockMovementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movementsAsync = ref.watch(stockMovementsProvider());

    return Scaffold(
      appBar: AppBar(title: const Text('حركات المخزون')),
      body: movementsAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: 'تعذَّر تحميل الحركات',
          onRetry: () => ref.invalidate(stockMovementsProvider),
        ),
        data: (movements) {
          if (movements.isEmpty) {
            return const EmptyView(
              message: 'لا توجد حركات مخزون بعد',
              icon: Icons.swap_horiz_outlined,
            );
          }
          return ListView.separated(
            itemCount: movements.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final m = movements[i];
              return ListTile(
                leading: CircleAvatar(child: Text('#${m.movementNumber}')),
                title: Text(
                  '${m.productName} · ${stockMovementTypeLabelAr(m.movementType)}',
                ),
                subtitle: Text(
                  '${locationTypeLabelAr(m.fromLocationType)} ← ${locationTypeLabelAr(m.toLocationType)}\n'
                  '${Formatters.dateTime(m.createdAt)}${m.notes != null ? ' · ${m.notes}' : ''}',
                ),
                isThreeLine: true,
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('الكمية: ${m.quantity}'),
                    MoneyText(m.totalCost),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
