import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../auth/data/models/app_user.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/models/app_notification.dart';
import '../providers/notification_providers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(myNotificationsProvider);
    final role = ref.watch(currentUserProfileProvider).value?.role;

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشعارات'),
        actions: [
          IconButton(
            tooltip: 'تعليم الكل كمقروء',
            icon: const Icon(Icons.done_all),
            onPressed: () async {
              final uid = ref.read(currentUserProfileProvider).value?.id;
              if (uid != null) {
                await ref.read(notificationRepositoryProvider).markAllAsRead(uid);
              }
            },
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => const ErrorView(message: 'تعذَّر تحميل الإشعارات'),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyView(message: 'لا توجد إشعارات بعد', icon: Icons.notifications_none);
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final n = items[i];
              return ListTile(
                tileColor: n.isRead ? null : Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.25),
                leading: CircleAvatar(child: Icon(_iconFor(n.type))),
                title: Text(n.title, style: TextStyle(fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold)),
                subtitle: Text(
                  [if (n.body != null && n.body!.isNotEmpty) n.body, Formatters.dateTime(n.createdAt)]
                      .join(' · '),
                ),
                onTap: () async {
                  if (!n.isRead) await ref.read(notificationRepositoryProvider).markAsRead(n.id);
                  if (context.mounted) _navigate(context, n, role);
                },
              );
            },
          );
        },
      ),
    );
  }

  IconData _iconFor(String type) => switch (type) {
        'order_status' => Icons.receipt_long_outlined,
        'maintenance_new' => Icons.build_outlined,
        'maintenance_completed' => Icons.check_circle_outline,
        'low_stock' => Icons.inventory_2_outlined,
        _ => Icons.notifications_outlined,
      };

  void _navigate(BuildContext context, AppNotification n, AppRole? role) {
    final orderId = n.data['order_id'] as String?;
    final maintenanceId = n.data['maintenance_request_id'] as String?;

    switch (n.type) {
      case 'order_status':
        if (orderId == null) return;
        if (role == AppRole.customer) context.push(Routes.customerOrderDetail(orderId));
        if (role == AppRole.admin) context.push(Routes.adminOrderDetail(orderId));
      case 'maintenance_new':
      case 'maintenance_completed':
        if (maintenanceId == null) return;
        if (role == AppRole.customer) context.push(Routes.customerMaintenanceDetail(maintenanceId));
        if (role == AppRole.technician) context.push(Routes.technicianMaintenanceDetail(maintenanceId));
        if (role == AppRole.admin) context.push(Routes.adminMaintenanceDetail(maintenanceId));
      case 'low_stock':
        if (role == AppRole.admin) context.push(Routes.adminWarehouse);
    }
  }
}
