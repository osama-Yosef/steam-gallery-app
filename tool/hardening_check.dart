// tool/hardening_check.dart
//
// Module 15 (Hardening) live-verification script — see
// docs/07-implementation-roadmap.md. Talks to your real Supabase project
// over plain HTTP (no extra pubspec dependency needed: dart:io + dart:convert
// only) to prove, against the ACTUAL deployed RLS policies and RPC
// functions, that:
//
//   1) A customer session cannot read admin-only tables directly (RLS probe
//      — read-only, no side effects).
//   2) A customer session cannot call admin-only RPC functions directly
//      (RLS/RPC probe — read-only, no side effects).
//   3) [optional, --run-race-test] Two concurrent sales of the same last
//      unit of stock cannot both succeed (race condition test — this DOES
//      mutate real data: it consumes real stock and creates a real sale
//      row. Only run it against a disposable test product/technician).
//
// Usage:
//   dart run tool/hardening_check.dart \
//     --url=https://xxxx.supabase.co \
//     --anon-key=sb_publishable_xxx \
//     --customer-phone=01099998888 --customer-password=xxxxxxxx \
//     [--technician-phone=01011112222 --technician-password=xxxxxxxx \
//      --product-id=<uuid> --run-race-test]
//
// Exit code 0 = every check passed (i.e. every unauthorized attempt was
// correctly rejected, and the race condition was correctly prevented).
// Exit code 1 = at least one check FAILED — meaning a real security or
// data-integrity hole was found and must be fixed before going live.

import 'dart:convert';
import 'dart:io';

late String baseUrl;
late String anonKey;
final client = HttpClient();

int passCount = 0;
int failCount = 0;

Future<void> main(List<String> args) async {
  final a = _parseArgs(args);
  baseUrl = (a['url'] ?? '').replaceAll(RegExp(r'/+$'), '');
  anonKey = a['anon-key'] ?? '';

  if (baseUrl.isEmpty || anonKey.isEmpty) {
    stderr.writeln('Missing --url or --anon-key. See file header for usage.');
    exit(2);
  }

  final customerPhone = a['customer-phone'];
  final customerPassword = a['customer-password'];
  if (customerPhone == null || customerPassword == null) {
    stderr.writeln('Missing --customer-phone / --customer-password (needed for every check).');
    exit(2);
  }

  print('== Signing in as customer $customerPhone ==');
  final customerToken = await _signIn(customerPhone, customerPassword);
  print('  ok, got session\n');

  await _rlsProbe(customerToken);
  await _rpcProbe(customerToken);

  if (a.containsKey('run-race-test')) {
    final techPhone = a['technician-phone'];
    final techPassword = a['technician-password'];
    final productId = a['product-id'];
    if (techPhone == null || techPassword == null || productId == null) {
      stderr.writeln(
          '--run-race-test needs --technician-phone, --technician-password and --product-id.');
      exit(2);
    }
    print('== Signing in as technician $techPhone ==');
    final techToken = await _signIn(techPhone, techPassword);
    final techUserId = await _getUserId(techToken);
    print('  ok, got session (user id: $techUserId)\n');
    await _raceConditionTest(techToken, techUserId, productId);
  } else {
    print('(skipping race-condition test — pass --run-race-test to include it)\n');
  }

  print('== Summary: $passCount passed, $failCount failed ==');
  exit(failCount == 0 ? 0 : 1);
}

// ----------------------------------------------------------------------------
Future<void> _rlsProbe(String token) async {
  print('== 1) RLS probe: a customer session must NOT read admin-only tables ==');
  final adminOnlyTables = [
    'cash_transactions',
    'technician_bag_stock',
    'audit_logs',
    'expenses',
    'warehouse_stock',
  ];
  for (final table in adminOnlyTables) {
    final res = await _restGet('/rest/v1/$table?select=*&limit=1', token);
    // RLS on Supabase returns 200 with an EMPTY array for a blocked SELECT
    // (not a 403) — the policy just filters every row out.
    final body = jsonDecode(res.body);
    final blocked = res.statusCode != 200 || (body is List && body.isEmpty);
    _report('customer cannot read `$table`', blocked, extra: 'got ${res.statusCode}: ${res.body}');
  }
  print('');
}

Future<void> _rpcProbe(String token) async {
  print('== 2) RPC probe: a customer session must NOT call admin-only functions ==');
  final calls = <String, Map<String, dynamic>>{
    'rpc_record_expense': {
      'p_category_id': '00000000-0000-0000-0000-000000000000',
      'p_amount': 1,
      'p_expense_date': null,
      'p_notes': 'hardening probe — should be rejected',
      'p_attachment_url': null,
    },
    'rpc_admin_set_active': {
      'p_user_id': '00000000-0000-0000-0000-000000000000',
      'p_is_active': false,
    },
    'rpc_issue_stock_to_technician': {
      'p_technician_id': '00000000-0000-0000-0000-000000000000',
      'p_items': [],
      'p_notes': 'hardening probe',
    },
  };
  for (final entry in calls.entries) {
    final res = await _restPost('/rest/v1/rpc/${entry.key}', token, entry.value);
    final rejected = res.statusCode == 400 || res.statusCode == 403 || res.statusCode >= 400;
    _report('customer cannot call `${entry.key}`', rejected, extra: 'got ${res.statusCode}: ${res.body}');
  }
  print('');
}

