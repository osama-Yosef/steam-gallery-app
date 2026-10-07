import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:steam_gallery_app/core/errors/app_exception.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Every error code a database function can raise must reach the person as
/// a real Arabic sentence — never the generic "حدث خطأ" — so this reads the
/// codes straight out of supabase/migrations and checks each one.
void main() {
  const generic = 'تعذَّرت العملية. حاول مرة أخرى.';
  final unexpected = AppException.from(Exception('x')).messageAr;

  /// Raised only by internal guard triggers that no client call can reach.
  const internalOnly = {'USE_DEDICATED_FUNCTION_FOR_'};

  final codes = <String>{};
  for (final file in Directory('supabase/migrations').listSync()) {
    if (file is! File || !file.path.endsWith('.sql')) continue;
    final sql = file.readAsStringSync();
    for (final m in RegExp(
      r"raise exception '([A-Z][A-Z0-9_]{3,})",
    ).allMatches(sql)) {
      codes.add(m.group(1)!);
    }
  }

  test('the migrations raise the codes this test expects to find', () {
    expect(codes.length, greaterThan(80));
    expect(codes, containsAll(['INSUFFICIENT_STOCK', 'FORBIDDEN']));
  });

  for (final code in codes.difference(internalOnly).toList()..sort()) {
    test('$code has its own Arabic message', () {
      final message = AppException.from(
        PostgrestException(message: code),
      ).messageAr;
      expect(message, isNot(generic));
      expect(message, isNot(unexpected));
      expect(message, isNot(contains(code)), reason: 'no raw code shown');
    });
  }

  test('a component short for an assembly names the component', () {
    expect(
      AppException.from(
        const PostgrestException(message: 'INSUFFICIENT_COMPONENT: مقبض'),
      ).messageAr,
      contains('مقبض'),
    );
  });
}
