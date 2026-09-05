import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// App-wide backdrop: a deep navy→violet gradient with a few large, heavily
/// blurred color "blobs" behind it. Every Scaffold is transparent (see
/// AppTheme) so this shows through everywhere — the same one-place trick
/// used for the dark-navy rollout, now producing the glass look for free
/// across every existing screen without touching them individually.
class GlassBackground extends StatelessWidget {
  final Widget child;
  const GlassBackground({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.bgTop, AppColors.bgBottom],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _Blob(
            color: AppColors.blobBlue,
            size: size.width * 0.9,
            top: -size.width * 0.35,
            left: -size.width * 0.3,
          ),
          _Blob(
            color: AppColors.blobViolet,
            size: size.width * 0.95,
            top: size.height * 0.35,
            right: -size.width * 0.4,
          ),
          _Blob(
            color: AppColors.blobCyan,
            size: size.width * 0.7,
            bottom: -size.width * 0.25,
            left: -size.width * 0.2,
            opacity: 0.16,
          ),
          child,
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  final Color color;
  final double size;
  final double? top;
  final double? left;
  final double? right;
  final double? bottom;
  final double opacity;

  const _Blob({
    required this.color,
    required this.size,
    this.top,
    this.left,
    this.right,
    this.bottom,
    this.opacity = 0.24,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: IgnorePointer(
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: opacity),
            ),
          ),
        ),
      ),
    );
  }
}
