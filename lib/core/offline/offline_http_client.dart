import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'network_status.dart';
import 'offline_store.dart';

/// The HTTP client handed to Supabase. Every successful read from the REST
/// API (a `.select()`, or one of the read-only RPCs below) is stored; when a
/// later read of the same thing can't reach the server, the stored copy is
/// returned instead, so every screen opens with the last data it saw.
///
/// Writes are not handled here — see [Outbox], which queues them.
///
/// Cache entries are keyed by the signed-in user as well as the request, so
/// one account never sees another's data offline on a shared device.
class OfflineHttpClient extends http.BaseClient {
  final http.Client _inner;
  final OfflineStore _store;

  OfflineHttpClient(this._store, [http.Client? inner])
    : _inner = inner ?? http.Client();

  /// RPCs that only read. Their responses are cached like a select.
  static bool _isReadOnlyRpc(String name) =>
      name.startsWith('rpc_get_') ||
      name.startsWith('rpc_my_') ||
      name == 'rpc_effective_prices' ||
      name == 'rpc_browse_products' ||
      name == 'rpc_offer_products' ||
      name == 'rpc_check_service_availability';

  /// A read that hangs on a bad connection should fall back to the cache
  /// rather than leave the screen spinning.
  static const _readTimeout = Duration(seconds: 15);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final key = _cacheKey(request);
    if (key == null) {
      try {
        final response = await _inner.send(request);
        NetworkStatus.instance.markOnline();
        return response;
      } catch (e) {
        if (isNetworkError(e)) NetworkStatus.instance.markOffline();
        rethrow;
      }
    }

    try {
      final streamed = await _inner.send(request).timeout(_readTimeout);
      NetworkStatus.instance.markOnline();
      final bytes = await streamed.stream.toBytes();
      if (streamed.statusCode >= 200 && streamed.statusCode < 300) {
        unawaited(_save(key, streamed, bytes));
      }
      return _response(request, streamed.statusCode, streamed.headers, bytes);
    } catch (e) {
      if (!isNetworkError(e)) rethrow;
      NetworkStatus.instance.markOffline();
      final cached = await _load(key);
      if (cached == null) rethrow;
      return cached(request);
    }
  }

  String? _cacheKey(http.BaseRequest request) {
    final path = request.url.path;
    if (!path.contains('/rest/v1/')) return null;
    String? body;
    if (request.method == 'GET') {
      body = '';
    } else if (request.method == 'POST' && path.contains('/rest/v1/rpc/')) {
      if (!_isReadOnlyRpc(path.split('/').last)) return null;
      body = request is http.Request ? request.body : null;
      if (body == null) return null;
    } else {
      return null;
    }
    final h = request.headers;
    String header(String name) =>
        h[name] ?? h[name.toLowerCase()] ?? h[_titleCase(name)] ?? '';
    return 'cache:${_userOf(header('Authorization'))}|${request.method}|'
        '${request.url}|${header('Accept')}|${header('Prefer')}|'
        '${header('Range')}|$body';
  }

  static String _titleCase(String s) => s
      .split('-')
      .map((p) => p.isEmpty ? p : p[0].toUpperCase() + p.substring(1))
      .join('-');

  /// The `sub` claim of the bearer token, or 'anon'.
  static String _userOf(String authorization) {
    try {
      final token = authorization.replaceFirst(
        RegExp('^Bearer ', caseSensitive: false),
        '',
      );
      final parts = token.split('.');
      if (parts.length != 3) return 'anon';
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final sub = (jsonDecode(payload) as Map<String, dynamic>)['sub'];
      if (sub is String && sub.isNotEmpty) return sub;
    } catch (_) {}
    return 'anon';
  }

  Future<void> _save(
    String key,
    http.StreamedResponse response,
    List<int> bytes,
  ) async {
    try {
      await _store.write(
        key,
        jsonEncode({
          'status': response.statusCode,
          'headers': {
            for (final e in response.headers.entries)
              if (e.key == 'content-type' || e.key == 'content-range')
                e.key: e.value,
          },
          'body': utf8.decode(bytes, allowMalformed: true),
        }),
      );
    } catch (_) {
      // Caching is best-effort; never fail a request over it.
    }
  }

  Future<http.StreamedResponse Function(http.BaseRequest)?> _load(
    String key,
  ) async {
    final raw = await _store.read(key);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final bytes = utf8.encode(map['body'] as String);
      final headers = (map['headers'] as Map).cast<String, String>();
      return (request) => _response(request, map['status'] as int, {
        ...headers,
        'x-offline-cache': '1',
      }, bytes);
    } catch (_) {
      return null;
    }
  }

  http.StreamedResponse _response(
    http.BaseRequest request,
    int status,
    Map<String, String> headers,
    List<int> bytes,
  ) => http.StreamedResponse(
    Stream.value(bytes),
    status,
    contentLength: bytes.length,
    request: request,
    headers: headers,
  );

  @override
  void close() => _inner.close();
}
