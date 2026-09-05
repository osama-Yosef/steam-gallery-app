import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/maintenance_providers.dart';

/// Renders one maintenance photo. The `maintenance` bucket is private, so the
/// stored value can't be handed to CachedNetworkImage directly — it has to be
/// exchanged for a signed URL first (doing that inline is what left every
/// photo showing as a broken image).
class MaintenanceImageThumb extends ConsumerWidget {
  final String storedPathOrUrl;
  final double size;

  const MaintenanceImageThumb({
    required this.storedPathOrUrl,
    this.size = 100,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final urlAsync = ref.watch(maintenanceImageUrlProvider(storedPathOrUrl));

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: size,
        height: size,
        child: urlAsync.when(
          loading: () => const ColoredBox(
            color: Colors.black12,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          error: (_, _) => const ColoredBox(
            color: Colors.black12,
            child: Icon(Icons.broken_image_outlined),
          ),
          data: (url) => CachedNetworkImage(
            imageUrl: url,
            width: size,
            height: size,
            fit: BoxFit.cover,
            placeholder: (_, _) => const ColoredBox(
              color: Colors.black12,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            errorWidget: (_, _, _) => const ColoredBox(
              color: Colors.black12,
              child: Icon(Icons.broken_image_outlined),
            ),
          ),
        ),
      ),
    );
  }
}
