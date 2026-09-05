import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/money_text.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../providers/cashbox_providers.dart';

class AdminExpensesListScreen extends ConsumerWidget {
  const AdminExpensesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('المصروفات')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push(Routes.adminExpenseNew);
          ref.invalidate(expensesProvider);
        },
        icon: const Icon(Icons.add),
        label: const Text('مصروف جديد'),
      ),
      body: expensesAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: 'تعذَّر تحميل المصروفات',
          onRetry: () => ref.invalidate(expensesProvider),
        ),
        data: (expenses) {
          if (expenses.isEmpty) {
            return const EmptyView(
              message: 'لا توجد مصروفات بعد',
              icon: Icons.receipt_long_outlined,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.only(bottom: 88),
            itemCount: expenses.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final e = expenses[i];
              return ListTile(
                leading: CircleAvatar(child: Text('#${e.expenseNumber}')),
                title: Text(e.categoryName),
                subtitle: Text(
                  Formatters.date(e.expenseDate) +
                      (e.notes != null ? ' · ${e.notes}' : ''),
                ),
                trailing: MoneyText(-e.amount, colorBySign: true),
              );
            },
          );
        },
      ),
    );
  }
}
