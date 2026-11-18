import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:steam_gallery_app/core/errors/app_exception.dart';
import 'package:steam_gallery_app/features/auth/data/models/app_user.dart';
import 'package:steam_gallery_app/features/auth/data/repositories/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'helpers/test_outbox.dart';

/// The signed-in profile decides which screens the app shows. With no
/// connection and no saved copy, the router used to send the user to login,
/// which needs the internet too: locked out until the connection was back.
void main() {
  const row = {
    'id': 'u1',
    'role': 'technician',
    'full_name': 'حسن',
    'phone': '01000000000',
    'is_active': true,
  };

  late bool online;
  late bool refuse;
  late MemoryStore store;
  late SupabaseClient client;

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

  setUp(() {
    online = true;
    refuse = false;
    store = MemoryStore();
    client = SupabaseClient(
      'https://fake.supabase.co',
      'anon-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((req) async {
        if (!online) throw http.ClientException('Failed host lookup');
        if (refuse) {
          return http.Response(
            jsonEncode({'message': 'permission denied', 'code': '42501'}),
            403,
            request: req,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response.bytes(
          utf8.encode(jsonEncode(row)),
          200,
          request: req,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );
  });

  test('offline: the last profile loaded is used', () async {
    await signIn('u1');
    final repo = SupabaseAuthRepository(client, store: store);
    final first = await repo.getMyProfile();
    expect(first?.role, AppRole.technician);
    await Future<void>.delayed(Duration.zero); // the save is not awaited

    online = false;
    final offline = await repo.getMyProfile();
    expect(offline, first);
  });

  test('offline with nothing saved: a network AppException', () async {
    await signIn('u1');
    online = false;
    final repo = SupabaseAuthRepository(client, store: store);
    await expectLater(
      repo.getMyProfile(),
      throwsA(
        isA<AppException>().having((e) => e.isNetwork, 'isNetwork', true),
      ),
    );
  });

  test("another account's saved profile is never used", () async {
    await signIn('u1');
    final repo = SupabaseAuthRepository(client, store: store);
    await repo.getMyProfile();
    await Future<void>.delayed(Duration.zero);

    await signIn('u2');
    online = false;
    await expectLater(repo.getMyProfile(), throwsA(isA<AppException>()));
  });

  test('a server refusal is not answered from the saved copy', () async {
    await signIn('u1');
    final repo = SupabaseAuthRepository(client, store: store);
    await repo.getMyProfile();
    await Future<void>.delayed(Duration.zero);

    refuse = true;
    await expectLater(
      repo.getMyProfile(),
      throwsA(
        isA<AppException>().having((e) => e.isNetwork, 'isNetwork', false),
      ),
    );
  });
}
