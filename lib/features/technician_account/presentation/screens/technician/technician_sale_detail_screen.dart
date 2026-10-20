import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/money_text.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../../../auth/data/models/app_user.dart';
import '../../../../auth/presentation/providers/auth_providers.dart';
import '../../../data/models/sale.dart';
import '../../providers/technician_account_providers.dart';
import 'technician_sale_edit_screen.dart';

/// How long a technician can change his own invoice; the server enforces
/// the same limit (0088).
const technicianEditWindow = Duration(days: 3);

bool technicianCanStillEdit(Sale sale, {DateTime? now}) =>
    (now ?? DateTime.now()).difference(sale.createdAt) < technicianEditWindow;

class TechnicianSaleDetailScreen extends ConsumerWidget {
  final String saleId;
  const TechnicianSaleDetailScreen({super.key, required this.saleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saleAsync = ref.watch(technicianSaleDetailProvider(saleId));
    final itemsAsync = ref.watch(saleItemsProvider(saleId));
    final me = ref.watch(currentUserProfileProvider).value;
    final sale = saleAsync.value;
    // Admin can change it any time; the technician who made it, for 3 days
    // (0087/0088).
    final canEdit =
        sale != null &&
        sale.status == SaleStatus.completed &&
        sale.technicianId != null &&
        (me?.role == AppRole.admin ||
            (me?.role == AppRole.technician &&
                me?.id == sale.technicianId &&
                technicianCanStillEdit(sale)));

    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل البيع'),
        actions: [
          if (canEdit)
            IconButton(
              tooltip: 'تعديل / حذف الفاتورة',
              icon: const Icon(Iconsax.edit_2_copy),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => TechnicianSaleEditScreen(saleId: saleId),
                ),
              ),
            ),
        ],
      ),
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
                  leading: const Icon(Iconsax.profile_circle_copy),
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
                // What is on the invoice now: an edit takes lines back.
                data: (items) => Column(
                  children: [
                    for (final item in items.where(
                      (i) => i.remainingQuantity > 0,
                    ))
                      ListTile(
                        title: Text(item.productNameSnapshot),
                        subtitle: Text(
                          '${item.remainingQuantity} × ${Formatters.currency(item.unitPriceSnapshot)}',
                        ),
                        trailing: MoneyText(item.remainingTotal),
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
              if (!canEdit &&
                  me?.role == AppRole.technician &&
                  sale.status == SaleStatus.completed &&
                  !technicianCanStillEdit(sale)) ...[
                const SizedBox(height: 16),
                Text(
                  'عدّى أكتر من 3 أيام على الفاتورة — لو محتاجة تعديل كلّم الأدمن',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              if (canEdit) ...[
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => TechnicianSaleEditScreen(saleId: saleId),
                    ),
                  ),
                  icon: const Icon(Iconsax.edit_2_copy),
                  label: const Text('تعديل أو حذف الفاتورة'),
                ),
              ],
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
