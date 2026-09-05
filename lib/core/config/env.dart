/// Build-time configuration, injected via `--dart-define`. Nothing here is a
/// secret: SUPABASE_PUBLISHABLE_KEY (Supabase's current name for what used
/// to be called the "anon key") is safe to ship inside the app because
/// every table it can touch is protected by Row Level Security
/// (see docs/04-security-architecture.md). The secret/service_role key must
/// NEVER appear here or anywhere in this app — it only ever lives inside
/// supabase/functions/*.
///
/// Run with your real project, e.g.:
///   flutter run \
///     --dart-define=SUPABASE_URL=https://xxxxx.supabase.co \
///     --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_...
class Env {
  const Env._();

  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  /// Module 0 must be able to `flutter run` cleanly even before a real
  /// Supabase project exists — the app degrades to a "not configured"
  /// screen instead of crashing on startup.
  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;
}
