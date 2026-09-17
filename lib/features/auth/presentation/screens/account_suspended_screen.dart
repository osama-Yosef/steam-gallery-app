import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/auth_providers.dart';
import '../widgets/auth_page.dart';

/// Shown to a signed-in account an admin has deactivated. The database
/// already refuses everything such an account tries (auth_role() is anon for
/// it, 0029); this just explains why instead of a wall of errors.
class AccountSuspendedScreen extends ConsumerWidget {
  const AccountSuspendedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AuthPage(
      title: 'الحساب موقوف',
      leading: const SizedBox.shrink(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.block, size: 56, color: AppColors.danger),
          const SizedBox(height: 16),
          const Text(
            'تم إيقاف هذا الحساب. لو تعتقد إن ده حصل بالغلط تواصل مع الإدارة.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
            child: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );
  }
}
