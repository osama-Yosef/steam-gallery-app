import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/router/route_names.dart';
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
              icon: Icons.badge_outlined,
            );
          }
          return ListView.separated(
            itemCount: technicians.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final t = technicians[i];
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                title: Text(t.fullName),
                subtitle: Text('كود: ${t.employeeCode}'),
                trailing: const Icon(Icons.chevron_left),
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
