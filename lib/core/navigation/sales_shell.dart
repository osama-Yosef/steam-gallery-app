import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../offline/offline_widgets.dart';
import '../router/route_names.dart';
import 'data_refresh_scope.dart';
import 'glass_bottom_nav.dart';

/// Floating glass pill bottom nav for the sales role (0046) — same shape as
/// [CustomerShell], replacing the old collapsible sidebar. Sales only gets
/// three tabs: البيع المباشر is the landing tab (sales must always default
/// to selling, not a dashboard), الطلبات, and الأقسام (marketing, InstaPay
/// review, cashbox withdrawal — everything that doesn't need its own tab).
class SalesShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const SalesShell({required this.navigationShell, super.key});

  static const _items = <GlassNavItem>[
    (icon: Icons.point_of_sale_rounded, label: 'بيع مباشر'),
    (icon: Icons.receipt_long_rounded, label: 'الطلبات'),
    (icon: Icons.apps_rounded, label: 'الأقسام'),
  ];

  @override
  Widget build(BuildContext context) {
    return DataRefreshScope(
      child: PopScope(
        canPop: navigationShell.currentIndex == 0,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) navigationShell.goBranch(0);
        },
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: navigationShell,
          // The offline/sync strip sits just above the tab pill — at the top
          // it would fight each screen's own AppBar for the status-bar inset.
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const OfflineStatusBar(syncRoute: Routes.salesSync),
              GlassBottomNav(navigationShell: navigationShell, items: _items),
            ],
          ),
        ),
      ),
    );
  }
}
