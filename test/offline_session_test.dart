import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:steam_gallery_app/core/offline/network_status.dart';
import 'package:steam_gallery_app/core/offline/offline_session.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

String _jwt(DateTime exp, {String sub = 'u1'}) {
  String part(Map<String, dynamic> m) =>
      base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');
  return '${part({'alg': 'none'})}.'
      '${part({'sub': sub, 'exp': exp.millisecondsSinceEpoch ~/ 1000})}.sig';
}

const _user = {
  'id': 'u1',
  'app_metadata': <String, dynamic>{},
  'user_metadata': <String, dynamic>{},
  'aud': 'authenticated',
  'created_at': '2026-01-01T00:00:00Z',
};

Map<String, dynamic> _session(String token, String refresh) => {
  'access_token': token,
  'refresh_token': refresh,
  'token_type': 'bearer',
  'expires_in': 3600,
  'user': _user,
};

/// The signed-in session through an internet outage longer than the access
/// token's one-hour life.
void main() {
  late bool online;
  late int refreshCalls;
  late GoTrueClient auth;
  late OfflineSession keeper;
  final expiredToken = _jwt(DateTime.now().subtract(const Duration(hours: 2)));
  final freshToken = _jwt(DateTime.now().add(const Duration(hours: 1)));

  setUp(() async {
    online = false;
    refreshCalls = 0;
    NetworkStatus.instance.markOnline();
    auth = GoTrueClient(
      url: 'https://example.test/auth/v1',
      autoRefreshToken: false,
      httpClient: MockClient((req) async {
        if (!online) throw http.ClientException('Failed host lookup');
        refreshCalls++;
        return http.Response(
          jsonEncode(_session(freshToken, 'r2')),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    // As after an app restart: the stored session's token has run out.
    await auth.setInitialSession(jsonEncode(_session(expiredToken, 'r1')));
    keeper = OfflineSession(auth, checkEvery: null);
  });

  tearDown(() => keeper.dispose());

  test('without it, an expired token blocks every request offline', () async {
    await expectLater(auth.getSession(), throwsA(isA<AuthException>()));
  });

  test('offline: the session stays usable, with its own token', () async {
    await keeper.start();
    final session = await auth.getSession();
    expect(session?.accessToken, expiredToken);
    expect(session?.refreshToken, 'r1');
    expect(auth.currentUser?.id, 'u1');
    expect(NetworkStatus.instance.isOnline, isFalse);
  });

  test('it keeps working on every later check while offline', () async {
    await keeper.start();
    for (var i = 0; i < 3; i++) {
      await keeper.check();
      expect((await auth.getSession())?.accessToken, expiredToken);
    }
  });

  test('back online: the token is renewed for real', () async {
    await keeper.start();
    online = true;
    NetworkStatus.instance.markOnline();
    await keeper.check();
    expect(refreshCalls, 1);
    expect(auth.currentSession?.accessToken, freshToken);
  });

  test('a still-valid token is left alone', () async {
    online = true;
    await auth.setInitialSession(jsonEncode(_session(freshToken, 'r1')));
    await keeper.start();
    expect(refreshCalls, 0);
    expect(auth.currentSession?.accessToken, freshToken);
  });

  test('an expired-token answer is a retry, not a rejection', () {
    expect(
      isExpiredTokenError(
        const PostgrestException(message: 'JWT expired', code: 'PGRST303'),
      ),
      isTrue,
    );
    expect(
      isExpiredTokenError(const PostgrestException(message: 'نفد المخزون')),
      isFalse,
    );
  });
}