Future<void> _raceConditionTest(String techToken, String techUserId, String productId) async {
  print('== 3) Race condition: two concurrent sales of the same unit ==');
  print('  WARNING: this mutates real data (creates real sale rows, consumes real stock).');

  final stockRes = await _restGet(
    "/rest/v1/technician_bag_stock?select=quantity,technician_bag_id&product_id=eq.$productId",
    techToken,
  );
  final stockRows = jsonDecode(stockRes.body) as List;
  if (stockRows.isEmpty || (stockRows.first['quantity'] as int) < 1) {
    print('  SKIPPED — technician has no stock of product $productId in their bag.');
    return;
  }
  final qty = stockRows.first['quantity'] as int;
  print('  Technician currently has $qty unit(s) of this product. Firing 2 concurrent sales of $qty each...');

  Map<String, dynamic> saleBody(String clientRequestId) => {
        'p_technician_id': techUserId,
        'p_customer_id': null,
        'p_customer_name': 'Hardening Test',
        'p_customer_phone': null,
        'p_items': [
          {'product_id': productId, 'quantity': qty}
        ],
        'p_payment_method': 'cash',
        'p_discount': 0,
        'p_paid_amount': 0,
        'p_client_request_id': clientRequestId,
        'p_notes': 'hardening race-condition probe',
      };

  final results = await Future.wait<HttpClientResponseLike>([
    _restPost('/rest/v1/rpc/rpc_technician_sale', techToken, saleBody(_fakeUuid('a'))),
    _restPost('/rest/v1/rpc/rpc_technician_sale', techToken, saleBody(_fakeUuid('b'))),
  ]);

  final successes = results.where((r) => r.statusCode < 300).length;
  final failures = results.where((r) => r.statusCode >= 300).length;

  print('  Result: $successes succeeded, $failures failed.');
  for (final r in results) {
    print('    -> ${r.statusCode}: ${r.body}');
  }
  _report('exactly one of the two concurrent sales succeeded (no oversell)', successes == 1);
}

// ----------------------------------------------------------------------------
void _report(String label, bool ok, {String? extra}) {
  if (ok) {
    passCount++;
    print('  [PASS] $label');
  } else {
    failCount++;
    print('  [FAIL] $label${extra != null ? ' — $extra' : ''}');
  }
}

Future<String> _signIn(String localPhone, String password) async {
  final phone = _toE164Egypt(localPhone);
  final res = await _post(
    '/auth/v1/token?grant_type=password',
    headers: {'apikey': anonKey, 'Content-Type': 'application/json'},
    body: {'phone': phone, 'password': password},
  );
  if (res.statusCode != 200) {
    stderr.writeln('Sign-in failed for $phone: ${res.statusCode} ${res.body}');
    exit(2);
  }
  final json = jsonDecode(res.body) as Map<String, dynamic>;
  return json['access_token'] as String;
}

/// Deterministic-but-unique fake UUID (v4-shaped, not cryptographically
/// meaningful) for client_request_id — good enough for this one-off probe.
String _fakeUuid(String tag) {
  final micros = DateTime.now().microsecondsSinceEpoch.toRadixString(16).padLeft(12, '0');
  final last12 = micros.substring(micros.length - 12);
  return '00000000-0000-4000-8${tag.codeUnitAt(0).toRadixString(16).padLeft(3, '0')}-$last12';
}

String _toE164Egypt(String local) {
  final digits = local.trim().replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('20')) return '+$digits';
  if (digits.startsWith('0')) return '+20${digits.substring(1)}';
  return '+20$digits';
}

Future<String> _getUserId(String token) async {
  final res = await _get('/auth/v1/user', headers: {'apikey': anonKey, 'Authorization': 'Bearer $token'});
  final json = jsonDecode(res.body) as Map<String, dynamic>;
  return json['id'] as String;
}

Future<HttpClientResponseLike> _restGet(String path, String token) => _get(
      path,
      headers: {'apikey': anonKey, 'Authorization': 'Bearer $token'},
    );

Future<HttpClientResponseLike> _restPost(String path, String token, Map<String, dynamic> body) => _post(
      path,
      headers: {'apikey': anonKey, 'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: body,
    );

class HttpClientResponseLike {
  final int statusCode;
  final String body;
  HttpClientResponseLike(this.statusCode, this.body);
}

Future<HttpClientResponseLike> _get(String path, {required Map<String, String> headers}) async {
  final req = await client.getUrl(Uri.parse('$baseUrl$path'));
  headers.forEach(req.headers.set);
  final res = await req.close();
  final body = await res.transform(utf8.decoder).join();
  return HttpClientResponseLike(res.statusCode, body);
}

Future<HttpClientResponseLike> _post(String path,
    {required Map<String, String> headers, required Map<String, dynamic> body}) async {
  final req = await client.postUrl(Uri.parse('$baseUrl$path'));
  headers.forEach(req.headers.set);
  req.write(jsonEncode(body));
  final res = await req.close();
  final resBody = await res.transform(utf8.decoder).join();
  return HttpClientResponseLike(res.statusCode, resBody);
}

Map<String, String> _parseArgs(List<String> args) {
  final map = <String, String>{};
  for (final a in args) {
    if (!a.startsWith('--')) continue;
    final withoutDashes = a.substring(2);
    final eq = withoutDashes.indexOf('=');
    if (eq == -1) {
      map[withoutDashes] = 'true';
    } else {
      map[withoutDashes.substring(0, eq)] = withoutDashes.substring(eq + 1);
    }
  }
  return map;
}
