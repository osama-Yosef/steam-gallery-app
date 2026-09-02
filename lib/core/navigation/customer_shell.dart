import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/cart/presentation/providers/cart_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_panel.dart';

/// Floating glass pill bottom nav for the customer role — replaces the old
/// AppBar action icons (maintenance / orders / cart / logout) on the
/// catalog screen with always-visible tabs, wrapping a
/// [StatefulShellRoute.indexedStack].
class CustomerShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;
  const CustomerShell({required this.navigationShell, super.key});

  static const _items = [
    (icon: Icons.storefront_rounded, label: 'المتجر'),
    (icon: Icons.build_rounded, label: 'الصيانة'),
    (icon: Icons.shopping_cart_rounded, label: 'السلة'),
    (icon: Icons.receipt_long_rounded, label: 'طلباتي'),
    (icon: Icons.person_rounded, label: 'حسابي'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartCount = ref.watch(cartItemCountProvider);

    return PopScope(
      // Back button/gesture from any non-"المتجر" tab steps toward the
      // store tab first instead of doing nothing (see AdminShell).
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
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: GlassPanel(
          borderRadius: BorderRadius.circular(28),
          blurSigma: 30,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (var i = 0; i < _items.length; i++)
                _TabItem(
                  icon: _items[i].icon,
                  label: _items[i].label,
                  selected: navigationShell.currentIndex == i,
                  badge: i == 2 && cartCount > 0 ? cartCount : null,
                  onTap: () => navigationShell.goBranch(i, initialLocation: i == navigationShell.currentIndex),
                ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final int? badge;
  final VoidCallback onTap;

  const _TabItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textSecondary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: selected
                ? LinearGradient(
                    colors: [AppColors.primary.withValues(alpha: 0.35), AppColors.accent.withValues(alpha: 0.25)],
                  )
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Badge(
                label: badge != null ? Text('$badge') : null,
                isLabelVisible: badge != null,
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 3),
              Text(label, style: TextStyle(color: color, fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }
}
