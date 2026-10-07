import 'package:flutter/services.dart';

/// Loads the app's own Arabic font, so text in a test takes the width it
/// takes on a phone. Without it every glyph is drawn as a full-width box
/// (the test font), roughly doubling Arabic text width and reporting
/// overflows no real screen would have.
Future<void> loadAppFonts() async {
  final cairo = FontLoader('Cairo');
  for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold']) {
    cairo.addFont(rootBundle.load('assets/fonts/Cairo-$weight.ttf'));
  }
  await cairo.load();
}
