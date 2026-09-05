// Guards the "just press Run" guarantee: the app ships with working Supabase
// defaults, so `flutter run` (or the Run button in Android Studio) reaches the
// real backend with no --dart-define and no other setup.
//
// This replaces the old Module 0 smoke test, which asserted the opposite — that
// an unconfigured app lands on the "not configured" screen. That screen is now
// only reachable by explicitly blanking the values out.
import 'package:flutter_test/flutter_test.dart';

import 'package:steam_gallery_app/core/config/env.dart';

void main() {
  test('Supabase is configured out of the box, with no --dart-define', () {
    expect(Env.isConfigured, isTrue);
    expect(Env.supabaseUrl, startsWith('https://'));
    expect(Env.supabasePublishableKey, isNotEmpty);
  });

  test('the service_role key is never what ships in the client', () {
    // The publishable key is safe to embed; the secret one never is. If a
    // service_role key is ever pasted in here, fail loudly rather than let it
    // reach a build.
    expect(Env.supabasePublishableKey, isNot(contains('service_role')));
    expect(Env.supabasePublishableKey, startsWith('sb_publishable_'));
  });
}
