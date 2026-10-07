import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../router/route_names.dart';
import '../widgets/confirm_dialog.dart';
import 'section_grid.dart';

const _sections = <SectionItem>[
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
      body: const SectionGrid(sections: _sections),
    );
  }
}
