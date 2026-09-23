-- ============================================================================
-- 0075_reset_for_launch.sql
--
-- DESTRUCTIVE, ONE-TIME, NOT part of the normal migration history -- this is
-- the pre-launch data reset: wipes every product and every piece of
-- transactional/test data accumulated during development and QA, keeping
-- only the one admin account (phone +201096525584) and the structural
-- config the app needs to function on day one (countries/cities/service
-- areas, the two cashboxes, expense categories, the warehouse row).
--
-- Review the KEPT / WIPED lists below before running. This cannot be undone
-- -- take a Supabase backup/snapshot first if there is ANY doubt.
--
-- Run this in the Supabase SQL Editor (or `supabase db push` if you prefer,
-- but this file is deliberately NOT meant to be part of the tracked
-- migration history that ships to other environments -- run it once by hand
-- against production when you're ready to go live, then leave it out of
-- future `supabase db push` runs, e.g. by not committing it, or by deleting
-- it from supabase/migrations/ right after).
--
-- KEPT: the admin's own row in auth.users/public.users; countries, cities,
--   service_areas; cashboxes (rows, not their balance); expense_categories;
--   warehouses (rows); private.app_settings, private.rpc_allowlist.
-- WIPED: every product, category, offer, banner; every order, cart, sale,
--   return, payment; every customer, technician, and their accounts/wallets;
--   every cash/stock/inventory-count movement; every maintenance request;
--   every notification and audit-log entry; every user account except the
--   one admin phone number above.
-- ============================================================================

begin;

do $$
declare
  v_admin_id uuid;
begin
  select id into v_admin_id
    from public.users
    where phone = '201096525584' and role = 'admin';

  if v_admin_id is null then
    raise exception 'Admin row not found for 201096525584 -- aborting, nothing was deleted.';
  end if;

  -- These tables are deliberately append-only in normal operation (a
  -- prevent_mutation() trigger blocks UPDATE/DELETE so the app can never
  -- edit its own financial ledger) -- switched off for this one-time reset
  -- only, and switched back on again below before the transaction commits.
  alter table public.stock_movements disable trigger trg_stock_movements_no_update;
  alter table public.order_items disable trigger trg_order_items_no_update;
  alter table public.maintenance_status_history disable trigger trg_maintenance_history_no_update;
  alter table public.sale_items disable trigger trg_sale_items_no_update;
  alter table public.technician_account_transactions disable trigger trg_tech_txn_no_update;
  alter table public.cash_transactions disable trigger trg_cash_txn_no_update;
  alter table public.customer_account_transactions disable trigger trg_cust_txn_no_update;
  alter table public.expenses disable trigger trg_expenses_no_update;
  alter table public.audit_logs disable trigger trg_audit_logs_no_update;
  alter table public.payment_attempts disable trigger trg_payment_attempts_no_mutation;
  alter table public.payment_webhook_events disable trigger trg_payment_webhook_events_no_delete;
  alter table public.wallet_transactions disable trigger trg_wallet_transactions_no_mutation;
  alter table public.sale_item_returns disable trigger trg_sale_item_returns_no_update;

  -- These two reference sales/orders (no cascade), so they must go first --
  -- otherwise deleting sales/orders below fails with a FK violation.
  delete from public.technician_account_transactions;
  delete from public.customer_account_transactions;

  -- Sales & returns
  delete from public.sale_item_returns;
  delete from public.sale_items;
  delete from public.sales;

  -- Orders & payments
  delete from public.order_items;
  delete from public.payment_attempts;
  delete from public.payment_webhook_events;
  delete from public.payments;
  delete from public.orders;
  delete from public.cart_items;

  -- Maintenance
  delete from public.maintenance_images;
  delete from public.maintenance_status_history;
  delete from public.maintenance_requests;

  -- Inventory & stock
  delete from public.inventory_count_items;
  delete from public.inventory_counts;
  delete from public.stock_movements;
  delete from public.technician_bag_stock;
  delete from public.technician_bags;
  delete from public.technician_supplies;
  delete from public.warehouse_stock;

  -- Accounts, wallets, cashbox movements (cashboxes themselves are kept --
  -- deleting every cash_transactions row zeroes their balance back to 0).
  -- technician_account_transactions and customer_account_transactions were
  -- already deleted above, before sales/orders.
  delete from public.technician_accounts;
  delete from public.wallet_transactions;
  delete from public.wallets;
  delete from public.customer_accounts;
  delete from public.cash_transactions;
  delete from public.expenses;

  -- Notifications & audit trail
  delete from public.notifications;
  delete from public.audit_logs;

  -- Marketing & catalogue
  delete from public.offer_products;
  delete from public.offers;
  delete from public.home_banners;
  delete from public.product_images;
  delete from public.product_options;
  delete from public.products;
  delete from public.product_categories;

  -- People: customer/technician addresses first, then role tables, then
  -- every account except the kept admin (public.users cascades from
  -- auth.users, so deleting there is enough, but both are explicit here
  -- for clarity).
  delete from public.customer_addresses;
  delete from public.customers;
  delete from public.technicians;
  delete from public.users where id <> v_admin_id;
  delete from auth.users where id <> v_admin_id;

  -- Restore the immutable-ledger protection for normal operation from now on.
  alter table public.stock_movements enable trigger trg_stock_movements_no_update;
  alter table public.order_items enable trigger trg_order_items_no_update;
  alter table public.maintenance_status_history enable trigger trg_maintenance_history_no_update;
  alter table public.sale_items enable trigger trg_sale_items_no_update;
  alter table public.technician_account_transactions enable trigger trg_tech_txn_no_update;
  alter table public.cash_transactions enable trigger trg_cash_txn_no_update;
  alter table public.customer_account_transactions enable trigger trg_cust_txn_no_update;
  alter table public.expenses enable trigger trg_expenses_no_update;
  alter table public.audit_logs enable trigger trg_audit_logs_no_update;
  alter table public.payment_attempts enable trigger trg_payment_attempts_no_mutation;
  alter table public.payment_webhook_events enable trigger trg_payment_webhook_events_no_delete;
  alter table public.wallet_transactions enable trigger trg_wallet_transactions_no_mutation;
  alter table public.sale_item_returns enable trigger trg_sale_item_returns_no_update;

  raise notice 'Reset complete. Admin kept: %', v_admin_id;
end $$;

commit;
