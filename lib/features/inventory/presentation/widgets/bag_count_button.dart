import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../inventory_count/presentation/providers/inventory_count_providers.dart';
import '../providers/inventory_providers.dart';

/// «جرد الشنطة» in a bag screen's AppBar (0089): starts the bag's count —
/// or reopens the one already open — and opens it at [routeFor].
class BagCountButton extends ConsumerStatefulWidget {
  final String technicianId;
  final String Function(String countId) routeFor;
  const BagCountButton({
    super.key,
    required this.technicianId,
    required this.routeFor,
  });

  @override
  ConsumerState<BagCountButton> createState() => _BagCountButtonState();
}

class _BagCountButtonState extends ConsumerState<BagCountButton> {
  bool _starting = false;

  Future<void> _start() async {
    setState(() => _starting = true);
    try {
      final countId = await ref
          .read(inventoryCountRepositoryProvider)
          .startBagCount(widget.technicianId);
      ref.invalidate(inventoryCountsProvider);
      if (!mounted) return;
      await context.push(widget.routeFor(countId));
      ref.invalidate(technicianBagStockProvider(widget.technicianId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppException.from(e).messageAr)));
      }
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: _starting
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Iconsax.task_square_copy),
      tooltip: 'جرد الشنطة',
      onPressed: _starting ? null : _start,
    );
  }
}
