-- ============================================================================
-- 0042_wallet_admin_reporting.sql  (Phase 15 — admin/finance visibility)
--
-- The revenue/profit figures on the admin dashboard (daily_sales_summary,
-- 0009) were already correct once wallet/InstaPay payments existed — they're
-- derived from orders.status, not from HOW an order was paid, so nothing
-- there double-counts or misses a wallet-paid sale.
--
-- What was actually missing: the admin had no visibility at all into money
-- sitting in customer wallets. That balance is a LIABILITY (the shop owes
-- customers goods/services worth it, not revenue) and is invisible in every
-- existing view — cashbox_balances only tracks physical cash, and a wallet
-- top-up deliberately never touches the cashbox (0040/0041). Two read-only
-- views, same security_invoker pattern as every other view in 0009, so RLS
-- on `wallets` (customer sees only their own row, admin sees every row)
-- decides what each caller's aggregate actually sums over.
-- ============================================================================

create view public.wallet_summary
  with (security_invoker = true) as
select
  w.id as wallet_id,
  w.customer_id,
  u.full_name as customer_name,
  w.balance,
  w.currency,
  w.is_active
from public.wallets w
join public.users u on u.id = w.customer_id;

-- Total liability + how many wallets hold a balance. For an admin this is
-- the true totals across every customer; for a customer querying it
-- directly, RLS on `wallets` limits the sum to their own single row — the
-- same self-consistent (not a leak) behaviour customer_account_summary
-- already has.
create view public.wallet_liability_summary
  with (security_invoker = true) as
select
  coalesce(sum(balance), 0)::numeric(14,2) as total_liability,
  count(*)::int as wallet_count
from public.wallets
where is_active;
