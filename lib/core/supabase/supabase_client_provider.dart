import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'supabase_client_provider.g.dart';

@Riverpod(keepAlive: true)
SupabaseClient supabaseClient(Ref ref) => Supabase.instance.client;

/// Raw Supabase auth state stream (SIGNED_IN / SIGNED_OUT / TOKEN_REFRESHED...).
/// The router listens to this (via GoRouterRefreshStream) to re-evaluate
/// redirects the instant a session appears or disappears.
@Riverpod(keepAlive: true)
Stream<AuthState> authStateChanges(Ref ref) {
  final client = ref.watch(supabaseClientProvider);
  return client.auth.onAuthStateChange;
}
