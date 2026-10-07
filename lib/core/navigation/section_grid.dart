import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_panel.dart';

/// One tile on a "الأقسام" page: tapping it pushes [route].
class SectionItem {
  final IconData icon;
  final String label;
  final List<Color> colors;
  final String route;
  const SectionItem({
    required this.icon,
    required this.label,
    required this.colors,
    required this.route,
  });
}

/// The tile grid shared by the admin and sales "الأقسام" pages.
class SectionGrid extends StatelessWidget {
  final List<SectionItem> sections;
  const SectionGrid({required this.sections, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, c) {
          final columns = (c.maxWidth / 190).floor().clamp(2, 6);
          return GridView(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              // A fixed row height rather than childAspectRatio, which ties
              // height to width — otherwise, whenever the admin sidebar rail
              // opens and narrows this grid, the shorter cells would overflow
              // their tile and spill text out of it.
              mainAxisExtent: 132,
            ),
            children: [
              for (final section in sections)
                _SectionTile(
                  section: section,
                  onTap: () => context.push(section.route),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionTile extends StatelessWidget {
  final SectionItem section;
  final VoidCallback onTap;
  const _SectionTile({required this.section, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      borderRadius: BorderRadius.circular(22),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: section.colors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: section.colors.last.withValues(alpha: 0.4),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: Icon(section.icon, color: Colors.white, size: 22),
                ),
                const SizedBox(height: 10),
                Text(
                  section.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
