import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/utils/history_query.dart';
import '../../../../../core/widgets/history_results_list.dart';
import '../../../../../core/widgets/history_search_bar.dart';
import '../../../../auth/data/models/app_user.dart';
import '../../../../auth/presentation/providers/auth_providers.dart';
import '../../providers/order_providers.dart';
import '../../widgets/admin_order/admin_order_tile.dart';

/// "سجل الطلبات": every order, by number, recipient name/phone and the
/// days it was placed. The orders tab itself only keeps what is still open
/// plus today's, so finished orders are looked up here.
class AdminOrdersHistoryScreen extends ConsumerStatefulWidget {
  const AdminOrdersHistoryScreen({super.key});

  @override
  ConsumerState<AdminOrdersHistoryScreen> createState() =>
      _AdminOrdersHistoryScreenState();
}

class _AdminOrdersHistoryScreenState
    extends ConsumerState<AdminOrdersHistoryScreen> {
  var _query = const HistoryQuery();

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(orderHistoryProvider(_query));
    final isSales =
        ref.watch(currentUserProfileProvider).value?.role == AppRole.sales;

    return Scaffold(
      appBar: AppBar(title: const Text('سجل الطلبات')),
      body: Column(
        children: [
          HistorySearchBar(
            query: _query,
            hint: 'رقم الطلب أو اسم/تليفون المستلم',
            onChanged: (q) => setState(() => _query = q),
          ),
          Expanded(
            child: HistoryResultsList(
              results: results,
              emptyMessage: 'لا توجد طلبات مطابقة',
              onRetry: () => ref.invalidate(orderHistoryProvider(_query)),
              onLoadMore: () =>
                  ref.read(orderHistoryProvider(_query).notifier).loadMore(),
              itemBuilder: (context, order) => AdminOrderTile(
                order: order,
                detailRoute: isSales
                    ? Routes.salesOrderDetail(order.id)
                    : Routes.adminOrderDetail(order.id),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
