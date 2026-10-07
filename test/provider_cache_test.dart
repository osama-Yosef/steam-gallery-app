import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:steam_gallery_app/core/offline/network_status.dart';
import 'package:steam_gallery_app/core/offline/outbox.dart';
import 'package:steam_gallery_app/core/supabase/supabase_client_provider.dart';
import 'package:steam_gallery_app/core/utils/provider_cache.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'helpers/test_outbox.dart';

AuthState _signedIn(String id) => AuthState(
  AuthChangeEvent.signedIn,
  Session(
    accessToken: 't',
    tokenType: 'bearer',
    user: User(
      id: id,
      appMetadata: const {},
      userMetadata: const {},
      aud: 'authenticated',
      createdAt: '2026-10-07T00:00:00Z',
    ),
  ),
);

void main() {
  test('refreshOnServerChange: refetches after a write reaches the server, '
      'and when the connection comes back', () async {
    final outbox = testOutbox();
    var fetches = 0;
    final data = FutureProvider.autoDispose<int>((ref) async {
      ref.refreshOnServerChange();
      return ++fetches;
    });
    final container = ProviderContainer(
      overrides: [outboxProvider.overrideWithValue(outbox)],
    );
    addTearDown(container.dispose);
    container.listen(data, (_, _) {});

    expect(await container.read(data.future), 1);

    outbox.markServerChanged();
    await Future<void>.delayed(Duration.zero);
    expect(await container.read(data.future), 2);

    NetworkStatus.instance.markOffline();
    NetworkStatus.instance.markOnline();
    await Future<void>.delayed(Duration.zero);
    expect(await container.read(data.future), 3);
  });

  group('cacheFor', () {
    late StreamController<AuthState> auth;
    late ProviderContainer container;
    var fetches = 0;
    final data = FutureProvider.autoDispose<int>((ref) async {
      ref.cacheFor(
        keep: const Duration(minutes: 5),
        staleAfter: const Duration(milliseconds: 50),
      );
      return ++fetches;
    });

    setUp(() async {
      fetches = 0;
      auth = StreamController<AuthState>.broadcast();
      container = ProviderContainer(
        overrides: [
          authStateChangesProvider.overrideWith((ref) => auth.stream),
        ],
      );
      // The session is known before any screen opens, as in the app.
      container.listen(authStateChangesProvider, (_, _) {});
      auth.add(_signedIn('user-a'));
      await Future<void>.delayed(Duration.zero);
    });

    tearDown(() {
      container.dispose();
      auth.close();
    });

    test(
      'reopening soon after shows the kept data without refetching',
      () async {
        final first = container.listen(data, (_, _) {});
        expect(await container.read(data.future), 1);
        first.close(); // the screen closes
        await Future<void>.delayed(Duration.zero);

        final again = container.listen(data, (_, _) {});
        expect(again.read().value, 1, reason: 'shown at once, no spinner');
        await Future<void>.delayed(Duration.zero);
        expect(fetches, 1);
      },
    );

    test('reopening after staleAfter refreshes in the background', () async {
      final first = container.listen(data, (_, _) {});
      await container.read(data.future);
      first.close();
      await Future<void>.delayed(const Duration(milliseconds: 80));

      final again = container.listen(data, (_, _) {});
      expect(again.read().value, 1, reason: 'old data stays on screen');
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(await container.read(data.future), 2);
    });

    test('a different signed-in account never gets the cached data', () async {
      final first = container.listen(data, (_, _) {});
      expect(await container.read(data.future), 1);
      first.close();

      auth.add(_signedIn('user-b'));
      await Future<void>.delayed(Duration.zero);
      container.listen(data, (_, _) {});
      expect(await container.read(data.future), 2);
    });
  });
}
