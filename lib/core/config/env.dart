/// Build-time configuration. Nothing here is a secret: SUPABASE_PUBLISHABLE_KEY
/// (Supabase's current name for what used to be called the "anon key") is safe
/// to ship inside the app because every table it can touch is protected by Row
/// Level Security (see docs/04-security-architecture.md). It is embedded in
/// every client build anyway — extractable from any shipped APK — which is
/// exactly what it is designed for. The secret/service_role key must NEVER
/// appear here or anywhere in this app — it only ever lives inside
/// supabase/functions/*.
///
/// The values below default to this project's Supabase instance so that a
/// plain `flutter run`, or the Run button in Android Studio / VS Code, works
/// with no extra setup. `--dart-define` still overrides them, which is how you
/// point a build at a different (e.g. staging) project:
///
///   flutter run \
///     --dart-define=SUPABASE_URL=https://xxxxx.supabase.co \
///     --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_...
class Env {
  const Env._();

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://jtvformbjielhhjtnsgh.supabase.co',
  );

  static const String supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_KnfOZejEqhApFb-MCjvq_Q_vLeu36Jq',
  );

  /// The app degrades to a "not configured" screen instead of crashing on
  /// startup if these are ever blanked out (e.g. someone overrides them with
  /// an empty --dart-define).
  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;
}
