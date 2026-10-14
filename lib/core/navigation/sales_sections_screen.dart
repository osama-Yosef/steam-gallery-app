import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../router/route_names.dart';
import '../widgets/confirm_dialog.dart';
import 'section_grid.dart';

/// The sales role's sections — shown under its dashboard on the home tab,
/// and on their own at [Routes.salesSections].
const salesSections = <SectionItem>[
  // The back office, the same screens as admin (0083).
  SectionItem(
    icon: Iconsax.buildings_2_copy,
    label: 'المخزن',
    colors: [Color(0xFF34D399), Color(0xFF10B981)],
    route: Routes.salesWarehouse,
  ),
  SectionItem(
    icon: Iconsax.receipt_2_copy,
    label: 'فواتير الشراء',
    colors: [Color(0xFF4DD0E1), Color(0xFF0097A7)],
    route: Routes.salesPurchaseInvoices,
  ),
  SectionItem(
    icon: Iconsax.people_copy,
    label: 'الموظفين',
    colors: [Color(0xFFFFAB91), Color(0xFFF4511E)],
    route: Routes.salesEmployees,
  ),
  SectionItem(
    icon: Iconsax.box_copy,
    label: 'المنتجات',
    colors: [Color(0xFF6D8CFF), Color(0xFF3B5BFF)],
    route: Routes.salesProducts,
  ),
  SectionItem(
    icon: Iconsax.tag_copy,
    label: 'عرض السعر',
    colors: [Color(0xFFFFB74D), Color(0xFFF57C00)],
    route: Routes.salesPriceList,
  ),
  SectionItem(
    icon: Iconsax.profile_2user_copy,
    label: 'الموردين',
    colors: [Color(0xFFAED581), Color(0xFF689F38)],
    route: Routes.salesSuppliers,
  ),
  SectionItem(
    icon: Iconsax.people_copy,
    label: 'العملاء',
    colors: [Color(0xFFF48FB1), Color(0xFFEC407A)],
    route: Routes.salesCustomers,
  ),
  SectionItem(
    icon: Iconsax.wallet_2_copy,
    label: 'محافظ العملاء',
    colors: [Color(0xFF64B5F6), Color(0xFF1976D2)],
    route: Routes.salesWallets,
  ),
  SectionItem(
    icon: Iconsax.discount_shape_copy,
    label: 'العروض والبانرات',
    colors: [Color(0xFFE4B83F), Color(0xFFB7862A)],
    route: Routes.salesMarketing,
  ),
  SectionItem(
    icon: Iconsax.bank_copy,
    label: 'مراجعة InstaPay',
    colors: [Color(0xFF9575CD), Color(0xFF5E35B1)],
    route: Routes.salesInstapayReview,
  ),
  SectionItem(
    icon: Iconsax.wallet_money_copy,
    label: 'الخزنة',
    colors: [Color(0xFF7CE0FF), Color(0xFF38BDF8)],
    route: Routes.salesCashbox,
  ),
  SectionItem(
    icon: Iconsax.receipt_2_copy,
    label: 'مرتجع المبيعات',
    colors: [Color(0xFFEF9A9A), Color(0xFFD32F2F)],
    route: Routes.salesSalesReturns,
  ),
];

/// The sales role's equivalent of [AdminSectionsScreen]: the back office
/// first, then marketing, InstaPay, the cashbox and sale returns. No users,
/// reports, service areas or sync settings.
class SalesSectionsScreen extends ConsumerWidget {
  const SalesSectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الأقسام'),
        actions: const [SalesLogoutButton()],
      ),
      body: const SectionGrid(sections: salesSections),
    );
  }
}

/// Sign-out, with a confirmation — on the sales home and sections pages.
class SalesLogoutButton extends ConsumerWidget {
  const SalesLogoutButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
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
    );
  }
}
