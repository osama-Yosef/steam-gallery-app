import 'package:flutter/material.dart';

/// Shown instead of crashing when the app was launched without
/// --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
/// See docs/07-implementation-roadmap.md, Module 0.
class ConfigMissingScreen extends StatelessWidget {
  const ConfigMissingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.dns_outlined, size: 56),
              const SizedBox(height: 16),
              Text(
                'إعدادات Supabase غير موجودة',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'شغّل التطبيق مع بيانات مشروعك:\n\n'
                'flutter run \\\n'
                '  --dart-define=SUPABASE_URL=https://xxxx.supabase.co \\\n'
                '  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_...',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'monospace'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
