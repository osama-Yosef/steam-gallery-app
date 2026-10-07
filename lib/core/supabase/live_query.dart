import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Runs [fetch] once when listened to, then again whenever [changes] fires
/// (bursts within [debounce] collapse into one refetch).
///
/// This is how a screen shows a *subset* of a table live — e.g. the orders
/// that are still open. Supabase's own `.stream()` can filter, but a
/// filtered realtime subscription never hears about a row that stops
/// matching (an order moving to "completed" would stay on the open list
/// forever). Listening to every change of the table only as a signal, and
/// re-running the real query, avoids that — and the query goes through the
/// offline cache like any other read.
Stream<T> refetchOn<T>(
  Future<T> Function() fetch,
  Stream<void> changes, {
  Duration debounce = const Duration(milliseconds: 400),
}) {
  late final StreamController<T> controller;
  StreamSubscription<void>? changeSub;
  Timer? pending;
  var closed = false;

  Future<void> run() async {
    try {
      final value = await fetch();
      if (!closed) controller.add(value);
    } catch (e, st) {
      if (!closed) controller.addError(e, st);
    }
  }

  controller = StreamController<T>(
    onListen: () {
      unawaited(run());
      changeSub = changes.listen((_) {
        pending?.cancel();
        pending = Timer(debounce, run);
      });
    },
    onCancel: () async {
      closed = true;
      pending?.cancel();
      await changeSub?.cancel();
    },
  );
  return controller.stream;
}

/// Fires whenever a row of [table] is inserted, updated or deleted (as far
/// as the signed-in user's row-level security lets them see), and each time
/// the realtime channel (re)connects — so a screen catches up on whatever
/// changed while the connection was down.
Stream<void> tableChanges(SupabaseClient client, String table) {
  late final StreamController<void> controller;
  RealtimeChannel? channel;
  controller = StreamController<void>(
    onListen: () {
      channel = client
          .channel('live:$table:${const Uuid().v4()}')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: table,
            callback: (_) => controller.add(null),
          )
          .subscribe((status, _) {
            if (status == RealtimeSubscribeStatus.subscribed) {
              controller.add(null);
            }
          });
    },
    onCancel: () async {
      final c = channel;
      if (c != null) await client.removeChannel(c);
    },
  );
  return controller.stream;
}
