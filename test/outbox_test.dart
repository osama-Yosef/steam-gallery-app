import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:steam_gallery_app/core/errors/app_exception.dart';
import 'package:steam_gallery_app/core/offline/network_status.dart';
import 'package:steam_gallery_app/core/offline/outbox.dart';

import 'helpers/test_outbox.dart';

/// The offline write queue (Outbox): what reaches the server, in what order,
/// and what the person at the counter is told.
void main() {
  late FakeServer server;
  late MemoryStore store;
  late Outbox outbox;

  setUp(() {
    server = FakeServer();
    store = MemoryStore();
    outbox = testOutbox(server: server, store: store);
  });

  Future<OutboxResult> sale(String id, {String kind = 'walk_in_sale'}) =>
      outbox.submit(
        rpc: 'rpc_admin_walk_in_sale',
        params: {'p_client_request_id': id},
        label: 'بيع $id',
        kind: kind,
        requestId: id,
      );

  test('online: a write goes straight to the server', () async {
    server.reply = {'sale_id': 's1'};
    final result = await sale('a');
    expect(result.queued, isFalse);
    expect(result.data, {'sale_id': 's1'});
    expect(server.calls.single.rpc, 'rpc_admin_walk_in_sale');
    expect(outbox.pending, isEmpty);
  });

  test('offline: the write is kept on the device, not lost', () async {
    server.online = false;
    final result = await sale('a');
    expect(result.queued, isTrue);
    expect(outbox.pending.single.id, 'a');
    // Survives an app restart: a new Outbox over the same store has it.
    final restarted = testOutbox(server: server, store: store);
    await restarted.start();
    expect(restarted.pending.single.id, 'a');
  });

  test('queued writes are sent in the order they were made', () async {
    server.online = false;
    await sale('a');
    await sale('b');
    await sale('c');
    server.online = true;
    await outbox.sync();
    expect(server.calls.map((c) => c.params['p_client_request_id']), [
      'a',
      'b',
      'c',
    ]);
    expect(outbox.pending, isEmpty);
  });

  test('while anything waits, a new write queues behind it', () async {
    server.online = false;
    await sale('a');
    server.online = true;
    // Sent along with the backlog, and reported as done — not "offline".
    final result = await sale('b');
    expect(result.queued, isFalse);
    expect(server.calls.map((c) => c.params['p_client_request_id']), [
      'a',
      'b',
    ]);
  });

  test('a server refusal is thrown in Arabic, never queued', () async {
    server.refusals['rpc_admin_walk_in_sale'] = 'INSUFFICIENT_STOCK';
    await expectLater(
      sale('a'),
      throwsA(
        isA<AppException>().having(
          (e) => e.messageAr,
          'messageAr',
          'الكمية المطلوبة غير متوفرة',
        ),
      ),
    );
    expect(outbox.entries, isEmpty);
  });

  test('a queued write the server later refuses is kept as failed, '
      'and the rest still go through', () async {
    server.online = false;
    await sale('a');
    await outbox.submit(
      rpc: 'rpc_record_expense',
      params: const {},
      label: 'مصروف',
      kind: 'expense',
      viaReplay: true,
      requestId: 'b',
    );
    server.online = true;
    server.refusals['rpc_admin_walk_in_sale'] = 'INSUFFICIENT_STOCK';
    await outbox.sync();
    expect(outbox.failed.single.id, 'a');
    expect(outbox.failed.single.error, 'الكمية المطلوبة غير متوفرة');
    expect(outbox.pending, isEmpty);

    // Retry after fixing the cause, or discard.
    server.refusals.clear();
    await outbox.retry(outbox.failed.single);
    expect(outbox.entries, isEmpty);
  });

  test('discarding a refused write removes it for good', () async {
    server.online = false;
    await sale('a');
    server.online = true;
    server.refusals['rpc_admin_walk_in_sale'] = 'FORBIDDEN';
    await outbox.sync();
    await outbox.discard(outbox.failed.single);
    expect(outbox.entries, isEmpty);
    expect(store.data['outbox.v1'], '[]');
  });

  test('writes without an idempotency key go through rpc_replay', () async {
    server.reply = {'result': 7};
    final result = await outbox.submit(
      rpc: 'rpc_record_expense',
      params: const {'p_amount': 50},
      label: 'مصروف',
      kind: 'expense',
      viaReplay: true,
      requestId: 'req-1',
    );
    expect(result.data, 7);
    final call = server.calls.single;
    expect(call.rpc, 'rpc_replay');
    expect(call.params, {
      'p_request_id': 'req-1',
      'p_rpc': 'rpc_record_expense',
      'p_params': {'p_amount': 50},
    });
  });

  test('a sync stops at the first connection failure', () async {
    server.online = false;
    await sale('a');
    await sale('b');
    await outbox.sync();
    expect(server.calls, isEmpty);
    expect(outbox.pending.length, 2);
  });

  test('a write made during a running sync is sent by that sync', () async {
    server.online = false;
    await sale('a');
    server.online = true;

    // Hold the first send so the sync is still running when 'b' arrives.
    final gate = Completer<void>();
    var first = true;
    final slow = Outbox(
      store: store,
      rpc: (rpc, params) async {
        if (first) {
          first = false;
          await gate.future;
        }
        return server.call(rpc, params);
      },
      currentUserId: () => 'admin-1',
      retryEvery: null,
    );
    await slow.start();
    final running = slow.sync();
    final b = slow.submit(
      rpc: 'rpc_admin_walk_in_sale',
      params: const {'p_client_request_id': 'b'},
      label: 'بيع b',
      kind: 'walk_in_sale',
      requestId: 'b',
    );
    gate.complete();
    await running;
    final result = await b;
    expect(result.queued, isFalse, reason: 'it was sent, not left waiting');
    expect(server.calls.map((c) => c.params['p_client_request_id']), [
      'a',
      'b',
    ]);
    expect(slow.pending, isEmpty);
  });

  test('another account never sees or sends this one\'s queue', () async {
    server.online = false;
    await sale('a');
    final other = testOutbox(server: server, store: store, userId: 'admin-2');
    await other.start();
    expect(other.entries, isEmpty);
    server.online = true;
    await other.sync();
    expect(server.calls, isEmpty);
  });

  test('signed out: a write is refused instead of queued anonymously', () {
    final signedOut = testOutbox(server: server, userId: null);
    expect(
      () => signedOut.submit(
        rpc: 'rpc_admin_walk_in_sale',
        params: const {},
        label: 'x',
        kind: 'walk_in_sale',
      ),
      throwsA(isA<AppException>()),
    );
  });

  test('onServerChanged fires once a write reaches the server', () async {
    var changes = 0;
    final sub = outbox.onServerChanged.listen((_) => changes++);
    addTearDown(sub.cancel);

    server.online = false;
    await sale('a');
    await Future<void>.delayed(Duration.zero);
    expect(changes, 0, reason: 'nothing reached the server yet');

    server.online = true;
    await outbox.sync();
    await Future<void>.delayed(Duration.zero);
    expect(changes, 1);
  });

  test('the connection coming back sends the queue by itself', () async {
    final network = NetworkStatus.instance;
    final online = testOutbox(server: server, store: store, network: network);
    await online.start();
    addTearDown(online.dispose);

    network.markOffline();
    server.online = false;
    await online.submit(
      rpc: 'rpc_admin_walk_in_sale',
      params: const {'p_client_request_id': 'a'},
      label: 'بيع a',
      kind: 'walk_in_sale',
      requestId: 'a',
    );
    server.online = true;
    network.markOnline();
    await Future<void>.delayed(Duration.zero);
    await online.sync();
    expect(online.pending, isEmpty);
    expect(server.calls.single.params['p_client_request_id'], 'a');
  });

  test('pendingOf filters by kind and record', () async {
    server.online = false;
    await sale('a');
    await outbox.submit(
      rpc: 'rpc_admin_edit_sale',
      params: const {},
      label: 'تعديل',
      kind: 'sale_edit',
      refId: 's1',
      requestId: 'e1',
    );
    expect(outbox.pendingOf('walk_in_sale').single.id, 'a');
    expect(outbox.pendingOf('sale_edit', refId: 's1').single.id, 'e1');
    expect(outbox.pendingOf('sale_edit', refId: 's2'), isEmpty);
  });
}
