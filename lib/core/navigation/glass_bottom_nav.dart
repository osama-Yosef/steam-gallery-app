import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_panel.dart';

/// One tab of a [GlassBottomNav].
typedef GlassNavItem = ({IconData icon, String label});

/// The floating glass pill bottom nav shared by the customer, sales and
/// technician shells. Tapping the current tab again returns that branch to
/// its first screen.
class GlassBottomNav extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  final List<GlassNavItem> items;

  /// A count badge per tab index (e.g. the cart); null or 0 shows none.
  final Map<int, int> badges;

  const GlassBottomNav({
    required this.navigationShell,
    required this.items,
    this.badges = const {},
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // Fewer tabs get more room each; six still have to fit on a phone.
    final itemPadding = items.length > 4 ? 8.0 : 18.0;
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: GlassPanel(
        borderRadius: BorderRadius.circular(28),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (var i = 0; i < items.length; i++)
              _TabItem(
                item: items[i],
                horizontalPadding: itemPadding,
                selected: navigationShell.currentIndex == i,
                badge: badges[i],
                onTap: () => navigationShell.goBranch(
                  i,
                  initialLocation: i == navigationShell.currentIndex,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final GlassNavItem item;
  final double horizontalPadding;
  final bool selected;
  final int? badge;
  final VoidCallback onTap;

  const _TabItem({
    required this.item,
    required this.horizontalPadding,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textSecondary;
    final showBadge = badge != null && badge! > 0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            // Flat, not a gradient: old integrated GPUs draw gradients as
            // nothing, which left the selected tab unmarked (see GradientBox).
            color: selected ? AppColors.primary.withValues(alpha: 0.3) : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Badge(
                label: showBadge ? Text('$badge') : null,
                isLabelVisible: showBadge,
                child: Icon(item.icon, color: color, size: 22),
              ),
              const SizedBox(height: 3),
              Text(item.label, style: TextStyle(color: color, fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }
}
