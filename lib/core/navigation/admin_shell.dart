import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../theme/app_colors.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/glass_panel.dart';

/// Collapsible glass sidebar for the admin role, wrapping a
/// [StatefulShellRoute.indexedStack] — replaces the old GridView home menu:
/// the sections it used to link to are always-reachable rail items, and a
/// small toggle handle lets the sidebar slide out of the way when it isn't
/// needed and reappear on demand.
///
/// The rail adapts to the window: a narrow icon-only rail on a phone, and a
/// wider labelled sidebar once there's desktop-class width to spend on it.
class AdminShell extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;
  const AdminShell({required this.navigationShell, super.key});

  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell> {
  bool _open = true;

  static const _items = [
    (icon: Icons.space_dashboard_rounded, label: 'الرئيسية'),
    (icon: Icons.inventory_2_rounded, label: 'المنتجات'),
    (icon: Icons.receipt_long_rounded, label: 'الطلبات'),
    (icon: Icons.build_rounded, label: 'الصيانة'),
    (icon: Icons.warehouse_rounded, label: 'المخزن'),
    (icon: Icons.account_balance_wallet_rounded, label: 'الخزنة'),
  ];

  /// Below this the window is treated as a phone: icon-only rail, content
  /// edge to edge. At or above it there's room for labels beside the icons.
  static const _wideBreakpoint = 900.0;

  static const _compactRailWidth = 84.0;
  static const _wideRailWidth = 216.0;

  /// Admin screens are lists and forms; letting them run the full width of a
  /// desktop monitor makes rows unreadably long and forms absurdly wide. Cap
  /// the content and centre it, leaving plenty of room for wide tables.
  static const _maxContentWidth = 1280.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= _wideBreakpoint;
        final railWidth = isWide ? _wideRailWidth : _compactRailWidth;

        return PopScope(
          // Otherwise the Android back button/gesture from any non-"الرئيسية"
          // section does nothing useful (StatefulShellRoute branches aren't a
          // navigation stack) — this makes "back" step toward home first, one
          // section at a time, like users expect.
          canPop: widget.navigationShell.currentIndex == 0,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) widget.navigationShell.goBranch(0);
          },
          child: Scaffold(
            backgroundColor: Colors.transparent,
            // The routed content (navigationShell) already has its own Scaffold
            // handling its own keyboard insets — without this, the sidebar's
            // fixed-height rail Column overflows whenever a nested screen's text
            // field opens the keyboard and this outer Scaffold also tries to
            // shrink for it.
            resizeToAvoidBottomInset: false,
            body: SafeArea(
              child: Row(
                children: [
                  ClipRect(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeInOutCubic,
                      width: _open ? railWidth : 0,
                      child: OverflowBox(
                        minWidth: railWidth,
                        maxWidth: railWidth,
                        alignment: AlignmentDirectional.centerStart,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(10, 16, 4, 16),
                          child: GlassPanel(
                            borderRadius: BorderRadius.circular(28),
                            blurSigma: 30,
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                            // A desktop window can be short (or the list can
                            // grow), so the rail scrolls rather than overflows.
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  for (var i = 0; i < _items.length; i++)
                                    _RailItem(
                                      icon: _items[i].icon,
                                      label: _items[i].label,
                                      expanded: isWide,
                                      selected: widget.navigationShell.currentIndex == i,
                                      onTap: () => widget.navigationShell.goBranch(
                                        i,
                                        initialLocation: i == widget.navigationShell.currentIndex,
                                      ),
                                    ),
                                  const SizedBox(height: 12),
                                  Container(height: 1, width: 32, color: AppColors.glassBorder),
                                  const SizedBox(height: 12),
                                  _RailItem(
                                    icon: Icons.logout_rounded,
                                    label: 'خروج',
                                    expanded: isWide,
                                    selected: false,
                                    danger: true,
                                    onTap: () async {
                                      final confirmed = await showConfirmDialog(
                                        context,
                                        title: 'تسجيل الخروج',
                                        message: 'هل تريد تسجيل الخروج من حسابك؟',
                                      );
                                      if (confirmed) await ref.read(authRepositoryProvider).signOut();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: _ToggleHandle(open: _open, onTap: () => setState(() => _open = !_open)),
                  ),
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: _maxContentWidth),
                        child: widget.navigationShell,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ToggleHandle extends StatelessWidget {
  final bool open;
  final VoidCallback onTap;
  const _ToggleHandle({required this.open, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      borderRadius: BorderRadius.circular(14),
      blurSigma: 20,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: SizedBox(
            width: 22,
            height: 56,
            child: Icon(
              open ? Icons.chevron_right_rounded : Icons.chevron_left_rounded,
              size: 18,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final bool danger;
  final bool expanded;
  final VoidCallback onTap;

  const _RailItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.expanded,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger
        ? AppColors.danger
        : selected
            ? AppColors.primary
            : AppColors.textSecondary;

    final decoration = BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      gradient: selected
          ? LinearGradient(
              colors: [AppColors.primary.withValues(alpha: 0.35), AppColors.accent.withValues(alpha: 0.25)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
          : null,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          // A pointer on desktop should say "this is clickable"; on touch this
          // is inert.
          mouseCursor: SystemMouseCursors.click,
          child: expanded
              ? Container(
                  width: 188,
                  padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 12, 12),
                  decoration: decoration,
                  child: Row(
                    children: [
                      Icon(icon, color: color, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          label,
                          style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                )
              : Container(
                  width: 64,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: decoration,
                  child: Column(
                    children: [
                      Icon(icon, color: color, size: 22),
                      const SizedBox(height: 4),
                      Text(label, style: TextStyle(color: color, fontSize: 10), textAlign: TextAlign.center),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
