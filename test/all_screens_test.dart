import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:steam_gallery_app/app.dart';
import 'package:steam_gallery_app/core/offline/outbox.dart';
import 'package:steam_gallery_app/core/router/app_router.dart';
import 'package:steam_gallery_app/core/supabase/supabase_client_provider.dart';
import 'package:steam_gallery_app/core/widgets/state_views.dart';
import 'package:steam_gallery_app/features/auth/data/models/app_user.dart';
import 'package:steam_gallery_app/features/auth/presentation/providers/auth_providers.dart';

import 'helpers/app_fonts.dart';
import 'helpers/fake_backend.dart';
import 'helpers/screen_fixtures.dart';
import 'helpers/test_outbox.dart';

AppUser _user(AppRole role) => AppUser(
  id: switch (role) {
    AppRole.admin => adminId,
    AppRole.sales => salesId,
    AppRole.technician => techId,
    AppRole.customer => customerId,
  },
  role: role,
  fullName: 'مستخدم ${role.name}',
  phone: '201000000000',
  email: '${role.name}@example.com',
  isActive: true,
  phoneVerifiedAt: DateTime(2026),
  emailVerifiedAt: DateTime(2026),
);

/// Opens [location] in the real app (real router, shells, repositories and
/// providers) signed in as [role], over [backend], at [size]. Fails on any
/// framework error (overflow, exception during build) and on a screen that
/// ends up showing an error instead of its content.
Future<void> _open(
  WidgetTester tester, {
  required AppRole role,
  required String location,
  required Size size,
  required FakeBackend backend,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await backend.signIn(_user(role).id);

  final container = ProviderContainer(
    overrides: [
      supabaseClientProvider.overrideWithValue(backend.client),
      outboxProvider.overrideWithValue(testOutbox(userId: _user(role).id)),
      currentUserProfileProvider.overrideWith((ref) async => _user(role)),
    ],
  );

  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const MokojiApp()),
  );
  await _settle(tester);
  container.read(appRouterProvider).go(location);
  await _settle(tester);

  expect(
    container.read(appRouterProvider).state.matchedLocation,
    isNot('/splash'),
    reason: 'stuck on splash',
  );
  final errors = find.byType(ErrorView);
  expect(
    errors,
    findsNothing,
    reason: errors.evaluate().isEmpty
        ? null
        : (errors.evaluate().first.widget as ErrorView).message,
  );

  if (const bool.fromEnvironment('SHOTS')) {
    await expectLater(
      find.byType(MokojiApp),
      matchesGoldenFile(
        '../build/screen_shots/${location.replaceAll(RegExp(r'[/?=]'), '_')}_${size.width.toInt()}.png',
      ),
    );
  }

  // Leave nothing running: the screens' realtime channels and timers.
  await tester.pumpWidget(const SizedBox());
  // Cached providers (ref.cacheFor) hold a timer until disposed.
  container.dispose();
  backend.close();
  // Long enough for every realtime/request timeout to fire and give up.
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(seconds: 10));
  }
}

/// pumpAndSettle with a cap: a screen with a looping animation (a progress
/// indicator while something loads) never "settles".
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (!tester.binding.hasScheduledFrame) break;
  }
}

const _phone = Size(360, 780);
const _desktop = Size(1280, 800);

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ar');
    await loadAppFonts();
  });

  for (final screen in screens) {
    for (final size in [_phone, _desktop]) {
      final label = size == _phone ? 'موبايل' : 'كمبيوتر';
      testWidgets('${screen.role.name} ${screen.location} ($label)', (
        tester,
      ) async {
        await _open(
          tester,
          role: screen.role,
          location: screen.location,
          size: size,
          backend: fixtureBackend(),
        );
      });
    }
  }
}
