import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/widgets/confirm_dialog.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../../../auth/presentation/providers/auth_providers.dart';
import '../../providers/technician_account_providers.dart';
import '../../widgets/account_summary_card.dart';

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
                  icon: const Icon(Icons.logout),
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
              icon: Icons.account_balance_wallet_outlined,
            );
          }
          return ListView(
            children: [
              AccountSummaryCard(summary: summary),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    FilledButton.icon(
                      onPressed: () async {
                        final route = isSelf
                            ? Routes.technicianAccountSupply
                            : Routes.adminTechnicianAccountSupply(resolvedId);
                        await context.push(route);
                        ref.invalidate(
                          technicianAccountSummaryProvider(resolvedId),
                        );
                      },
                      icon: const Icon(Icons.payments_outlined),
                      label: const Text('تسجيل توريد'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () {
                        final route = isSelf
                            ? Routes.technicianAccountHistory
                            : Routes.adminTechnicianAccountHistory(resolvedId);
                        context.push(route);
                      },
                      icon: const Icon(Icons.history),
                      label: const Text('سجل الحركات'),
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
