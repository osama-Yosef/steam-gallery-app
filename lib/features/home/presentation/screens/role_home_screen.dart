import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

/// Temporary landing screen per role — proves end-to-end that
/// login -> role lookup -> correct shell routing works (Module 1 DoD).
/// Each real feature module (dashboard/maintenance/bag/...) replaces the
/// body of its respective shell as it's built, per docs/07-implementation-roadmap.md.
class RoleHomeScreen extends ConsumerWidget {
  final String roleLabel;
  final IconData icon;

  const RoleHomeScreen({super.key, required this.roleLabel, required this.icon});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentUserProfileProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: Text(roleLabel),
        actions: [
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
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64),
            const SizedBox(height: 16),
            Text('مرحبًا ${profile?.fullName ?? ''}', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(roleLabel, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
