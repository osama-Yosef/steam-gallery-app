import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:steam_gallery_app/core/offline/offline_http_client.dart';

/// Every RPC the app calls has to be one of three things with no
/// connection (specs/001-offline-mode/contracts/offline-behavior.md):
///
/// 1. a read kept on the device — [OfflineHttpClient.isReadOnlyRpc];
/// 2. a write that waits in the Outbox — called as `submit(rpc: '...')`;
/// 3. a write that needs the internet on purpose — [_onlineOnly] below,
///    where the screen says "needs internet" instead of failing.
///
/// A new RPC that is none of these fails here, so it can't quietly become a
/// screen that stops working offline.
const _onlineOnly = {
  // Sign-in, account and settings.
  'rpc_mark_phone_verified',
  'rpc_admin_set_active',
  'rpc_admin_set_role',
  'rpc_admin_set_setting',
  'rpc_admin_set_text_setting',
  'rpc_backup_export',
  'rpc_backup_restore',
  // Customer: ordering, addresses, payments, maintenance requests.
  'rpc_create_order',
  'rpc_customer_respond_shipping_fee',
  'rpc_save_my_address',
  'rpc_delete_my_address',
  'rpc_set_default_address',
  'rpc_set_my_city',
  'rpc_submit_instapay_payment',
  'rpc_wallet_topup_via_instapay',
  'rpc_pay_order_from_wallet',
  'rpc_create_maintenance_request',
  // Maintenance hand-offs: they depend on the request's state at the shop.
  'rpc_assign_maintenance',
  'rpc_claim_maintenance',
  'rpc_start_maintenance',
  'rpc_cancel_maintenance',
  // Technician: stock moves, supply and edits, checked against the shop.
  'rpc_technician_bag_transfer',
  'rpc_technician_supply',
  'rpc_edit_technician_sale',
  'rpc_delete_technician_sale',
  // Back office actions that need the current server state.
  'rpc_admin_review_technician_supply',
  'rpc_admin_verify_instapay',
  'rpc_admin_set_assembly',
  'rpc_admin_opening_stock',
  'rpc_admin_return_sale',
  'rpc_return_sale_item',
  'rpc_issue_stock_to_technician',
  'rpc_edit_expense',
  'rpc_delete_expense',
  // Counts: each line is compared with the stock at the moment it's counted.
  'rpc_start_inventory_count',
  'rpc_start_bag_count',
  'rpc_add_inventory_count_item',
  'rpc_save_inventory_count_item',
  'rpc_refresh_inventory_count',
  'rpc_submit_inventory_count',
  'rpc_complete_inventory_count',
};

void main() {
  final direct = <String, Set<String>>{};
  final queued = <String, Set<String>>{};
  final directCall = RegExp(r"\.rpc\(\s*'([a-z0-9_]+)'");
  final queuedCall = RegExp(r"rpc:\s*'([a-z0-9_]+)'");
  // Order actions pass the RPC name to a helper that submits it.
  final orderAction = RegExp(r"_orderAction\(\s*\w+,\s*'([a-z0-9_]+)'");

  for (final f in Directory('lib').listSync(recursive: true)) {
    final path = f.path.replaceAll(r'\', '/');
    if (f is! File ||
        !path.endsWith('.dart') ||
        path.endsWith('.g.dart') ||
        path.endsWith('.freezed.dart')) {
      continue;
    }
    final src = f.readAsStringSync();
    for (final m in directCall.allMatches(src)) {
      direct.putIfAbsent(m.group(1)!, () => {}).add(path);
    }
    for (final m in [
      ...queuedCall.allMatches(src),
      ...orderAction.allMatches(src),
    ]) {
      queued.putIfAbsent(m.group(1)!, () => {}).add(path);
    }
  }

  test('the scan finds the app\'s RPCs', () {
    expect(direct.length + queued.length, greaterThan(40));
  });

  test('every RPC called directly is kept offline or marked online-only', () {
    final unclassified = {
      for (final e in direct.entries)
        if (!OfflineHttpClient.isReadOnlyRpc(e.key) &&
            !_onlineOnly.contains(e.key) &&
            // rpc_replay is the Outbox's own sender.
            e.key != 'rpc_replay')
          e.key: e.value,
    };
    expect(
      unclassified,
      isEmpty,
      reason:
          'Add each to OfflineHttpClient.isReadOnlyRpc (a read), send it '
          'through Outbox.submit (a write that can wait), or add it to '
          '_onlineOnly here (a write that needs the internet).',
    );
  });

  test('no write is both queued and listed as online-only', () {
    expect(queued.keys.toSet().intersection(_onlineOnly), isEmpty);
  });

  test('no queued write is ever answered from the read cache', () {
    expect(queued.keys.where(OfflineHttpClient.isReadOnlyRpc), isEmpty);
  });
}
