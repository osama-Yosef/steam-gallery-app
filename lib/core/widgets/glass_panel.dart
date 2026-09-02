import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// A real frosted-glass surface: backdrop blur + translucent fill + a
/// light 1px border + a soft top-edge sheen. Used for the navigation chrome
/// (sidebar / bottom nav) and hero dashboard cards — the highest-visibility
/// surfaces, where a genuine BackdropFilter blur is worth the cost. Ordinary
/// content cards get the cheaper "fake glass" look via CardTheme instead.
class GlassPanel extends StatelessWidget {
  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry? padding;
  final double blurSigma;
  final Color fill;
  final Gradient? gradient;

  const GlassPanel({
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
    this.padding,
    this.blurSigma = 24,
    this.fill = AppColors.glassFill,
    this.gradient,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: gradient == null ? fill : null,
            gradient: gradient,
            borderRadius: borderRadius,
            border: Border.all(color: AppColors.glassBorder, width: 1),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 24, offset: const Offset(0, 8)),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
