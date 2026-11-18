# Working without internet (2.4.0)

Spec, plan and tasks: [specs/001-offline-mode](../specs/001-offline-mode/).

## What works with no connection

| Role | Works offline | Needs internet |
|------|---------------|----------------|
| All | Opening the app (once it has loaded the account on this device), every screen opened before (last data seen), the "offline" strip | First sign-in on a device, screens never opened on it |
| Admin / sales | Walk-in sales, invoice edits/deletes, expenses, deposits/withdrawals/transfers, customer and supplier payments, purchase invoices, salaries and advances, order status changes — saved on the device and sent in order when the connection is back | Backup/restore, users and roles, settings, returns, counts, opening stock |
| Technician | Selling from the bag, closing a maintenance job (and its invoice) — saved and sent later; the bag shown already counts pending sales out | Claiming/starting jobs, bag transfers, bag counts, editing a sale, supply |
| Customer | Browsing what was loaded before, past orders | Ordering (the cart is kept), maintenance requests, addresses, payments |

Every RPC the app calls is classified in
`test/offline_rpc_classification_test.dart`; a new one that isn't fails the
test.

## Before releasing 2.4.0

Apply migration **`0097_offline_complete_maintenance.sql`** to Supabase
first: a technician's job closed offline is sent through `rpc_replay`, which
refuses it (`UNSUPPORTED_RPC`) on a database without 0097.

## How it fits together

- `lib/core/offline/offline_http_client.dart` — reads are saved per user and
  answered from the device when the server can't be reached.
- `lib/core/offline/offline_session.dart` — the session is carried through an
  outage, so nobody is signed out.
- `lib/core/offline/outbox.dart` — writes wait on the device and go out in
  order, each exactly once (`client_request_id`, or `rpc_replay`). The first
  attempt waits 15 s at most.
- `SupabaseAuthRepository.getMyProfile` keeps the last profile on the device;
  with no connection and nothing saved, the router shows the offline start
  screen instead of login, and the splash screen no longer signs out.
