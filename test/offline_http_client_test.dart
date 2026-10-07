import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:steam_gallery_app/core/offline/network_status.dart';
import 'package:steam_gallery_app/core/offline/offline_http_client.dart';

import 'helpers/test_outbox.dart';

String _jwt(String sub) {
  String part(Map<String, dynamic> m) =>
      base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');
  return '${part({'alg': 'none'})}.${part({'sub': sub})}.sig';
}

void main() {
  late MemoryStore store;
  var online = true;
  var calls = 0;

  setUp(() {
    store = MemoryStore();
    online = true;
    calls = 0;
  });

  OfflineHttpClient client() => OfflineHttpClient(
    store,
    MockClient((req) async {
      calls++;
      if (!online) throw http.ClientException('Failed host lookup');
      return http.Response(
        '[{"n":$calls}]',
        200,
        headers: {'content-type': 'application/json'},
      );
    }),
  );

  Future<http.Response> get(
    OfflineHttpClient c,
    String path, {
    String user = 'u1',
  }) => c.get(
    Uri.parse('https://x.supabase.co$path'),
    headers: {'Authorization': 'Bearer ${_jwt(user)}'},
  );

  test('a read made offline gets the last copy seen online', () async {
    final c = client();
    final first = await get(c, '/rest/v1/products?select=*');
    expect(first.body, '[{"n":1}]');
    await Future<void>.delayed(Duration.zero); // let the cache write land

    online = false;
    final offline = await get(c, '/rest/v1/products?select=*');
    expect(offline.statusCode, 200);
    expect(offline.body, '[{"n":1}]');
    expect(offline.headers['x-offline-cache'], '1');
    expect(NetworkStatus.instance.isOnline, isFalse);

    online = true;
    final back = await get(c, '/rest/v1/products?select=*');
    expect(back.body, '[{"n":3}]');
    expect(NetworkStatus.instance.isOnline, isTrue);
  });

  test('nothing cached yet: the connection error still surfaces', () async {
    online = false;
    expect(
      () => get(client(), '/rest/v1/orders?select=*'),
      throwsA(isA<http.ClientException>()),
    );
  });

  test('one account never gets another account\'s cached data', () async {
    final c = client();
    await get(c, '/rest/v1/sales?select=*', user: 'admin-a');
    await Future<void>.delayed(Duration.zero);
    online = false;
    expect(
      () => get(c, '/rest/v1/sales?select=*', user: 'admin-b'),
      throwsA(isA<http.ClientException>()),
    );
  });

  test('write RPCs are never cached or replayed from cache', () async {
    final c = client();
    final uri = Uri.parse(
      'https://x.supabase.co/rest/v1/rpc/rpc_admin_walk_in_sale',
    );
    await c.post(uri, body: '{}');
    await Future<void>.delayed(Duration.zero);
    expect(store.data, isEmpty);
    online = false;
    expect(() => c.post(uri, body: '{}'), throwsA(isA<http.ClientException>()));
  });

  test('read-only RPCs are cached per request body', () async {
    final c = client();
    final uri = Uri.parse(
      'https://x.supabase.co/rest/v1/rpc/rpc_effective_prices',
    );
    await c.post(uri, body: '{"p_product_ids":["a"]}');
    await Future<void>.delayed(Duration.zero);
    online = false;
    final hit = await c.post(uri, body: '{"p_product_ids":["a"]}');
    expect(hit.body, '[{"n":1}]');
    expect(
      () => c.post(uri, body: '{"p_product_ids":["b"]}'),
      throwsA(isA<http.ClientException>()),
    );
  });

  test('a body with newlines and quotes survives the cache intact', () async {
    // A raw newline in the body as well as an escaped one.
    const body = '[{"note":"line 1\\nline \\"2\\""}]\n';
    final c = OfflineHttpClient(
      store,
      MockClient((req) async {
        if (!online) throw http.ClientException('Failed host lookup');
        return http.Response(body, 200);
      }),
    );
    await get(c, '/rest/v1/notes?select=*');
    await Future<void>.delayed(Duration.zero);
    online = false;
    expect((await get(c, '/rest/v1/notes?select=*')).body, body);
  });

  test('entries cached by 1.1.x (one JSON map) are still served', () async {
    final c = client();
    await get(c, '/rest/v1/products?select=*');
    await Future<void>.delayed(Duration.zero);
    final key = store.data.keys.single;
    store.data[key] = jsonEncode({
      'status': 200,
      'headers': {'content-type': 'application/json'},
      'body': '[{"legacy":true}]',
    });
    online = false;
    final hit = await get(c, '/rest/v1/products?select=*');
    expect(hit.body, '[{"legacy":true}]');
    expect(hit.headers['x-offline-cache'], '1');
  });
}
