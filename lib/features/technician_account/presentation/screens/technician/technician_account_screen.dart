import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/confirm_dialog.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../../../auth/presentation/providers/auth_providers.dart';
import '../../providers/technician_account_providers.dart';
import '../../widgets/account_summary_card.dart';
import '../../widgets/pending_supplies_section.dart';

/// Shows the signed-in technician's own account when [technicianId] is null,
/// or a specific technician's account when an admin navigates here with one.
class TechnicianAccountScreen extends ConsumerWidget {
  final String? technicianId;
  const TechnicianAccountScreen({super.key, this.technicianId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resolvedId =
        technicianId ?? ref.watch(currentUserProfileProvider).value?.id;
    final isSelf = technicianId == null;

    if (resolvedId == null) {
      return const Scaffold(body: LoadingView());
    }

    final summaryAsync = ref.watch(
      technicianAccountSummaryProvider(resolvedId),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(isSelf ? 'حسابي' : 'حساب الصنايعي'),
        actions: isSelf
            ? [
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
              ]
            : null,
      ),
      body: summaryAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: 'تعذَّر تحميل الحساب',
          onRetry: () =>
              ref.invalidate(technicianAccountSummaryProvider(resolvedId)),
        ),
        data: (summary) {
          if (summary == null) {
            return const EmptyView(
              message: 'لا يوجد حساب بعد',
              icon: Iconsax.wallet_copy,
            );
          }
          return ListView(
            children: [
              AccountSummaryCard(summary: summary),
              PendingSuppliesSection(
                technicianId: resolvedId,
                // An admin opens this screen with an explicit technicianId.
                canReview: !isSelf,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _AccountActionButton(
                        icon: Iconsax.wallet_add_copy,
                        label: 'تسجيل توريد',
                        color: AppColors.success,
                        onTap: () async {
                          final route = isSelf
                              ? Routes.technicianAccountSupply
                              : Routes.adminTechnicianAccountSupply(
                                  resolvedId,
                                );
                          await context.push(route);
                          ref.invalidate(
                            technicianAccountSummaryProvider(resolvedId),
                          );
                          ref.invalidate(
                            pendingTechnicianSuppliesProvider(resolvedId),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _AccountActionButton(
                        icon: Iconsax.clock_copy,
                        label: 'سجل الحركات',
                        color: AppColors.info,
                        onTap: () {
                          final route = isSelf
                              ? Routes.technicianAccountHistory
                              : Routes.adminTechnicianAccountHistory(
                                  resolvedId,
                                );
                          context.push(route);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}

/// A colour-tinted card button — same visual language as the redesigned
/// admin screens' status cards, replacing the plain grey Filled/Outlined
/// buttons this screen used to have.
class _AccountActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _AccountActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Material(
        color: color.withValues(alpha: 0.1),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color),
                const SizedBox(height: 6),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: color, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
