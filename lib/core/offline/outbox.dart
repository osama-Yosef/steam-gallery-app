import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../errors/app_exception.dart';
import 'network_status.dart';
import 'offline_store.dart';

/// One write waiting to reach the server.
class OutboxEntry {
  /// Also the idempotency key: sent as the request id for [viaReplay]
  /// entries, and already embedded in [params] as p_client_request_id for
  /// RPCs that take one.
  final String id;
  final String rpc;
  final Map<String, dynamic> params;

  /// Send through rpc_replay (0076) so a repeat can't apply twice. Needed for
  /// RPCs with no idempotency key of their own (expense, deposit, order
  /// status changes...).
  final bool viaReplay;

  /// What the admin sees in the sync list, e.g. "بيع مباشر · 3 أصناف".
  final String label;

  /// Groups entries for screens that show pending work, e.g. 'walk_in_sale'.
  final String kind;

  /// The record it concerns (an order id, a sale id), if any.
  final String? refId;

  /// Display-only data for screens showing the pending change (never sent).
  final Map<String, dynamic>? meta;
  final String userId;
  final DateTime createdAt;

  /// Set once the server rejected it (not a connection problem) — it then
  /// waits for the admin to retry or discard it.
  final String? error;

  const OutboxEntry({
    required this.id,
    required this.rpc,
    required this.params,
    required this.viaReplay,
    required this.label,
    required this.kind,
    required this.userId,
    required this.createdAt,
    this.refId,
    this.meta,
    this.error,
  });

  bool get failed => error != null;

  OutboxEntry withError(String? error) => OutboxEntry(
    id: id,
    rpc: rpc,
    params: params,
    viaReplay: viaReplay,
    label: label,
    kind: kind,
    refId: refId,
    meta: meta,
    userId: userId,
    createdAt: createdAt,
    error: error,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'rpc': rpc,
    'params': params,
    'viaReplay': viaReplay,
    'label': label,
    'kind': kind,
    'refId': refId,
    'meta': meta,
    'userId': userId,
    'createdAt': createdAt.toIso8601String(),
    'error': error,
  };

  factory OutboxEntry.fromJson(Map<String, dynamic> j) => OutboxEntry(
    id: j['id'] as String,
    rpc: j['rpc'] as String,
    params: (j['params'] as Map).cast<String, dynamic>(),
    viaReplay: j['viaReplay'] as bool? ?? false,
    label: j['label'] as String,
    kind: j['kind'] as String,
    refId: j['refId'] as String?,
    meta: (j['meta'] as Map?)?.cast<String, dynamic>(),
    userId: j['userId'] as String,
    createdAt: DateTime.parse(j['createdAt'] as String),
    error: j['error'] as String?,
  );
}

/// Result of [Outbox.submit]: either the server's answer, or "saved on this
/// device, will be sent when the connection is back".
class OutboxResult {
  final bool queued;
  final dynamic data;
  const OutboxResult._(this.queued, this.data);
  const OutboxResult.done(dynamic data) : this._(false, data);
  const OutboxResult.queued() : this._(true, null);
}

/// Queue of admin writes made while offline. A write is first tried
/// directly; if the server can't be reached it is stored on the device and
/// sent, in order, as soon as a request gets through again (checked on every
/// successful request and every 20 seconds).
///
/// Order matters (an order confirmed then marked prepared), so while
/// anything is waiting, new writes queue behind it instead of jumping ahead.
class Outbox extends ChangeNotifier {
  Outbox._();
  static final instance = Outbox._();

  static const _storeKey = 'outbox.v1';

  OfflineStore? _store;
  SupabaseClient? _client;
  List<OutboxEntry> _all = [];
  bool _syncing = false;
  Timer? _timer;
  final _synced = StreamController<void>.broadcast();

  /// Fires after a sync sent at least one entry — screens refresh then.
  Stream<void> get onSynced => _synced.stream;

  bool get isSyncing => _syncing;

