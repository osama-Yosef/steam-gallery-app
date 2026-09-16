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
//   4) Phase 0.5 probes (0029/0030) — read-only: no cost price reachable by a
//      customer, internal SECURITY DEFINER helpers not callable by a customer
//      or by anon, phone not self-editable.
//   5) [optional, --run-order-discount-test --product-id=<uuid>] A customer
//      cannot discount their own order through the RPC payload. This DOES
//      create one real pending order — cancel it from the admin app after.
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
  await _phase05Probe(customerToken);

  if (a.containsKey('run-order-discount-test')) {
    final productId = a['product-id'];
    if (productId == null) {
      stderr.writeln('--run-order-discount-test needs --product-id.');
      exit(2);
    }
    await _orderDiscountTest(customerToken, productId);
  }

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

Future<void> _phase05Probe(String token) async {
  print('== 4) Phase 0.5 probes (0029/0030) ==');

  // RLS filters a blocked SELECT to an empty list; a revoked column is a 4xx.
  bool emptyOrDenied(HttpClientResponseLike res) {
    if (res.statusCode >= 400) return true;
    final body = jsonDecode(res.body);
    return body is List && body.isEmpty;
  }

  final costQueries = {
    'products.cost_price': '/rest/v1/products?select=id,cost_price&limit=1',
    'order_items.unit_cost_snapshot': '/rest/v1/order_items?select=id,unit_cost_snapshot&limit=1',
    'sale_items.unit_cost_snapshot': '/rest/v1/sale_items?select=id,unit_cost_snapshot&limit=1',
    'daily_sales_summary.cogs': '/rest/v1/daily_sales_summary?select=day,cogs&limit=1',
  };
  for (final entry in costQueries.entries) {
    final res = await _restGet(entry.value, token);
    _report('customer cannot read `${entry.key}`', emptyOrDenied(res), extra: 'got ${res.statusCode}: ${res.body}');
  }

  // The safe views must still work for the customer (empty is fine for a
  // customer with no orders; an error is not).
  for (final view in ['order_items_display', 'sale_items_display', 'products_public']) {
    final res = await _restGet('/rest/v1/$view?select=*&limit=1', token);
    final rows = res.statusCode == 200 ? jsonDecode(res.body) : null;
    final noCost = rows is List &&
        rows.every((r) => (r as Map).keys.every((k) => !k.toString().contains('cost')));
    _report('customer can read `$view` without any cost column', res.statusCode == 200 && noCost,
        extra: 'got ${res.statusCode}: ${res.body}');
  }

  const bogus = '00000000-0000-0000-0000-000000000000';
  final internal = <String, Map<String, dynamic>>{
    'notify_user': {'p_user_id': bogus, 'p_type': 'probe', 'p_title': 'probe', 'p_body': 'probe', 'p_data': {}},
    'notify_all_admins': {'p_type': 'probe', 'p_title': 'probe', 'p_body': 'probe', 'p_data': {}},
    'post_technician_supply': {'p_supply_id': bogus},
  };
  for (final entry in internal.entries) {
    final asCustomer = await _restPost('/rest/v1/rpc/${entry.key}', token, entry.value);
    _report('customer cannot call internal `${entry.key}`', asCustomer.statusCode >= 400,
        extra: 'got ${asCustomer.statusCode}: ${asCustomer.body}');
    // Sending the publishable key as the bearer token makes the request anon.
    final asAnon = await _restPost('/rest/v1/rpc/${entry.key}', anonKey, entry.value);
    _report('anon cannot call internal `${entry.key}`', asAnon.statusCode >= 400,
        extra: 'got ${asAnon.statusCode}: ${asAnon.body}');
  }

  final userId = await _getUserId(token);
  final patch = await _patch(
    '/rest/v1/users?id=eq.$userId',
    headers: {
      'apikey': anonKey,
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'Prefer': 'return=representation',
    },
    body: {'phone': '+200000000000'},
  );
  _report('customer cannot change their own phone', patch.statusCode >= 400,
      extra: 'got ${patch.statusCode}: ${patch.body}');

  // Phase 2 (0031). This script signs in with a password, so its session is
  // exactly the kind that must NOT be able to claim a verified phone.
  final selfVerify = await _patch(
    '/rest/v1/users?id=eq.$userId',
    headers: {
      'apikey': anonKey,
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: {'phone_verified_at': DateTime.now().toUtc().toIso8601String()},
  );
  _report('customer cannot set phone_verified_at directly', selfVerify.statusCode >= 400,
      extra: 'got ${selfVerify.statusCode}: ${selfVerify.body}');
  final markVerified = await _restPost('/rest/v1/rpc/rpc_mark_phone_verified', token, {});
  _report('a password session cannot mark the phone verified',
      markVerified.statusCode >= 400 && markVerified.body.contains('OTP_SESSION_REQUIRED'),
      extra: 'got ${markVerified.statusCode}: ${markVerified.body}');
  final flip = await _restPost('/rest/v1/rpc/rpc_admin_set_setting', token,
      {'p_key': 'require_verified_phone', 'p_value': false});
  _report('customer cannot change auth settings', flip.statusCode >= 400,
      extra: 'got ${flip.statusCode}: ${flip.body}');

  // Phase 3 (0032). Addresses are RPC-only; coverage is admin-only.
  final cities = await _restGet('/rest/v1/cities?select=id,center_latitude,center_longitude&limit=1', token);
  final cityRows = cities.statusCode == 200 ? jsonDecode(cities.body) as List : const [];
  if (cityRows.isEmpty) {
    print('  (skipping address probes — no active city visible)');
  } else {
    final city = cityRows.first as Map;
    final directAddress = await _restPost('/rest/v1/customer_addresses', token, {
      'customer_id': userId,
      'country_id': city['id'],
      'city_id': city['id'],
      'label': 'probe',
      'address_line': 'hardening probe',
      'latitude': city['center_latitude'],
      'longitude': city['center_longitude'],
    });
    _report('customer cannot insert an address around the RPC', directAddress.statusCode >= 400,
        extra: 'got ${directAddress.statusCode}: ${directAddress.body}');
    final area = await _restPost('/rest/v1/service_areas', token, {
      'city_id': city['id'],
      'name_ar': 'probe',
      'center_latitude': city['center_latitude'],
      'center_longitude': city['center_longitude'],
      'radius_km': 50,
    });
    _report('customer cannot create a service area', area.statusCode >= 400,
        extra: 'got ${area.statusCode}: ${area.body}');
  }
  final anonCities = await _restGet('/rest/v1/cities?select=id&limit=1', anonKey);
  _report('anon cannot read coverage tables',
      anonCities.statusCode >= 400 || (jsonDecode(anonCities.body) is List && (jsonDecode(anonCities.body) as List).isEmpty),
      extra: 'got ${anonCities.statusCode}: ${anonCities.body}');

  // Phase 5 (0033). Marketing content is admin-managed; offers never price.
  final offer = await _restPost('/rest/v1/offers', token, {'title': 'probe', 'is_active': true});
  _report('customer cannot create an offer', offer.statusCode >= 400,
      extra: 'got ${offer.statusCode}: ${offer.body}');
  final banner = await _restPost('/rest/v1/home_banners', token,
      {'title': 'probe', 'image_url': 'https://example.invalid/x.jpg', 'is_active': true});
  _report('customer cannot create a banner', banner.statusCode >= 400,
      extra: 'got ${banner.statusCode}: ${banner.body}');
  final anonBanners = await _restGet('/rest/v1/home_banners?select=id&limit=1', anonKey);
  _report('anon cannot read banners',
      anonBanners.statusCode >= 400 || (jsonDecode(anonBanners.body) is List && (jsonDecode(anonBanners.body) as List).isEmpty),
      extra: 'got ${anonBanners.statusCode}: ${anonBanners.body}');

  // Phase 6 (0034). Paginated browse: no cost column, sort whitelist, caps.
  final browse = await _restPost('/rest/v1/rpc/rpc_browse_products', token, {'p_limit': 5});
  final browseRows = browse.statusCode == 200 ? jsonDecode(browse.body) as List : const [];
  _report('customer browses the catalogue without any cost column',
      browse.statusCode == 200 &&
          browseRows.every((r) => !(r as Map).keys.any((k) => k.toString().contains('cost'))),
      extra: 'got ${browse.statusCode}: ${browse.body}');
  final badSort = await _restPost('/rest/v1/rpc/rpc_browse_products', token, {'p_sort': 'cost_price'});
  _report('browse refuses an unknown sort', badSort.statusCode >= 400 && badSort.body.contains('INVALID_SORT'),
      extra: 'got ${badSort.statusCode}: ${badSort.body}');
  final bigPage = await _restPost('/rest/v1/rpc/rpc_browse_products', token, {'p_limit': 1000});
  _report('browse refuses pages over 50', bigPage.statusCode >= 400,
      extra: 'got ${bigPage.statusCode}: ${bigPage.body}');
  final anonBrowse = await _restPost('/rest/v1/rpc/rpc_browse_products', anonKey, {});
  _report('anon cannot browse', anonBrowse.statusCode >= 400,
      extra: 'got ${anonBrowse.statusCode}: ${anonBrowse.body}');

  // Phase 7 (0035). Server-side cart: no direct writes, no cost column, and
  // the server (not Flutter) enforces the per-line quantity cap.
  final cartProduct = await _restGet('/rest/v1/products_public?select=id&limit=1', token);
  final cartProductRows = cartProduct.statusCode == 200 ? jsonDecode(cartProduct.body) as List : const [];
  if (cartProductRows.isEmpty) {
    print('  SKIPPED cart checks — no product in products_public to add.');
  } else {
    final pid = cartProductRows.first['id'] as String;
    final addToCart = await _restPost('/rest/v1/rpc/rpc_cart_add_item', token,
        {'p_product_id': pid, 'p_quantity': 1});
    _report('customer can add to their own cart', addToCart.statusCode == 200,
        extra: 'got ${addToCart.statusCode}: ${addToCart.body}');
    final cartBody = addToCart.statusCode == 200 ? jsonDecode(addToCart.body) as Map : const {};
    final cartItems = (cartBody['items'] as List?) ?? const [];
    _report('cart items carry no cost column',
        cartItems.every((r) => !(r as Map).keys.any((k) => k.toString().contains('cost'))),
        extra: cartBody.toString());
    final directInsert = await _restPost('/rest/v1/cart_items', token,
        {'customer_id': await _getUserId(token), 'product_id': pid, 'quantity': 1, 'price_seen': 0});
    _report('customer cannot insert into cart_items directly', directInsert.statusCode >= 400,
        extra: 'got ${directInsert.statusCode}: ${directInsert.body}');
    final overCap = await _restPost('/rest/v1/rpc/rpc_cart_set_item', token,
        {'p_product_id': pid, 'p_quantity': 999});
    _report('cart quantity above the server cap is refused',
        overCap.statusCode >= 400 && overCap.body.contains('INVALID_QUANTITY'),
        extra: 'got ${overCap.statusCode}: ${overCap.body}');
    final anonCart = await _restPost('/rest/v1/rpc/rpc_get_my_cart', anonKey, {});
    _report('anon cannot read a cart', anonCart.statusCode >= 400,
        extra: 'got ${anonCart.statusCode}: ${anonCart.body}');
    // Leave no residue from this probe run.
    await _restPost('/rest/v1/rpc/rpc_cart_clear', token, {});
  }
  print('');
}

Future<void> _orderDiscountTest(String token, String productId) async {
  print('== 5) Order pricing: a payload discount must be ignored ==');
  print('  WARNING: creates one real pending order — cancel it from the admin app.');

  final productRes = await _restGet('/rest/v1/products_public?select=selling_price&id=eq.$productId', token);
  final products = jsonDecode(productRes.body) as List;
  if (products.isEmpty) {
    print('  SKIPPED — product $productId is not in products_public.');
    return;
  }
  final price = (products.first['selling_price'] as num).toDouble();

  final userId = await _getUserId(token);
  final create = await _restPost('/rest/v1/rpc/rpc_create_order', token, {
    'p_customer_id': userId,
    'p_items': [
      {'product_id': productId, 'quantity': 1, 'discount': 999999},
    ],
    'p_delivery_address': 'hardening probe',
    'p_latitude': null,
    'p_longitude': null,
    'p_notes': 'hardening discount probe — cancel me',
    'p_client_request_id': _fakeUuid('d'),
  });
  if (create.statusCode >= 300) {
    _report('order creation succeeded for the probe', false, extra: 'got ${create.statusCode}: ${create.body}');
    return;
  }
  final orderId = jsonDecode(create.body) as String;
  final orderRes = await _restGet('/rest/v1/orders?select=total&id=eq.$orderId', token);
  final total = ((jsonDecode(orderRes.body) as List).first['total'] as num).toDouble();
  _report('order total uses the database price ($price), got $total', total == price);
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

Future<HttpClientResponseLike> _patch(String path,
    {required Map<String, String> headers, required Map<String, dynamic> body}) async {
  final req = await client.patchUrl(Uri.parse('$baseUrl$path'));
  headers.forEach(req.headers.set);
  req.write(jsonEncode(body));
  final res = await req.close();
  final resBody = await res.transform(utf8.decoder).join();
  return HttpClientResponseLike(res.statusCode, resBody);
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
