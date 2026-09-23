import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Real push, on top of the in-app notifications table (which only ever
/// reached an open, connected app via Realtime — see
/// features/notifications). Firebase Cloud Messaging delivers to this
/// device even closed/killed; this class is only what runs ON the device:
/// asking permission, keeping the token registered, and showing a heads-up
/// banner for the one case FCM can't do that itself — a message arriving
/// while the app is already open in the foreground.
class PushNotificationService {
  static const _channel = AndroidNotificationChannel(
    'default_channel',
    'إشعارات عامة',
    description: 'إشعارات الطلبات والصيانة والحساب',
    importance: Importance.high,
  );

  final _messaging = FirebaseMessaging.instance;
  final _local = FlutterLocalNotificationsPlugin();

  /// Call once at app start, after Firebase.initializeApp(). Requesting
  /// permission and creating the channel are both no-ops if already done.
  Future<void> init() async {
    await _messaging.requestPermission();

    await _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);
    await _local.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );

    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
  }

  /// The token to register against the signed-in user (auth_providers.dart
  /// calls updateFcmToken with this after every sign-in and on refresh).
  Future<String?> getToken() => _messaging.getToken();

  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  void _showForegroundNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;
    _local.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }
}
