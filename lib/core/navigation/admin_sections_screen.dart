import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../features/support/presentation/providers/support_providers.dart';
import '../errors/app_exception.dart';
import '../router/route_names.dart';
import 'section_grid.dart';

const _sections = <SectionItem>[
  SectionItem(
    icon: Iconsax.box_copy,
    label: 'المنتجات',
    colors: [Color(0xFF6D8CFF), Color(0xFF3B5BFF)],
    route: Routes.adminProducts,
  ),
  SectionItem(
    icon: Iconsax.receipt_text_copy,
    label: 'الطلبات',
    colors: [Color(0xFFB07CFF), Color(0xFF7C4DFF)],
    route: Routes.adminOrders,
  ),
  SectionItem(
    icon: Iconsax.setting_2_copy,
    label: 'الصيانة',
    colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
    route: Routes.adminMaintenance,
  ),
  SectionItem(
    icon: Iconsax.buildings_2_copy,
    label: 'المخزن',
    colors: [Color(0xFF34D399), Color(0xFF10B981)],
    route: Routes.adminWarehouse,
  ),
  SectionItem(
    icon: Iconsax.wallet_money_copy,
    label: 'الخزنة',
    colors: [Color(0xFF7CE0FF), Color(0xFF38BDF8)],
    route: Routes.adminCashbox,
  ),
  SectionItem(
    icon: Iconsax.people_copy,
    label: 'الموظفين',
    colors: [Color(0xFFFFAB91), Color(0xFFF4511E)],
    route: Routes.adminEmployees,
  ),
  SectionItem(
    icon: Iconsax.card_pos_copy,
    label: 'بيع مباشر',
    colors: [Color(0xFFFF8A65), Color(0xFFE64A19)],
    route: Routes.adminWalkInSale,
  ),
  SectionItem(
    icon: Iconsax.tag_copy,
    label: 'عرض السعر',
    colors: [Color(0xFFFFB74D), Color(0xFFF57C00)],
    route: Routes.adminPriceList,
  ),
  SectionItem(
    icon: Iconsax.receipt_2_copy,
    label: 'فواتير الشراء',
    colors: [Color(0xFF4DD0E1), Color(0xFF0097A7)],
    route: Routes.adminPurchaseInvoices,
  ),
  SectionItem(
    icon: Iconsax.profile_2user_copy,
    label: 'الموردين',
    colors: [Color(0xFFAED581), Color(0xFF689F38)],
    route: Routes.adminSuppliers,
  ),
  SectionItem(
    icon: Iconsax.refresh_circle_copy,
    label: 'المزامنة',
    colors: [Color(0xFF90A4AE), Color(0xFF546E7A)],
    route: Routes.adminSync,
  ),
  SectionItem(
    icon: Iconsax.chart_2_copy,
    label: 'التقارير',
    colors: [Color(0xFFA78BFA), Color(0xFF7C3AED)],
    route: Routes.adminReports,
  ),
  SectionItem(
    icon: Iconsax.people_copy,
    label: 'العملاء',
    colors: [Color(0xFFF48FB1), Color(0xFFEC407A)],
    route: Routes.adminCustomers,
  ),
  SectionItem(
    icon: Iconsax.discount_shape_copy,
    label: 'العروض والبانرات',
    colors: [Color(0xFFE4B83F), Color(0xFFB7862A)],
    route: Routes.adminMarketing,
  ),
  SectionItem(
    icon: Iconsax.map_copy,
    label: 'مناطق الخدمة',
    colors: [Color(0xFF67A9B2), Color(0xFF2F7784)],
    route: Routes.adminServiceAreas,
  ),
  SectionItem(
    icon: Iconsax.profile_2user_copy,
    label: 'المستخدمون',
    colors: [Color(0xFF80CBC4), Color(0xFF00897B)],
    route: Routes.adminUsers,
  ),
  SectionItem(
    icon: Iconsax.bank_copy,
    label: 'مراجعة InstaPay',
    colors: [Color(0xFF9575CD), Color(0xFF5E35B1)],
    route: Routes.adminInstapayReview,
  ),
  SectionItem(
    icon: Iconsax.receipt_2_copy,
    label: 'مرتجع المبيعات',
    colors: [Color(0xFFEF9A9A), Color(0xFFD32F2F)],
    route: Routes.adminSalesReturns,
  ),
  SectionItem(
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
      body: const SectionGrid(sections: _sections),
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
          const Text(
            'العميل هيشوف زرار "تواصل معنا" في حسابه يفتح واتساب على الرقم ده.',
          ),
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
