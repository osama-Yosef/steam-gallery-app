import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'gradient_box.dart';

/// App-wide backdrop: a soft paper-to-teal gradient with a few large, soft
/// color "blobs" behind it. Every Scaffold is transparent (see AppTheme) so
/// this shows through everywhere — the glass look across every screen
/// without touching them individually.
///
/// Performance: the blobs are radial gradients that fade to transparent,
/// NOT circles under an `ImageFilter.blur`. A blur of that radius over
/// screen-sized shapes is re-rendered on every frame by Impeller (there is
/// no raster cache), which made every page transition and scroll stutter.
/// The [RepaintBoundary] keeps this static layer from repainting along with
/// the routes drawn on top of it.
class GlassBackground extends StatelessWidget {
  final Widget child;
  const GlassBackground({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: GradientBox(
            // Old integrated GPUs draw no gradients (see GradientBox): they
            // get the flat paper colour and no blobs.
            fallback: AppColors.bgTop,
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.bgTop, AppColors.bgBottom],
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _Blob(
                  color: AppColors.blobTeal,
                  size: size.width * 0.9,
                  top: -size.width * 0.35,
                  left: -size.width * 0.3,
                ),
                _Blob(
                  color: AppColors.blobGold,
                  size: size.width * 0.95,
                  top: size.height * 0.35,
                  right: -size.width * 0.4,
                  // Gold reads much brighter than teal at the same opacity.
                  opacity: 0.12,
                ),
                _Blob(
                  color: AppColors.blobSky,
                  size: size.width * 0.7,
                  bottom: -size.width * 0.25,
                  left: -size.width * 0.2,
                  opacity: 0.16,
                ),
              ],
            ),
          ),
        ),
        child,
      ],
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
    // The blurred circle this replaces spread well past its own edge, so the
    // gradient is drawn on a larger square and fades out across it.
    final extent = size * 1.6;
    final offset = (extent - size) / 2;
    return Positioned(
      top: top == null ? null : top! - offset,
      left: left == null ? null : left! - offset,
      right: right == null ? null : right! - offset,
      bottom: bottom == null ? null : bottom! - offset,
      width: extent,
      height: extent,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [
                color.withValues(alpha: opacity),
                color.withValues(alpha: opacity * 0.55),
                color.withValues(alpha: 0),
              ],
              stops: const [0.0, 0.4, 1.0],
            ),
          ),
        ),
      ),
    );
  }
}
