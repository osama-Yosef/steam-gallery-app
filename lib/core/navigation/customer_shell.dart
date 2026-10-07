import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/cart/presentation/providers/cart_provider.dart';
import 'glass_bottom_nav.dart';

/// Floating glass pill bottom nav for the customer role — replaces the old
/// AppBar action icons (maintenance / orders / cart / logout) on the
/// catalog screen with always-visible tabs, wrapping a
/// [StatefulShellRoute.indexedStack].
class CustomerShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;
  const CustomerShell({required this.navigationShell, super.key});

  static const _items = <GlassNavItem>[
    (icon: Icons.home_rounded, label: 'الرئيسية'),
    (icon: Icons.storefront_rounded, label: 'المتجر'),
    (icon: Icons.build_rounded, label: 'الصيانة'),
    (icon: Icons.shopping_cart_rounded, label: 'السلة'),
    (icon: Icons.receipt_long_rounded, label: 'طلباتي'),
    (icon: Icons.person_rounded, label: 'حسابي'),
  ];

  static const _cartTab = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartCount = ref.watch(cartItemCountProvider);

    return PopScope(
      // Back button/gesture from any non-"الرئيسية" tab steps toward the
      // home tab first instead of doing nothing (see AdminShell).
      canPop: navigationShell.currentIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) navigationShell.goBranch(0);
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        // NOT extendBody: each branch's own Scaffold owns its FloatingActionButton
        // (e.g. "طلب صيانة جديد") — extending the body behind this nav bar would
        // render those FABs underneath it, unreachable.
        body: navigationShell,
        bottomNavigationBar: GlassBottomNav(
          navigationShell: navigationShell,
          items: _items,
          badges: {_cartTab: cartCount},
        ),
      ),
    );
  }
}
