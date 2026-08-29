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

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
