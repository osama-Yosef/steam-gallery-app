import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../supabase/supabase_client_provider.dart';

extension ProviderCache on Ref {
  /// Keeps an auto-dispose provider's data for [keep] after the last screen
  /// using it closes, so opening that screen again shows the data instantly
  /// instead of a spinner while the same request goes back to the server.
  ///
  /// The data never goes stale silently: when a screen comes back to it after
  /// more than [staleAfter], it is refetched in the background — the old
  /// data stays on screen meanwhile (`AsyncValue.when` skips the loading
  /// state on a refresh). Writes made in the app still refetch it right
  /// away through `ref.invalidate` / `DataRefreshScope`.
  ///
  /// Tied to the signed-in user: a different account never sees what the
  /// previous one cached.
  ///
  /// Call it first thing in the provider's body:
  /// ```dart
  /// @riverpod
  /// Future<List<Supplier>> suppliers(Ref ref) {
  ///   ref.cacheFor();
  ///   return ref.watch(purchasesRepositoryProvider).getSuppliers();
  /// }
  /// ```
  void cacheFor({
    Duration keep = const Duration(minutes: 5),
    Duration staleAfter = const Duration(seconds: 30),
  }) {
    watch(
      authStateChangesProvider.select((auth) => auth.value?.session?.user.id),
    );

    final link = keepAlive();
    Timer? disposeTimer;
    DateTime? leftAt;

    onCancel(() {
      leftAt = DateTime.now();
      disposeTimer = Timer(keep, link.close);
    });
    onResume(() {
      disposeTimer?.cancel();
      final since = leftAt;
      leftAt = null;
      if (since != null && DateTime.now().difference(since) > staleAfter) {
        // A Ref can't be used inside its own life-cycle callbacks.
        Timer.run(() {
          if (mounted) invalidateSelf();
        });
      }
    });
    onDispose(() => disposeTimer?.cancel());
  }
}