  Future<void> init(SupabaseClient client, OfflineStore store) async {
    _client = client;
    _store = store;
    try {
      final raw = await store.read(_storeKey);
      if (raw != null) {
        _all = (jsonDecode(raw) as List)
            .map(
              (e) => OutboxEntry.fromJson((e as Map).cast<String, dynamic>()),
            )
            .toList();
      }
    } catch (_) {
      _all = [];
    }
    NetworkStatus.instance.addListener(() {
      if (NetworkStatus.instance.isOnline) unawaited(sync());
    });
    client.auth.onAuthStateChange.listen((_) => notifyListeners());
    _timer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (pending.isNotEmpty) unawaited(sync());
    });
    if (pending.isNotEmpty) unawaited(sync());
  }

  String? get _userId => _client?.auth.currentUser?.id;

  /// The signed-in user's entries — another account's queued work on a
  /// shared device is neither shown nor sent under this session.
  List<OutboxEntry> get entries =>
      _all.where((e) => e.userId == _userId).toList(growable: false);

  List<OutboxEntry> get pending =>
      entries.where((e) => !e.failed).toList(growable: false);

  List<OutboxEntry> get failed =>
      entries.where((e) => e.failed).toList(growable: false);

  List<OutboxEntry> pendingOf(String kind, {String? refId}) => pending
      .where((e) => e.kind == kind && (refId == null || e.refId == refId))
      .toList(growable: false);

  /// Runs [rpc] now, or queues it if the server can't be reached. Server
  /// errors are thrown as [AppException] exactly as a direct call would.
  Future<OutboxResult> submit({
    required String rpc,
    required Map<String, dynamic> params,
    required String label,
    required String kind,
    String? refId,
    Map<String, dynamic>? meta,
    bool viaReplay = false,
    String? requestId,
  }) async {
    final userId = _userId;
    if (_client == null || userId == null) {
      throw const AppException('انتهت الجلسة، سجِّل الدخول مرة أخرى');
    }
    final entry = OutboxEntry(
      id: requestId ?? const Uuid().v4(),
      rpc: rpc,
      params: params,
      viaReplay: viaReplay,
      label: label,
      kind: kind,
      refId: refId,
      meta: meta,
      userId: userId,
      createdAt: DateTime.now(),
    );

    if (pending.isNotEmpty) {
      await _add(entry);
      await sync();
      // Sent along with the backlog: report it as done (or as the server's
      // refusal) rather than "saved offline".
      final after = _all.where((e) => e.id == entry.id).firstOrNull;
      if (after == null) return const OutboxResult.done(null);
      if (after.failed) {
        await discard(after);
        throw AppException(after.error!);
      }
      return const OutboxResult.queued();
    }
    try {
      return OutboxResult.done(await _send(entry));
    } catch (e) {
      if (isNetworkError(e)) {
        await _add(entry);
        return const OutboxResult.queued();
      }
      throw AppException.from(e);
    }
  }

  Future<dynamic> _send(OutboxEntry e) async {
    if (!e.viaReplay) return _client!.rpc(e.rpc, params: e.params);
    final res = await _client!.rpc(
      'rpc_replay',
      params: {'p_request_id': e.id, 'p_rpc': e.rpc, 'p_params': e.params},
    );
    return res is Map ? res['result'] : null;
  }

  /// Sends everything waiting, oldest first. Stops at the first connection
  /// failure (the rest would fail the same way); a server rejection marks
  /// that entry failed and moves on.
  Future<void> sync() async {
    if (_syncing || _client == null || _userId == null) return;
    _syncing = true;
    notifyListeners();
    var sent = 0;
    try {
      for (final entry in pending) {
        try {
          await _send(entry);
          _all.removeWhere((e) => e.id == entry.id);
          sent++;
          await _persist();
          notifyListeners();
        } catch (e) {
          if (isNetworkError(e)) break;
          _replace(entry.withError(AppException.from(e).messageAr));
          await _persist();
          notifyListeners();
        }
      }
    } finally {
      _syncing = false;
      notifyListeners();
      if (sent > 0) _synced.add(null);
    }
  }

  Future<void> retry(OutboxEntry entry) async {
    _replace(entry.withError(null));
    await _persist();
    notifyListeners();
    await sync();
  }

  Future<void> discard(OutboxEntry entry) async {
    _all.removeWhere((e) => e.id == entry.id);
    await _persist();
    notifyListeners();
  }

  Future<void> _add(OutboxEntry entry) async {
    _all.add(entry);
    await _persist();
    notifyListeners();
  }

  void _replace(OutboxEntry entry) {
    final i = _all.indexWhere((e) => e.id == entry.id);
    if (i >= 0) _all[i] = entry;
  }

  Future<void> _persist() async {
    await _store?.write(
      _storeKey,
      jsonEncode(_all.map((e) => e.toJson()).toList()),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _synced.close();
    super.dispose();
  }
}
