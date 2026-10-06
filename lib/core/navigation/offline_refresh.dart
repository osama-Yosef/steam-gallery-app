import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/cashbox/presentation/providers/cashbox_providers.dart';
import '../../features/dashboard/presentation/providers/dashboard_providers.dart';
import '../../features/inventory/presentation/providers/inventory_providers.dart';
import '../../features/purchases/presentation/providers/purchases_providers.dart';
import '../offline/network_status.dart';
import '../offline/outbox.dart';

/// Wraps a staff shell: when the connection comes back, or queued offline
/// writes finish sending, the screens built on one-shot fetches (dashboard,
/// stock, cashbox, purchases) refetch, so nobody keeps looking at the cached
/// numbers from before. Realtime lists (orders, invoices) refetch by
/// themselves when their channel reconnects.
class OfflineRefresh extends ConsumerStatefulWidget {
  final Widget child;
  const OfflineRefresh({super.key, required this.child});

  @override
  ConsumerState<OfflineRefresh> createState() => _OfflineRefreshState();
}

class _OfflineRefreshState extends ConsumerState<OfflineRefresh> {
  StreamSubscription<void>? _synced;
  bool _wasOnline = NetworkStatus.instance.isOnline;

  @override
  void initState() {
    super.initState();
    _synced = Outbox.instance.onSynced.listen((_) => _refresh());
    NetworkStatus.instance.addListener(_onNetwork);
  }

  void _onNetwork() {
    final online = NetworkStatus.instance.isOnline;
    if (online && !_wasOnline) _refresh();
    _wasOnline = online;
  }

  void _refresh() {
    if (!mounted) return;
    ref.invalidate(dashboardSummaryProvider);
    ref.invalidate(dashboardRevenueTrendProvider);
    ref.invalidate(warehouseStockProvider);
    ref.invalidate(assemblyStockProvider);
    ref.invalidate(cashboxBalancesProvider);
    ref.invalidate(cashTransactionsProvider);
    ref.invalidate(expensesProvider);
    ref.invalidate(purchaseInvoicesProvider);
    ref.invalidate(suppliersProvider);
  }

  @override
  void dispose() {
    _synced?.cancel();
    NetworkStatus.instance.removeListener(_onNetwork);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
