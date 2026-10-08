import 'package:flutter/material.dart';

/// A box filled with [gradient], drawn over a plain [fallback] fill of the
/// same shape.
///
/// Old integrated GPUs (seen on an Intel HD Graphics 2000/3000 PC running
/// the Windows app) draw gradients as nothing at all: a gradient card with
/// white text on it simply vanished. With the solid fill underneath, those
/// machines show a flat card instead, and everywhere else the gradient
/// covers it exactly, so nothing changes.
class GradientBox extends StatelessWidget {
  final Gradient gradient;
  final Color fallback;
  final BoxShape shape;
  final BorderRadiusGeometry? borderRadius;
  final List<BoxShadow>? boxShadow;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final Widget? child;

  const GradientBox({
    required this.gradient,
    required this.fallback,
    this.shape = BoxShape.rectangle,
    this.borderRadius,
    this.boxShadow,
    this.width,
    this.height,
    this.padding,
    this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    Widget? content = child;
    if (padding != null) content = Padding(padding: padding!, child: content);
    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: fallback,
          shape: shape,
          borderRadius: borderRadius,
          boxShadow: boxShadow,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: gradient,
            shape: shape,
            borderRadius: borderRadius,
          ),
          child: content,
        ),
      ),
    );
  }
}
