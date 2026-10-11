import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/money_text.dart';
import '../../../../core/widgets/state_views.dart';
import '../../data/models/employee_models.dart';
import '../providers/employees_providers.dart';

/// The shop's staff with their salary and what they still owe in advances.
/// Stopped employees are listed last, greyed out.
class AdminEmployeesScreen extends ConsumerWidget {
  const AdminEmployeesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeesAsync = ref.watch(employeesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الموظفين'),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.calendar_tick_copy),
            tooltip: 'الحضور والغياب',
            onPressed: () => context.push(Routes.adminAttendance),
          ),
        ],
        bottom: switch (employeesAsync.value) {
          final list? when list.any((e) => e.isActive) => PreferredSize(
            preferredSize: const Size.fromHeight(36),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('إجمالي المرتبات الشهرية: '),
                  MoneyText(
                    list
                        .where((e) => e.isActive)
                        .fold<double>(0, (s, e) => s + e.monthlySalary),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ],
              ),
            ),
          ),
          _ => null,
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(Routes.adminEmployeeNew),
        icon: const Icon(Iconsax.user_add_copy),
        label: const Text('موظف جديد'),
      ),
      body: employeesAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: 'تعذَّر تحميل الموظفين',
          onRetry: () => ref.invalidate(employeesProvider),
        ),
        data: (employees) {
          if (employees.isEmpty) {
            return const EmptyView(
              message: 'لا يوجد موظفين بعد — أضف أول موظف',
              icon: Iconsax.people_copy,
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.refresh(employeesProvider.future),
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 12, bottom: 88),
              itemCount: employees.length,
              itemBuilder: (context, i) =>
                  _EmployeeTile(employee: employees[i]),
            ),
          );
        },
      ),
    );
  }
}

class _EmployeeTile extends StatelessWidget {
  final Employee employee;
  const _EmployeeTile({required this.employee});

  @override
  Widget build(BuildContext context) {
    final e = employee;
    final color = !e.isActive
        ? AppColors.textSecondary
        : e.advanceBalance > 0
        ? AppColors.warning
        : AppColors.primary;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: color.withValues(alpha: 0.08),
          child: InkWell(
            onTap: () => context.push(Routes.adminEmployeeDetail(e.id)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: color,
                    child: Text(
                      e.fullName.characters.first,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.fullName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          [
                            if (e.jobTitle != null) e.jobTitle!,
                            if (!e.isActive) 'موقوف',
                            if (e.advanceBalance > 0)
                              'عليه سلف ${Formatters.currency(e.advanceBalance)}',
                          ].join(' · ').ifEmpty('—'),
                          style: theme.textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  MoneyText(
                    e.monthlySalary,
                    style: TextStyle(color: color, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
