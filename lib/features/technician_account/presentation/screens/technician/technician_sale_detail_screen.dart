import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/money_text.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../../data/models/sale.dart';
import '../../providers/technician_account_providers.dart';

class TechnicianSaleDetailScreen extends ConsumerWidget {
  final String saleId;
  const TechnicianSaleDetailScreen({super.key, required this.saleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saleAsync = ref.watch(technicianSaleDetailProvider(saleId));
    final itemsAsync = ref.watch(saleItemsProvider(saleId));

    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل البيع')),
      body: saleAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => const ErrorView(message: 'تعذَّر تحميل البيع'),
        data: (sale) {
          if (sale == null) return const EmptyView(message: 'البيع غير موجود');
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'بيع #${sale.saleNumber}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Chip(label: Text(saleStatusLabelAr(sale.status))),
                ],
              ),
              const SizedBox(height: 4),
              Text(Formatters.dateTime(sale.createdAt)),
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text(sale.customerName ?? 'عميل نقدي'),
                  subtitle: sale.customerPhone != null
                      ? Text(sale.customerPhone!)
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              Text('الأصناف', style: Theme.of(context).textTheme.titleMedium),
              itemsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => const Text('تعذَّر تحميل الأصناف'),
                data: (items) => Column(
                  children: [
                    for (final item in items)
                      ListTile(
                        title: Text(item.productNameSnapshot),
                        subtitle: Text(
                          '${item.quantity} × ${Formatters.currency(item.unitPriceSnapshot)}',
                        ),
                        trailing: MoneyText(item.lineTotal),
                      ),
                  ],
                ),
              ),
              const Divider(height: 32),
              _summaryRow(context, 'الإجمالي الفرعي', sale.subtotal),
              _summaryRow(context, 'الخصم', sale.discount),
              _summaryRow(context, 'الإجمالي', sale.total, emphasize: true),
              _summaryRow(context, 'المبلغ المحصَّل', sale.paidAmount),
              const SizedBox(height: 8),
              Text('طريقة الدفع: ${paymentMethodLabelAr(sale.paymentMethod)}'),
            ],
          );
        },
      ),
    );
  }

  Widget _summaryRow(
    BuildContext context,
    String label,
    double amount, {
    bool emphasize = false,
  }) {
    final style = emphasize ? Theme.of(context).textTheme.titleMedium : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          MoneyText(amount, style: style),
        ],
      ),
    );
  }
}
