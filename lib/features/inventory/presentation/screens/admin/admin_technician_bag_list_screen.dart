import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../../../maintenance/presentation/providers/maintenance_providers.dart';

class AdminTechnicianBagListScreen extends ConsumerWidget {
  const AdminTechnicianBagListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final techniciansAsync = ref.watch(assignableTechniciansProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('شنط الصنايعية')),
      body: techniciansAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: 'تعذَّر تحميل الصنايعية',
          onRetry: () => ref.invalidate(assignableTechniciansProvider),
        ),
        data: (technicians) {
          if (technicians.isEmpty) {
            return const EmptyView(
              message: 'لا يوجد صنايعية',
              icon: Iconsax.personalcard_copy,
            );
          }
          return ListView.separated(
            itemCount: technicians.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final t = technicians[i];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                  child: const Icon(Iconsax.user_copy, color: AppColors.primary),
                ),
                title: Text(t.fullName),
                subtitle: Text('كود: ${t.employeeCode}'),
                trailing: const Icon(Iconsax.arrow_left_2_copy),
                onTap: () =>
                    context.push(Routes.adminTechnicianBagDetail(t.id)),
              );
            },
          );
        },
      ),
    );
  }
}
