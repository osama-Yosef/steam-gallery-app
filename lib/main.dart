import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'core/config/env.dart';
import 'core/firebase/push_notification_service.dart';
import 'core/offline/offline_http_client.dart';
import 'core/offline/offline_store.dart';
import 'core/offline/outbox.dart';
import 'features/auth/presentation/providers/auth_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase (phone-auth proof + push) is wired for Android/iOS only — it
  // reads android/app/google-services.json natively, with no Dart-side
  // options for web, and firebase_messaging has no Windows/Linux plugin
  // implementation at all. Skip it on every other platform instead of
  // crashing app startup there.
  PushNotificationService? pushService;
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    await Firebase.initializeApp();
    pushService = PushNotificationService();
    await pushService.init();
  }

  Outbox? outbox;
  if (Env.isConfigured) {
    // Reads are cached and served from the device when the server can't be
    // reached; admin writes queue in the Outbox until it can (offline mode).
    final offlineStore = await OfflineStore.open();
    await Supabase.initialize(
      url: Env.supabaseUrl,
      publishableKey: Env.supabasePublishableKey,
      httpClient: OfflineHttpClient(offlineStore),
    );
    outbox = Outbox.supabase(Supabase.instance.client, offlineStore);
    await outbox.start();
  }

  runApp(
    ProviderScope(
      overrides: [
        if (pushService != null)
          pushNotificationServiceProvider.overrideWithValue(pushService),
        if (outbox != null) outboxProvider.overrideWithValue(outbox),
      ],
      child: const MokojiApp(),
    ),
  );
}
