import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Every network image in the app goes through here.
///
/// Product photos are uploaded straight from a phone camera, often 3000+
/// pixels wide. Decoding one at full size for a 120-pixel grid tile costs
/// tens of megabytes and a visible hitch on the raster thread, and a grid of
/// them made scrolling and opening the store / register screens heavy. This
/// widget decodes the image at the size it is actually drawn (times the
/// screen's pixel ratio), and caches that smaller copy instead.
///
/// The API mirrors [CachedNetworkImage] for the parameters the app uses.
class AppNetworkImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit? fit;
  final double? width;
  final double? height;
  final Widget Function(BuildContext context, String url)? placeholder;
  final Widget Function(BuildContext context, String url, Object error)?
  errorWidget;

  const AppNetworkImage({
    required this.imageUrl,
    this.fit,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        double? finite(double? v) => v != null && v.isFinite ? v : null;
        final w = finite(width) ?? finite(constraints.maxWidth);
        final h = finite(height) ?? finite(constraints.maxHeight);
        // Decode by the longer side so BoxFit.cover still has enough pixels
        // whichever way the photo and the box are oriented. Aspect ratio is
        // kept — only the width is constrained.
        final longest = [w, h].whereType<double>().fold<double>(0, math.max);
        final cacheWidth = longest > 0 ? (longest * dpr).round() : null;

        return CachedNetworkImage(
          imageUrl: imageUrl,
          fit: fit,
          width: width,
          height: height,
          memCacheWidth: cacheWidth,
          fadeInDuration: const Duration(milliseconds: 200),
          placeholder: placeholder,
          errorWidget:
              errorWidget ??
              (_, _, _) => const Center(
                child: Icon(Icons.broken_image_outlined, color: Colors.black26),
              ),
        );
      },
    );
  }
}
