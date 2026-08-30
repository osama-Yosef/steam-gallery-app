import 'dart:async';
import 'package:flutter/foundation.dart';

/// Bridges a Stream (Supabase's onAuthStateChange) into a Listenable that
/// go_router's `refreshListenable` understands, so a sign-in/sign-out
/// re-evaluates the redirect logic immediately without a manual navigation.
class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  /// Lets external code (e.g. a `ref.listen` on a provider the redirect
  /// logic depends on, such as the profile fetch) force go_router to
  /// re-run its redirect callback even when no new auth event fired.
  void ping() => notifyListeners();

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
