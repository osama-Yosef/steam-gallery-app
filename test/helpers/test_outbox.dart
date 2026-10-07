import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:steam_gallery_app/core/offline/network_status.dart';
import 'package:steam_gallery_app/core/offline/offline_store.dart';
import 'package:steam_gallery_app/core/offline/outbox.dart';

/// An [OfflineStore] in memory, for tests.
class MemoryStore implements OfflineStore {
  final data = <String, String>{};

  @override
  Future<String?> read(String key) async => data[key];

  @override
  Future<void> write(String key, String value) async => data[key] = value;

  @override
  Future<void> delete(String key) async => data.remove(key);

  @override
  Future<void> clearCache() async =>
      data.removeWhere((k, _) => k.startsWith('cache:'));
}

/// A fake server for an [Outbox]: records every RPC sent, answers with
/// [reply], and can be switched "offline" (throws a connection error) or
/// made to refuse a call the way Postgres would.
class FakeServer {
  final calls = <({String rpc, Map<String, dynamic> params})>[];
  bool online = true;

  /// RPC name → the exception code the database raises for it (e.g.
  /// 'INSUFFICIENT_STOCK'), surfaced as a PostgrestException.
  final refusals = <String, String>{};
  dynamic reply;

  Future<dynamic> call(String rpc, Map<String, dynamic> params) async {
    if (!online) throw http.ClientException('Failed host lookup');
    calls.add((rpc: rpc, params: params));
    final refusal = refusals[rpc];
    if (refusal != null) throw PostgrestException(message: refusal);
    return reply;
  }
}

/// A real [Outbox] — the same queue logic the app runs — over [server] and
/// an in-memory store, with no retry timer. Signed in as [userId].
Outbox testOutbox({
  FakeServer? server,
  OfflineStore? store,
  String? userId = 'admin-1',
  NetworkStatus? network,
}) {
  final s = server ?? FakeServer();
  return Outbox(
    store: store ?? MemoryStore(),
    rpc: s.call,
    currentUserId: () => userId,
    network: network,
    retryEvery: null,
  );
}
