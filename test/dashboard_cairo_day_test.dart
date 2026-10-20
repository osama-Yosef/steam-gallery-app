import 'package:flutter_test/flutter_test.dart';
import 'package:steam_gallery_app/features/dashboard/data/repositories/dashboard_repository.dart';

void main() {
  group('cairoDay', () {
    test('Cairo midnight in summer time (UTC+3) is that day', () {
      expect(cairoDay('2026-10-14T21:00:00+00:00'), DateTime(2026, 10, 15));
    });

    test('Cairo midnight in winter time (UTC+2) is that day', () {
      expect(cairoDay('2026-12-14T22:00:00+00:00'), DateTime(2026, 12, 15));
    });

    test('the first of the month stays in its own month', () {
      expect(cairoDay('2026-10-31T21:00:00+00:00'), DateTime(2026, 11, 1));
    });

    test('an offset written in Cairo time reads the same', () {
      expect(cairoDay('2026-10-15T00:00:00+03:00'), DateTime(2026, 10, 15));
    });
  });
}
