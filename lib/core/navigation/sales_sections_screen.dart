import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../router/route_names.dart';
import '../theme/app_colors.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/glass_panel.dart';

class _SectionItem {
  final IconData icon;
  final String label;
  final List<Color> colors;
  final String route;
  const _SectionItem({
    required this.icon,
    required this.label,
    required this.colors,
    required this.route,
  });
}

const _sections = [
  _SectionItem(
    icon: Iconsax.discount_shape_copy,
    label: 'العروض والبانرات',
    colors: [Color(0xFFE4B83F), Color(0xFFB7862A)],
    route: Routes.salesMarketing,
  ),
  _SectionItem(
    icon: Iconsax.bank_copy,
    label: 'مراجعة InstaPay',
    colors: [Color(0xFF9575CD), Color(0xFF5E35B1)],
    route: Routes.salesInstapayReview,
  ),
  _SectionItem(
    icon: Iconsax.wallet_money_copy,
    label: 'الخزنة',
    colors: [Color(0xFF7CE0FF), Color(0xFF38BDF8)],
    route: Routes.salesCashbox,
  ),
  _SectionItem(
    icon: Iconsax.receipt_2_copy,
    label: 'مرتجع المبيعات',
    colors: [Color(0xFFEF9A9A), Color(0xFFD32F2F)],
    route: Routes.salesSalesReturns,
  ),
];

/// The sales role's equivalent of [AdminSectionsScreen] — no products or
/// warehouse tiles (0046: sales must never see products or warehouse stock,
/// only what it sells through "بيع مباشر" itself).
class SalesSectionsScreen extends ConsumerWidget {
  const SalesSectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الأقسام'),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.logout_copy),
            tooltip: 'تسجيل الخروج',
            onPressed: () async {
              final confirmed = await showConfirmDialog(
                context,
                title: 'تسجيل الخروج',
                message: 'هل تريد تسجيل الخروج من حسابك؟',
              );
              if (confirmed) {
                await ref.read(authRepositoryProvider).signOut();
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, c) {
            final columns = (c.maxWidth / 190).floor().clamp(2, 6);
            return GridView(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                mainAxisExtent: 132,
              ),
              children: [
                for (final section in _sections)
                  _SectionTile(
                    icon: section.icon,
                    label: section.label,
                    colors: section.colors,
                    onTap: () => context.push(section.route),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SectionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final List<Color> colors;
  final VoidCallback onTap;
  const _SectionTile({
    required this.icon,
    required this.label,
    required this.colors,
    required this.onTap,
  });

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
                      colors: colors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colors.last.withValues(alpha: 0.4),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                const SizedBox(height: 10),
                Text(
                  label,
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
