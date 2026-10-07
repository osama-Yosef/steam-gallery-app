import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'glass_bottom_nav.dart';

/// Floating glass pill bottom nav for the technician role — replaces the old
/// AppBar action icons (شنطتي / حسابي) with always-visible tabs, wrapping a
/// [StatefulShellRoute.indexedStack].
class TechnicianShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const TechnicianShell({required this.navigationShell, super.key});

  static const _items = <GlassNavItem>[
    (icon: Icons.build_rounded, label: 'الصيانة'),
    (icon: Icons.work_rounded, label: 'شنطتي'),
    (icon: Icons.account_balance_wallet_rounded, label: 'حسابي'),
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Back button/gesture from any non-"الصيانة" tab steps toward the
      // queue tab first instead of doing nothing (see AdminShell).
      canPop: navigationShell.currentIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) navigationShell.goBranch(0);
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        // NOT extendBody — see CustomerShell for why (FABs on per-branch
        // screens would end up hidden underneath this nav bar).
        body: navigationShell,
        bottomNavigationBar: GlassBottomNav(
          navigationShell: navigationShell,
          items: _items,
        ),
      ),
    );
  }
}
