import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A stand-in for the Supabase server: every REST read of a table, view or
/// RPC is answered from [tables] / [rpcs] by name (an empty list when there
/// is nothing for it), so the app's real repositories, row parsing and
/// providers run unchanged against known data.
class FakeBackend {
  FakeBackend({
    Map<String, List<Map<String, dynamic>>>? tables,
    Map<String, Object?>? rpcs,
  }) : tables = tables ?? {},
       rpcs = rpcs ?? {};

  final Map<String, List<Map<String, dynamic>>> tables;
  final Map<String, Object?> rpcs;

  /// Every request the app made, as "GET table" / "POST rpc/name".
  final requests = <String>[];

  late final SupabaseClient client = SupabaseClient(
    'https://fake.supabase.co',
    'anon-key',
    authOptions: const AuthClientOptions(autoRefreshToken: false),
    httpClient: MockClient(_handle),
  );

  /// Signs [client] in as [userId] without a server round trip, so the
  /// router treats the session as live.
  Future<void> signIn(String userId) => client.auth.setInitialSession(
    jsonEncode({
      'access_token': 'test-token',
      'token_type': 'bearer',
      'refresh_token': 'r',
      'user': {
        'id': userId,
        'aud': 'authenticated',
        'app_metadata': <String, dynamic>{},
        'user_metadata': <String, dynamic>{},
        'created_at': '2026-01-01T00:00:00Z',
      },
    }),
  );

  /// Closes the realtime channels screens opened, so no reconnect timer
  /// outlives the test.
  /// Not awaited: leaving a channel waits for a server reply that never
  /// comes.
  void close() {
    unawaited(client.removeAllChannels());
    unawaited(client.realtime.disconnect());
  }

  Future<http.Response> _handle(http.Request req) async {
    final segments = req.url.pathSegments;
    final restAt = segments.indexOf('v1');
    if (restAt < 0 || segments.first != 'rest') {
      requests.add('${req.method} ${req.url.path}');
      return _json(req, <String, dynamic>{});
    }
    final rest = segments.sublist(restAt + 1);
    if (rest.first == 'rpc') {
      final name = rest[1];
      requests.add('RPC $name');
      return _json(req, rpcs.containsKey(name) ? rpcs[name] : null);
    }
    final name = rest.first;
    requests.add('${req.method} $name');
    if (req.method != 'GET' && req.method != 'HEAD') {
      return _json(req, <Object>[]);
    }
    final rows = _filter(tables[name] ?? const [], req.url.queryParameters);
    final wantsObject = (req.headers['accept'] ?? '').contains(
      'vnd.pgrst.object',
    );
    if (wantsObject) {
      if (rows.isEmpty) {
        return http.Response(
          jsonEncode({
            'code': 'PGRST116',
            'message': 'JSON object requested, multiple (or no) rows returned',
          }),
          406,
          request: req,
          headers: {'content-type': 'application/json'},
        );
      }
      return _json(req, rows.first);
    }
    return _json(req, rows, count: rows.length);
  }

  /// Applies the `id=eq.x`-style equality filters a detail screen sends, so
  /// "the order with this id" finds that order; every other filter is
  /// ignored (the lists show all of a table's rows).
  List<Map<String, dynamic>> _filter(
    List<Map<String, dynamic>> rows,
    Map<String, String> query,
  ) {
    var out = rows;
    for (final entry in query.entries) {
      if (!entry.value.startsWith('eq.')) continue;
      final value = entry.value.substring(3);
      if (!rows.any((r) => r.containsKey(entry.key))) continue;
      out = [
        for (final r in out)
          if ('${r[entry.key]}' == value) r,
      ];
    }
    return out;
  }

  http.Response _json(http.Request req, Object? body, {int? count}) =>
      http.Response.bytes(
        utf8.encode(jsonEncode(body)),
        200,
        request: req,
        headers: {
          'content-type': 'application/json; charset=utf-8',
          if (count != null)
            'content-range': count == 0 ? '*/0' : '0-${count - 1}/$count',
        },
      );
}
