import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:steam_gallery_app/core/errors/app_exception.dart';
import 'package:steam_gallery_app/features/backup/data/backup_repository.dart';

/// Reading a backup file before restoring it.
void main() {
  Uint8List bytes(Object json) =>
      Uint8List.fromList(utf8.encode(jsonEncode(json)));

  test('a backup file shows its date and what it holds', () {
    final (info, json) = BackupInfo.parse(
      bytes({
        'format': 'mokoji-backup',
        'version': 1,
        'schema': '0093',
        'created_at': '2026-11-02T12:30:00Z',
        'tables': {
          'public.sales': [{}, {}, {}],
          'public.expenses': [{}],
        },
      }),
    );
    expect(info.createdAt, DateTime.utc(2026, 11, 2, 12, 30));
    expect(info.of('sales'), 3);
    expect(info.of('expenses'), 1);
    expect(info.of('products'), 0);
    expect(json['schema'], '0093');
  });

  test('any other file is refused before anything is sent', () {
    for (final other in [
      bytes({'hello': 1}),
      bytes([1, 2, 3]),
      Uint8List.fromList([0xff, 0xfe, 0x00]),
    ]) {
      expect(() => BackupInfo.parse(other), throwsA(isA<AppException>()));
    }
  });

  test('the file name carries the date and time', () {
    expect(
      BackupRepository.fileName(DateTime(2026, 11, 2, 9, 5)),
      'mokoji-backup-2026-11-02-0905.json',
    );
  });
}
