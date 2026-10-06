import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderOrFamily;

import '../../features/cashbox/presentation/providers/cashbox_providers.dart';
import '../../features/dashboard/presentation/providers/dashboard_providers.dart';
import '../../features/inventory/presentation/providers/inventory_providers.dart';
import '../../features/products/presentation/providers/product_providers.dart';
import '../../features/purchases/presentation/providers/purchases_providers.dart';
import '../../features/sales/presentation/providers/sales_providers.dart';
import '../offline/network_status.dart';
import '../offline/outbox.dart';

/// Wraps a staff shell (admin / sales) and keeps its one-shot fetches fresh.
///
/// The shells keep every tab alive (StatefulShellRoute.indexedStack), so a
/// screen opened earlier never refetches by itself — after a sale, the
/// cashbox tab and the invoice list kept showing the old data. Whenever a
/// write reaches the server ([Outbox.onServerChanged]) or the connection
/// comes back, everything below is refetched in one place instead of each
/// screen guessing what another screen shows. Realtime lists (orders,
/// maintenance, notifications) update by themselves.
class DataRefreshScope extends ConsumerStatefulWidget {
  final Widget child;
  const DataRefreshScope({super.key, required this.child});

  @override
  ConsumerState<DataRefreshScope> createState() => _DataRefreshScopeState();
}

class _DataRefreshScopeState extends ConsumerState<DataRefreshScope> {
  StreamSubscription<void>? _serverChanged;
  bool _wasOnline = NetworkStatus.instance.isOnline;

  @override
  void initState() {
    super.initState();
    _serverChanged = Outbox.instance.onServerChanged.listen((_) => _refresh());
    NetworkStatus.instance.addListener(_onNetwork);
  }

  void _onNetwork() {
    final online = NetworkStatus.instance.isOnline;
    if (online && !_wasOnline) _refresh();
    _wasOnline = online;
  }

  void _refresh() {
    if (!mounted) return;
    for (final provider in <ProviderOrFamily>[
      dashboardSummaryProvider,
      dashboardRevenueTrendProvider,
      walkInSalesProvider,
      invoiceLinesProvider,
      saleReturnItemsProvider,
      saleByIdProvider,
      warehouseStockProvider,
      assemblyStockProvider,
      adminProductsProvider,
      serviceProductsProvider,
      assemblyComponentsProvider,
      stockMovementsProvider,
      cashboxBalancesProvider,
      cashTransactionsProvider,
      expensesProvider,
      purchaseInvoicesProvider,
      purchaseInvoiceProvider,
      purchaseInvoicePaymentsProvider,
      suppliersProvider,
    ]) {
      ref.invalidate(provider);
    }
  }

  @override
  void dispose() {
    _serverChanged?.cancel();
    NetworkStatus.instance.removeListener(_onNetwork);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
