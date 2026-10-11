-- supabase/scripts/reset_for_production.sql
--
-- Wipes the trial data so the shop starts live from zero. NOT a migration:
-- it must never run on its own. Run it once, by hand, in the Supabase
-- dashboard → SQL Editor, AFTER taking a backup (Database → Backups, or
-- `supabase db dump`). There is no undo.
--
-- Removed (and every number restarts at 1 — sales, orders, maintenance
-- tickets, expenses, purchase invoices, stock movements, counts, supplies,
-- supplier payments):
--   * all sales, orders, maintenance requests, payments, returns, carts
--   * the cashbox ledger (so both tills read 0), expenses, customer and
--     technician account ledgers, wallet transactions (wallets back to 0)
--   * stock: warehouse and technician-bag quantities, movements, counts
--   * the catalogue: products, categories, images, options, components
--   * suppliers and purchase invoices, offers, banners, service areas
--   * employees' attendance, advances and salary payments (the employees
--     themselves are kept)
--   * notifications and the audit log
--
-- Kept: every account (admin, sales, technicians, customers) and their
-- logins, customers' saved addresses (their service area cleared — areas
-- are redrawn from scratch), countries and cities, the warehouse and the
-- four tills, the employees, technicians' (empty) bags, app settings (InstaPay, WhatsApp,
-- phone verification switch).
--
-- Expense categories are cleared and the standard seven put back: the app
-- has no screen to add categories, so with none an expense can't be saved.
-- Likewise the maintenance service line ("خدمة صيانة") is put back.
--
-- Files already uploaded to Storage (product photos, banners, maintenance
-- photos, InstaPay receipts) are not touched by SQL; empty those buckets
-- from Storage in the dashboard if you want them gone too.

begin;

-- Addresses stay; the area they were matched to is about to go.
update public.customer_addresses set service_area_id = null
where service_area_id is not null;

-- One statement, no CASCADE: if any table this script keeps still pointed
-- at one of these, Postgres refuses and nothing is wiped.
truncate table
  public.employee_payrolls,
  public.employee_advances,
  public.employee_attendance,
  public.notifications,
  public.cart_items,
  public.payment_webhook_events,
  public.payment_attempts,
  public.payments,
  public.order_item_components,
  public.order_items,
  public.orders,
  public.sale_item_returns,
  public.sale_items,
  public.sales,
  public.maintenance_images,
  public.maintenance_status_history,
  public.maintenance_requests,
  public.technician_supplies,
  public.technician_account_transactions,
  public.customer_account_transactions,
  public.wallet_transactions,
  public.cash_transactions,
  public.expenses,
  public.expense_categories,
  public.supplier_payments,
  public.purchase_invoice_items,
  public.purchase_invoices,
  public.suppliers,
  public.inventory_count_items,
  public.inventory_counts,
  public.stock_movements,
  public.warehouse_stock,
  public.technician_bag_stock,
  public.offer_products,
  public.offers,
  public.home_banners,
  public.product_components,
  public.product_options,
  public.product_images,
  public.products,
  public.product_categories,
  private.processed_requests
restart identity;

-- Referenced by the kept addresses (now cleared above), so deleted rather
-- than truncated.
delete from public.service_areas;

update public.wallets set balance = 0, updated_at = now() where balance <> 0;

insert into public.expense_categories (name)
values ('كهرباء'), ('إيجار'), ('نقل'), ('مرتبات'), ('صيانة'), ('شراء أدوات'), ('مصاريف أخرى');

-- The maintenance service line (seeded by 0027) is part of the app, not
-- trial data: the technician's maintenance invoice and the counter's
-- "خدمة" line both sell it.
insert into public.products (sku, name, description, cost_price, selling_price, is_service)
values ('SERVICE-MAINT', 'خدمة صيانة', 'أجر خدمة الصيانة — السعر يُحدَّد وقت الفاتورة', 0, 0, true);

-- Last, so the steps above (which the audit triggers record) leave no trace.
truncate table public.audit_logs restart identity;

commit;
