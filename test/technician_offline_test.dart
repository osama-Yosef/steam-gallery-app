import 'package:flutter_test/flutter_test.dart';
import 'package:steam_gallery_app/core/errors/app_exception.dart';
import 'package:steam_gallery_app/features/inventory/data/models/technician_bag_stock_item.dart';
import 'package:steam_gallery_app/features/inventory/presentation/state/bag_stock.dart';
import 'package:steam_gallery_app/features/maintenance/data/repositories/maintenance_repository.dart';
import 'package:steam_gallery_app/features/sales/data/models/sale_line_input.dart';
import 'package:steam_gallery_app/features/technician_account/data/models/sale.dart';
import 'package:steam_gallery_app/features/technician_account/data/repositories/technician_account_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'helpers/test_outbox.dart';

/// The technician is out at customers' homes, often with no connection: a
/// bag sale and closing a job are kept on the phone and sent later, and the
/// bag he sees already counts those sales out.
void main() {
  late FakeServer server;
  late SupabaseClient client;

  setUp(() {
    server = FakeServer();
    client = SupabaseClient('https://fake.supabase.co', 'anon-key');
  });

  Future<String?> sell(
    SupabaseTechnicianAccountRepository repo, {
    String requestId = 'req-1',
    String? maintenanceId,
  }) => repo.recordSale(
    technicianId: 'tech-1',
    customerName: 'أم أحمد',
    items: const [
      SaleLineInput(productId: 'p1', quantity: 2, unitPrice: 50),
      SaleLineInput(productId: 'p2', quantity: 1, unitPrice: 30),
    ],
    itemNames: const ['خرطوم', 'جلبة'],
    paymentMethod: PaymentMethod.cash,
    discount: 10,
    paidAmount: 120,
    clientRequestId: requestId,
    maintenanceRequestId: maintenanceId,
  );

  group('bag sale', () {
    test('online: sent at once, returns the sale id', () async {
      final outbox = testOutbox(server: server, userId: 'tech-1');
      server.reply = 'sale-9';
      final id = await sell(
        SupabaseTechnicianAccountRepository(client, outbox),
      );
      expect(id, 'sale-9');
      expect(server.calls.single.rpc, 'rpc_technician_sale');
      expect(outbox.pending, isEmpty);
    });

    test('offline: kept on the phone, keyed by its request id', () async {
      final outbox = testOutbox(server: server, userId: 'tech-1');
      server.online = false;
      final id = await sell(
        SupabaseTechnicianAccountRepository(client, outbox),
        maintenanceId: 'm-1',
      );
      expect(id, isNull);
      final e = outbox.pending.single;
      expect(e.kind, technicianSaleKind);
      expect(e.id, 'req-1');
      expect(e.params['p_client_request_id'], e.id);
      // Safe to repeat on its own (0090) — no rpc_replay needed.
      expect(e.viaReplay, isFalse);
      expect(e.refId, 'm-1');
      expect(e.meta?['total'], 120);
      expect((e.meta?['items'] as List).first['name'], 'خرطوم');
    });

    test('a refusal is thrown in Arabic, not queued', () async {
      final outbox = testOutbox(server: server, userId: 'tech-1');
      server.refusals['rpc_technician_sale'] = 'INSUFFICIENT_STOCK';
      await expectLater(
        sell(SupabaseTechnicianAccountRepository(client, outbox)),
        throwsA(isA<AppException>()),
      );
      expect(outbox.pending, isEmpty);
    });
  });

  group('closing a maintenance job', () {
    test('offline: kept, sent through rpc_replay later', () async {
      final outbox = testOutbox(server: server, userId: 'tech-1');
      final repo = SupabaseMaintenanceRepository(client, outbox);
      server.online = false;
      final result = await repo.complete('m-1', 'تم', customerName: 'أم أحمد');
      expect(result.queued, isTrue);
      final e = outbox.pending.single;
      expect(e.kind, maintenanceCompleteKind);
      expect(e.refId, 'm-1');
      expect(e.viaReplay, isTrue);
      expect(outbox.pendingOf(maintenanceCompleteKind, refId: 'm-1'), [e]);

      server.online = true;
      await outbox.sync();
      expect(server.calls.single.rpc, 'rpc_replay');
      expect(server.calls.single.params['p_rpc'], 'rpc_complete_maintenance');
      expect(server.calls.single.params['p_params'], {
        'p_request_id': 'm-1',
        'p_notes': 'تم',
      });
    });

    test('the close goes out before the invoice made after it', () async {
      final outbox = testOutbox(server: server, userId: 'tech-1');
      server.online = false;
      await SupabaseMaintenanceRepository(client, outbox).complete('m-1', null);
      await sell(
        SupabaseTechnicianAccountRepository(client, outbox),
        maintenanceId: 'm-1',
      );
      server.online = true;
      await outbox.sync();
      expect(server.calls.map((c) => c.rpc), [
        'rpc_replay',
        'rpc_technician_sale',
      ]);
    });
  });

  group('the bag on screen', () {
    TechnicianBagStockItem item(String id, int qty) => TechnicianBagStockItem(
      productId: id,
      sku: id,
      productName: id,
      quantity: qty,
      costPrice: 10,
      sellingPrice: 20,
    );

    test('pending sales are taken off, never below zero', () async {
      final outbox = testOutbox(server: server, userId: 'tech-1');
      server.online = false;
      final repo = SupabaseTechnicianAccountRepository(client, outbox);
      await sell(repo, requestId: 'a'); // p1 ×2, p2 ×1
      await sell(repo, requestId: 'b');

      final shown = bagStockAfterPending(
        [item('p1', 5), item('p2', 1), item('p3', 4)],
        outbox.pendingOf(technicianSaleKind),
        'tech-1',
      );
      expect(
        {for (final i in shown) i.productId: i.quantity},
        {'p1': 1, 'p2': 0, 'p3': 4},
      );
    });

    test("another technician's pending sales don't count", () async {
      final outbox = testOutbox(server: server, userId: 'tech-1');
      server.online = false;
      await sell(SupabaseTechnicianAccountRepository(client, outbox));
      final shown = bagStockAfterPending(
        [item('p1', 5)],
        outbox.pendingOf(technicianSaleKind),
        'tech-2',
      );
      expect(shown.single.quantity, 5);
    });
  });
}
