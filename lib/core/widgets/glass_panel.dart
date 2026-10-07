import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// A frosted-glass surface: translucent white fill + a light 1px border + a
/// soft shadow. Used for the navigation chrome (sidebar / bottom nav) and
/// hero cards.
///
/// There is deliberately no `BackdropFilter` here. Every panel sits over the
/// static [GlassBackground] (never over scrolling content), and the
/// near-opaque fill hides what a blur would have softened — while a backdrop
/// blur is re-rendered on every frame anything on screen moves, which is
/// what made switching tabs and pushing screens feel heavy.
class GlassPanel extends StatelessWidget {
  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry? padding;
  final Color fill;
  final Gradient? gradient;

  const GlassPanel({
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
    this.padding,
    this.fill = AppColors.glassFill,
    this.gradient,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: gradient == null ? fill : null,
        gradient: gradient,
        borderRadius: borderRadius,
        border: Border.all(color: AppColors.glassBorder, width: 1),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
