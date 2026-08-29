// Module 0 smoke test: the app boots without a configured Supabase project
// and shows the "not configured" screen instead of crashing.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:steam_gallery_app/app.dart';

void main() {
  testWidgets('App boots to config-missing screen when unconfigured', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: SteamGalleryApp()));
    await tester.pumpAndSettle();

    expect(find.text('إعدادات Supabase غير موجودة'), findsOneWidget);
  });
}
