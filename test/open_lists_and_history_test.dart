import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:steam_gallery_app/core/supabase/live_query.dart';
import 'package:steam_gallery_app/core/utils/history_query.dart';
import 'package:steam_gallery_app/features/maintenance/data/repositories/maintenance_repository.dart';
import 'package:steam_gallery_app/features/orders/data/repositories/order_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'helpers/test_outbox.dart';

/// A Supabase client whose HTTP requests are captured instead of sent.
({SupabaseClient client, List<Uri> requests, List<Map<String, String>> headers})
_capturingClient() {
  final requests = <Uri>[];
  final headers = <Map<String, String>>[];
  final client = SupabaseClient(
    'https://x.supabase.co',
    'anon-key',
    httpClient: MockClient((req) async {
      requests.add(req.url);
      headers.add(req.headers);
      return http.Response(
        jsonEncode(<Object>[]),
        200,
        request: req,
        headers: {'content-type': 'application/json'},
      );
    }),
  );
  return (client: client, requests: requests, headers: headers);
}

/// The query string as PostgREST receives it, decoded.
String _query(Uri uri) => Uri.decodeComponent(uri.query);

void main() {
  group('refetchOn', () {
    test('fetches once on listen, then after each burst of changes', () async {
      final changes = StreamController<void>();
      var fetches = 0;
      final values = <int>[];
      final sub = refetchOn(
        () async => ++fetches,
        changes.stream,
        debounce: const Duration(milliseconds: 20),
      ).listen(values.add);

      await Future<void>.delayed(const Duration(milliseconds: 5));
      expect(values, [1]);

      // Three changes in a row → one refetch.
      changes
        ..add(null)
        ..add(null)
        ..add(null);
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(values, [1, 2]);

      await sub.cancel();
      changes.add(null);
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(fetches, 2, reason: 'nothing runs after the screen closes');
      await changes.close();
    });

    test('a failed fetch is reported and the next change retries', () async {
      final changes = StreamController<void>();
      var fail = true;
      final events = <Object>[];
      final sub = refetchOn(
        () async {
          if (fail) throw Exception('offline');
          return 'ok';
        },
        changes.stream,
        debounce: Duration.zero,
      ).listen(events.add, onError: events.add);
      await Future<void>.delayed(const Duration(milliseconds: 5));
      expect(events.single, isA<Exception>());

      fail = false;
      changes.add(null);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(events.last, 'ok');
      await sub.cancel();
      await changes.close();
    });
  });

  group('HistoryQuery', () {
    test('a number (with or without #) searches by number', () {
      expect(const HistoryQuery(text: ' 42 ').number, 42);
      expect(const HistoryQuery(text: '#42').number, 42);
      expect(const HistoryQuery(text: 'أحمد').number, isNull);
    });

    test('characters that would break the server filter are dropped', () {
      expect(const HistoryQuery(text: '#a,b(c)*d%e').safeText, 'a b c  d e');
    });

    test('days become a [from midnight, next midnight) range in UTC', () {
      final q = HistoryQuery(
        from: DateTime(2026, 10, 1),
        to: DateTime(2026, 10, 7),
      );
      expect(q.fromUtc, DateTime(2026, 10, 1).toUtc().toIso8601String());
      expect(q.toUtcExclusive, DateTime(2026, 10, 8).toUtc().toIso8601String());
    });

    test('equal queries are equal (they key the results provider)', () {
      expect(
        HistoryQuery(text: 'x', from: DateTime(2026)),
        HistoryQuery(text: 'x', from: DateTime(2026)),
      );
    });
  });

  group('orders', () {
    test('the open list asks for unfinished orders or today\'s', () async {
      final c = _capturingClient();
      await SupabaseOrderRepository(c.client, testOutbox()).fetchOpenOrders();
      final q = _query(c.requests.single);
      expect(c.requests.single.path, '/rest/v1/orders');
      expect(
        q,
        contains(
          'or=(status.in.(pending,confirmed,preparing,delivered),'
          'created_at.gte.${startOfTodayUtc()})',
        ),
      );
      expect(q, contains('order=created_at.desc'));
    });

    test('history by number, one page at a time', () async {
      final c = _capturingClient();
      await SupabaseOrderRepository(
        c.client,
        testOutbox(),
      ).searchOrders(const HistoryQuery(text: '#15'), limit: 30, offset: 60);
      final q = _query(c.requests.single);
      // Digits are the order number — or part of the recipient's phone.
      expect(q, contains('or=(order_number.eq.15,delivery_phone.ilike.%15%)'));
      expect(q, contains('offset=60'));
      expect(q, contains('limit=30'));
    });

    test('history by name or phone, within days', () async {
      final c = _capturingClient();
      final query = HistoryQuery(
        text: 'منى',
        from: DateTime(2026, 9, 1),
        to: DateTime(2026, 9, 30),
      );
      await SupabaseOrderRepository(
        c.client,
        testOutbox(),
      ).searchOrders(query, limit: 30, offset: 0);
      final q = _query(c.requests.single);
      expect(
        q,
        contains(
          'or=(delivery_recipient_name.ilike.%منى%,delivery_phone.ilike.%منى%)',
        ),
      );
      expect(q, contains('created_at=gte.${query.fromUtc}'));
      expect(q, contains('created_at=lt.${query.toUtcExclusive}'));
    });
  });

  group('maintenance', () {
    test('the open list asks for open requests or today\'s', () async {
      final c = _capturingClient();
      await SupabaseMaintenanceRepository(c.client).fetchOpenRequests();
      final q = _query(c.requests.single);
      expect(c.requests.single.path, '/rest/v1/maintenance_requests');
      expect(
        q,
        contains(
          'or=(status.in.(waiting,assigned,in_progress),'
          'created_at.gte.${startOfTodayUtc()})',
        ),
      );
    });

    test('history by ticket number or customer', () async {
      final c = _capturingClient();
      final repo = SupabaseMaintenanceRepository(c.client);
      await repo.searchRequests(
        const HistoryQuery(text: '9'),
        limit: 30,
        offset: 0,
      );
      await repo.searchRequests(
        const HistoryQuery(text: '0100'),
        limit: 30,
        offset: 0,
      );
      await repo.searchRequests(
        const HistoryQuery(text: 'سعيد'),
        limit: 30,
        offset: 0,
      );
      expect(
        _query(c.requests[0]),
        contains('or=(ticket_number.eq.9,phone.ilike.%9%)'),
      );
      // A phone fragment is digits too: it finds the phone, leading 0 kept.
      expect(
        _query(c.requests[1]),
        contains('or=(ticket_number.eq.100,phone.ilike.%0100%)'),
      );
      expect(
        _query(c.requests[2]),
        contains('or=(customer_name.ilike.%سعيد%,phone.ilike.%سعيد%)'),
      );
    });
  });
}
