import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../providers/notification_providers.dart';

/// Drop into any home screen's AppBar.actions — realtime badge count, tap
/// navigates to the shared notifications screen (Module 12).
class NotificationBellIcon extends ConsumerWidget {
  const NotificationBellIcon({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadNotificationCountProvider);

    return IconButton(
      tooltip: 'الإشعارات',
      onPressed: () => context.push(Routes.notifications),
      icon: Badge(
        isLabelVisible: unread > 0,
        label: Text('$unread'),
        child: const Icon(Icons.notifications_outlined),
      ),
    );
  }
}
