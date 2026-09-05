import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/formatters.dart';
import '../../../technician_account/presentation/providers/technician_account_providers.dart';

/// What the job cost, itemised: the service fee plus any parts fitted. Shown
/// on the request itself so the customer can see what was done and what it
/// totalled without having to ask.
///
/// Renders nothing until the technician has actually raised the invoice.
class MaintenanceInvoiceCard extends ConsumerWidget {
  final String maintenanceRequestId;

  const MaintenanceInvoiceCard({required this.maintenanceRequestId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoiceAsync = ref.watch(
      maintenanceInvoiceProvider(maintenanceRequestId),
    );

    return invoiceAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (sale) {
        if (sale == null) return const SizedBox.shrink();

        final itemsAsync = ref.watch(saleItemsProvider(sale.id));

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'فاتورة الصيانة',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text('#${sale.saleNumber}'),
                  ],
                ),
                const Divider(),
                itemsAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (_, _) => const Text('تعذَّر تحميل بنود الفاتورة'),
                  data: (items) => Column(
                    children: [
                      for (final item in items)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.quantity > 1
                                      ? '${item.productNameSnapshot} × ${item.quantity}'
                                      : item.productNameSnapshot,
                                ),
                              ),
                              Text(Formatters.currency(item.lineTotal)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                if (sale.discount > 0) ...[
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('الخصم'),
                      Text('- ${Formatters.currency(sale.discount)}'),
                    ],
                  ),
                ],
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'الإجمالي',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      Formatters.currency(sale.total),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
