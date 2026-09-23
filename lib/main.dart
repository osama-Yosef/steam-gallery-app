import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'core/config/env.dart';
import 'core/firebase/push_notification_service.dart';
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

  if (Env.isConfigured) {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      publishableKey: Env.supabasePublishableKey,
    );
  }

  runApp(
    ProviderScope(
      overrides: [
        if (pushService != null)
          pushNotificationServiceProvider.overrideWithValue(pushService),
      ],
      child: const MokojiApp(),
    ),
  );
}
