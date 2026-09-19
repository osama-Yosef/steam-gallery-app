import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../features/support/presentation/providers/support_providers.dart';
import '../errors/app_exception.dart';
import '../router/route_names.dart';
import '../theme/app_colors.dart';
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
    icon: Iconsax.box_copy,
    label: 'المنتجات',
    colors: [Color(0xFF6D8CFF), Color(0xFF3B5BFF)],
    route: Routes.adminProducts,
  ),
  _SectionItem(
    icon: Iconsax.receipt_text_copy,
    label: 'الطلبات',
    colors: [Color(0xFFB07CFF), Color(0xFF7C4DFF)],
    route: Routes.adminOrders,
  ),
  _SectionItem(
    icon: Iconsax.setting_2_copy,
    label: 'الصيانة',
    colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
    route: Routes.adminMaintenance,
  ),
  _SectionItem(
    icon: Iconsax.buildings_2_copy,
    label: 'المخزن',
    colors: [Color(0xFF34D399), Color(0xFF10B981)],
    route: Routes.adminWarehouse,
  ),
  _SectionItem(
    icon: Iconsax.wallet_money_copy,
    label: 'الخزنة',
    colors: [Color(0xFF7CE0FF), Color(0xFF38BDF8)],
    route: Routes.adminCashbox,
  ),
  _SectionItem(
    icon: Iconsax.card_pos_copy,
    label: 'بيع مباشر',
    colors: [Color(0xFFFF8A65), Color(0xFFE64A19)],
    route: Routes.adminWalkInSale,
  ),
  _SectionItem(
    icon: Iconsax.chart_2_copy,
    label: 'التقارير',
    colors: [Color(0xFFA78BFA), Color(0xFF7C3AED)],
    route: Routes.adminReports,
  ),
  _SectionItem(
    icon: Iconsax.people_copy,
    label: 'العملاء',
    colors: [Color(0xFFF48FB1), Color(0xFFEC407A)],
    route: Routes.adminCustomers,
  ),
  _SectionItem(
    icon: Iconsax.discount_shape_copy,
    label: 'العروض والبانرات',
    colors: [Color(0xFFE4B83F), Color(0xFFB7862A)],
    route: Routes.adminMarketing,
  ),
  _SectionItem(
    icon: Iconsax.map_copy,
    label: 'مناطق الخدمة',
    colors: [Color(0xFF67A9B2), Color(0xFF2F7784)],
    route: Routes.adminServiceAreas,
  ),
  _SectionItem(
    icon: Iconsax.profile_2user_copy,
    label: 'المستخدمون',
    colors: [Color(0xFF80CBC4), Color(0xFF00897B)],
    route: Routes.adminUsers,
  ),
  _SectionItem(
    icon: Iconsax.bank_copy,
    label: 'مراجعة InstaPay',
    colors: [Color(0xFF9575CD), Color(0xFF5E35B1)],
    route: Routes.adminInstapayReview,
  ),
  _SectionItem(
    icon: Iconsax.receipt_2_copy,
    label: 'مرتجع المبيعات',
    colors: [Color(0xFFEF9A9A), Color(0xFFD32F2F)],
    route: Routes.adminSalesReturns,
  ),
  _SectionItem(
    icon: Iconsax.wallet_2_copy,
    label: 'محافظ العملاء',
    colors: [Color(0xFF64B5F6), Color(0xFF1976D2)],
    route: Routes.adminWallets,
  ),
];

/// The section shortcuts that used to fill the admin home page — now their
/// own page behind the "الأقسام" rail button, so the home page stays short
/// and this list gets room to breathe instead of being squeezed into a
/// bottom sheet.
class AdminSectionsScreen extends StatelessWidget {
  const AdminSectionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الأقسام'),
        actions: [
          IconButton(
            tooltip: 'إعدادات الدعم',
            icon: const Icon(Iconsax.setting_2_copy),
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              showDragHandle: true,
              builder: (_) => const _SupportSettingsSheet(),
            ),
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
                // A fixed row height rather than childAspectRatio, which
                // ties height to width — otherwise, whenever the sidebar
                // rail opens and narrows this grid, the shorter cells
                // would overflow their tile and spill text out of it.
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

class _SupportSettingsSheet extends ConsumerStatefulWidget {
  const _SupportSettingsSheet();

  @override
  ConsumerState<_SupportSettingsSheet> createState() =>
      _SupportSettingsSheetState();
}

class _SupportSettingsSheetState extends ConsumerState<_SupportSettingsSheet> {
  final _whatsappCtrl = TextEditingController();
  bool _saving = false;
  bool _loaded = false;

  void _prefill(String? whatsapp) {
    if (_loaded) return;
    _loaded = true;
    _whatsappCtrl.text = whatsapp ?? '';
  }

  @override
  void dispose() {
    _whatsappCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref
          .read(supportRepositoryProvider)
          .setWhatsapp(_whatsappCtrl.text.trim());
      ref.invalidate(supportWhatsappProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppException.from(e).messageAr)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final whatsappAsync = ref.watch(supportWhatsappProvider);
    whatsappAsync.whenData(_prefill);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('إعدادات الدعم', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          const Text('العميل هيشوف زرار "تواصل معنا" في حسابه يفتح واتساب على الرقم ده.'),
          const SizedBox(height: 16),
          TextField(
            controller: _whatsappCtrl,
            maxLength: 20,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'رقم واتساب الدعم',
              hintText: '01xxxxxxxxx',
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('حفظ'),
          ),
        ],
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
