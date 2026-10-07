import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../offline/network_status.dart';
import '../offline/outbox.dart';
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
  /// away through [refreshOnServerChange].
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

  /// Refetches this provider whenever a write made on this device reaches
  /// the server (a sale, an expense, a purchase invoice — sent directly or
  /// later from the offline queue), and when the connection comes back
  /// after being offline.
  ///
  /// Each provider whose data such a write can change opts in with this one
  /// line, next to its own definition — rather than a central list someone
  /// has to remember to extend (a screen left off that list kept showing
  /// stale data after a sale). Realtime streams don't need it.
  void refreshOnServerChange() {
    final changes = watch(outboxProvider).onServerChanged.listen((_) {
      if (mounted) invalidateSelf();
    });
    final network = NetworkStatus.instance;
    var wasOnline = network.isOnline;
    void onNetwork() {
      final online = network.isOnline;
      if (online && !wasOnline && mounted) invalidateSelf();
      wasOnline = online;
    }

    network.addListener(onNetwork);
    onDispose(() {
      changes.cancel();
      network.removeListener(onNetwork);
    });
  }
}
