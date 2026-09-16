// Keeps the Mokoji identity consistent everywhere a platform shows the app's
// name — those files can't read lib/core/constants/brand.dart, so without this
// they silently drift (the old shop name lived on in five separate places).
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:steam_gallery_app/core/constants/brand.dart';
import 'package:steam_gallery_app/core/widgets/brand_logo.dart';

const _oldBrandFragments = ['المدينة المنورة', 'Madina Steam Gallery'];

String _read(String path) => File(path).readAsStringSync();

void main() {
  group('platform app names match Brand.name', () {
    test('Android launcher label', () {
      expect(
        _read('android/app/src/main/res/values/strings.xml'),
        contains('<string name="app_name">${Brand.name}</string>'),
      );
    });

    test('iOS display name', () {
      expect(
        _read('ios/Runner/Info.plist'),
        matches(
          RegExp(
            '<key>CFBundleDisplayName</key>\\s*<string>${Brand.name}</string>',
          ),
        ),
      );
    });

    test('Windows window title and file metadata', () {
      expect(_read('windows/runner/main.cpp'), contains('L"${Brand.name}"'));
      expect(
        _read('windows/runner/Runner.rc'),
        contains('VALUE "ProductName", "${Brand.nameLatin}"'),
      );
    });

    test('web manifest and page title', () {
      final manifest = _read('web/manifest.json');
      expect(manifest, contains('"name": "${Brand.name}"'));
      expect(manifest, contains('"short_name": "${Brand.name}"'));
      expect(_read('web/index.html'), contains('<title>${Brand.name}</title>'));
    });
  });

  test('the previous shop name is gone from app code and platform shells', () {
    final roots = [
      'lib',
      'android/app/src/main',
      'ios/Runner',
      'windows/runner',
      'web',
    ];
    final offenders = <String>[];
    for (final root in roots) {
      for (final entity in Directory(root).listSync(recursive: true)) {
        if (entity is! File) continue;
        final path = entity.path;
        if (!RegExp(r'\.(dart|xml|plist|cpp|rc|json|html)$').hasMatch(path)) {
          continue;
        }
        final text = entity.readAsStringSync();
        for (final fragment in _oldBrandFragments) {
          if (text.contains(fragment)) offenders.add('$path: "$fragment"');
        }
      }
    }
    expect(offenders, isEmpty);
  });

  test('brand assets referenced in code are bundled', () {
    final pubspec = _read('pubspec.yaml');
    for (final asset in [Brand.logoAsset, Brand.markAsset]) {
      expect(File(asset).existsSync(), isTrue, reason: '$asset missing');
      expect(pubspec, contains('- $asset'), reason: '$asset not bundled');
    }
  });

  testWidgets('BrandLogo renders the logo with the brand name for a11y', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: BrandLogo())),
      ),
    );
    expect(find.byType(Image), findsOneWidget);
    expect(find.bySemanticsLabel(Brand.name), findsOneWidget);
  });
}
