import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../core/theme/app_colors.dart';

/// "الخدمة متاحة — مدينة نصر" / "المنطقة غير مغطاة حاليًا". Always reflects
/// the server's resolution, never a client-side guess.
class AvailabilityBadge extends StatelessWidget {
  final bool available;
  final String? areaName;
  final bool compact;

  const AvailabilityBadge({
    super.key,
    required this.available,
    this.areaName,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = available ? AppColors.success : AppColors.warning;
    final text = available
        ? (areaName == null ? 'الخدمة متاحة' : 'الخدمة متاحة — $areaName')
        : 'المنطقة غير مغطاة حاليًا';
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 3 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            available ? Iconsax.tick_circle : Iconsax.info_circle_copy,
            size: compact ? 14 : 18,
            color: color,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: compact ? 11 : 13,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
