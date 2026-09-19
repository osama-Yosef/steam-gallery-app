import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_panel.dart';

/// Floating glass pill bottom nav for the sales role (0046) — same shape as
/// [CustomerShell], replacing the old collapsible sidebar. Sales only gets
/// three tabs: البيع المباشر is the landing tab (sales must always default
/// to selling, not a dashboard), الطلبات, and الأقسام (marketing, InstaPay
/// review, cashbox withdrawal — everything that doesn't need its own tab).
class SalesShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;
  const SalesShell({required this.navigationShell, super.key});

  static const _items = [
    (icon: Icons.point_of_sale_rounded, label: 'بيع مباشر'),
    (icon: Icons.receipt_long_rounded, label: 'الطلبات'),
    (icon: Icons.apps_rounded, label: 'الأقسام'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopScope(
      canPop: navigationShell.currentIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) navigationShell.goBranch(0);
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
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
                    onTap: () => navigationShell.goBranch(
                      i,
                      initialLocation: i == navigationShell.currentIndex,
                    ),
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
  final VoidCallback onTap;

  const _TabItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: selected
                ? LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.35),
                      AppColors.accent.withValues(alpha: 0.25),
                    ],
                  )
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 3),
              Text(label, style: TextStyle(color: color, fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }
}
