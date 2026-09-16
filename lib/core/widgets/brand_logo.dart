import 'package:flutter/material.dart';
import '../constants/brand.dart';
import '../theme/app_colors.dart';

/// The Mokoji logo on its brand "paper" card. The wordmark is navy, so it
/// disappears against the app's dark background unless it sits on a light
/// surface — this widget is the one place that guarantees that.
class BrandLogo extends StatelessWidget {
  /// Width of the logo image itself; the card adds padding around it.
  final double width;

  /// The mark alone (no wordmark) — for tight spaces.
  final bool markOnly;

  const BrandLogo({super.key, this.width = 160, this.markOnly = false});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: Brand.name,
      image: true,
      child: Container(
        padding: EdgeInsets.all(width * 0.1),
        decoration: BoxDecoration(
          color: AppColors.brandPaper,
          borderRadius: BorderRadius.circular(width * 0.16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Image.asset(
          markOnly ? Brand.markAsset : Brand.logoAsset,
          width: width,
          filterQuality: FilterQuality.medium,
          excludeFromSemantics: true,
        ),
      ),
    );
  }
}
