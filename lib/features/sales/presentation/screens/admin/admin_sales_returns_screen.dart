import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../../../auth/data/models/app_user.dart';
import '../../../../auth/presentation/providers/auth_providers.dart';
import '../../../../technician_account/data/models/sale.dart';
import '../../providers/sales_providers.dart';

Color _saleStatusColor(SaleStatus status) => switch (status) {
  SaleStatus.completed => AppColors.success,
  SaleStatus.returned || SaleStatus.cancelled => AppColors.danger,
};

/// Walk-in sales only — 0057. Shared by admin and sales, reached from
/// "مرتجع المبيعات" in either role's sections screen. Tapping any sale opens
/// its invoice (0058) — a completed one can be returned there, line by line
/// or all at once; any other status is just viewable.
class AdminSalesReturnsScreen extends ConsumerWidget {
  const AdminSalesReturnsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesAsync = ref.watch(walkInSalesProvider);
    final isSales =
        ref.watch(currentUserProfileProvider).value?.role == AppRole.sales;
    String detailRoute(String id) => isSales
        ? Routes.salesSaleReturnDetail(id)
        : Routes.adminSaleReturnDetail(id);

    return Scaffold(
      appBar: AppBar(title: const Text('مرتجع المبيعات')),
      body: salesAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => const ErrorView(message: 'تعذَّر تحميل المبيعات'),
        data: (sales) {
          if (sales.isEmpty) {
            return const EmptyView(
              message: 'لا توجد مبيعات مباشرة بعد',
              icon: Iconsax.receipt_2_copy,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: sales.length,
            itemBuilder: (context, i) => _SaleTile(
              sale: sales[i],
              onTap: () => context.push(detailRoute(sales[i].id)),
            ),
          );
        },
      ),
    );
  }
}

class _SaleTile extends StatelessWidget {
  final Sale sale;
  final VoidCallback? onTap;
  const _SaleTile({required this.sale, this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = _saleStatusColor(sale.status);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: color.withValues(alpha: 0.08),
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
                    child: const Icon(
                      Iconsax.receipt_2_copy,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'بيع #${sale.saleNumber}',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (sale.customerName != null ||
                            sale.customerPhone != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            [
                              if (sale.customerName != null) sale.customerName!,
                              if (sale.customerPhone != null) sale.customerPhone!,
                            ].join(' — '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                        const SizedBox(height: 2),
                        Text(
                          Formatters.date(sale.createdAt),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        Formatters.currency(sale.total),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          saleStatusLabelAr(sale.status),
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
