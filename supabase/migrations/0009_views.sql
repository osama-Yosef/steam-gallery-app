-- ============================================================================
-- 0009_views.sql
--
-- IMPORTANT: every view is created WITH (security_invoker = true). Without
-- this, a Postgres view runs with the privileges of its OWNER (the migration
-- role, which bypasses RLS), silently leaking every row to any authenticated
-- caller regardless of the RLS policies on the underlying tables. With
-- security_invoker = true (Postgres 15+, used by Supabase), the view
-- re-applies the QUERYING user's RLS policies on every underlying table, so
-- e.g. a technician querying technician_account_summary only ever sees the
-- row(s) their own RLS-filtered joins can produce.
-- ============================================================================

-- Public product catalog WITHOUT cost_price (customer app must never see cost).
create view public.products_public
  with (security_invoker = true) as
select
  p.id, p.sku, p.barcode, p.category_id, p.name, p.description, p.specs,
  p.selling_price, p.is_active, p.created_at,
  coalesce(ws.total_qty, 0) > 0 as is_available
from public.products p
left join (
  select product_id, sum(quantity) as total_qty
  from public.warehouse_stock
  group by product_id
) ws on ws.product_id = p.id
where p.is_active = true;

-- Cashbox running balance = SUM of the ledger. No stored balance anywhere.
-- Admin-only in practice (cash_transactions SELECT policy is admin-only).
create view public.cashbox_balances
  with (security_invoker = true) as
select
  cb.id as cashbox_id,
  cb.name,
  coalesce(sum(ct.amount), 0)::numeric(14,2) as balance
from public.cashboxes cb
left join public.cash_transactions ct on ct.cashbox_id = cb.id
group by cb.id, cb.name;

-- Customer statement summary. A customer querying this only ever sees their
-- own row because customer_account_transactions RLS restricts the join.
create view public.customer_account_summary
  with (security_invoker = true) as
select
  c.id as customer_id,
  u.full_name as customer_name,
  coalesce(sum(t.amount) filter (where t.transaction_type = 'order_charge'), 0)::numeric(14,2) as total_purchases,
  coalesce(-sum(t.amount) filter (where t.transaction_type in ('payment', 'return_credit')), 0)::numeric(14,2) as total_paid,
  coalesce(sum(t.amount), 0)::numeric(14,2) as remaining_balance
from public.customers c
join public.users u on u.id = c.id
left join public.customer_account_transactions t on t.customer_id = c.id
group by c.id, u.full_name;

-- Technician bag value at current cost price.
create view public.technician_bag_value
  with (security_invoker = true) as
select
  tb.technician_id,
  coalesce(sum(tbs.quantity * p.cost_price), 0)::numeric(14,2) as bag_value
from public.technician_bags tb
left join public.technician_bag_stock tbs on tbs.technician_bag_id = tb.id
left join public.products p on p.id = tbs.product_id
group by tb.technician_id;

-- Main warehouse stock value at current cost price (admin only).
create view public.warehouse_stock_value
  with (security_invoker = true) as
select
  ws.warehouse_id,
  coalesce(sum(ws.quantity * p.cost_price), 0)::numeric(14,2) as stock_value
from public.warehouse_stock ws
join public.products p on p.id = ws.product_id
group by ws.warehouse_id;

-- Full technician account summary (matches the "محمد" example in the spec).
-- A technician querying this only ever gets their own row.
create view public.technician_account_summary
  with (security_invoker = true) as
select
  t.id as technician_id,
  u.full_name as technician_name,
  coalesce(bv.bag_value, 0)::numeric(14,2) as bag_value,
  coalesce(s.total_sales, 0)::numeric(14,2) as total_sales,
  coalesce(s.total_collected, 0)::numeric(14,2) as total_collected,
  coalesce(due.sale_credit, 0)::numeric(14,2) - coalesce(due.supply_debit, 0)::numeric(14,2)
    + coalesce(due.adjustment, 0)::numeric(14,2) as amount_due
from public.technicians t
join public.users u on u.id = t.id
left join public.technician_bag_value bv on bv.technician_id = t.id
left join (
  select technician_id,
    sum(total) as total_sales,
    sum(paid_amount) as total_collected
  from public.sales
  where status = 'completed'
  group by technician_id
) s on s.technician_id = t.id
left join (
  select technician_id,
    sum(amount) filter (where transaction_type = 'sale_credit') as sale_credit,
    sum(amount) filter (where transaction_type = 'supply_debit') as supply_debit,
    sum(amount) filter (where transaction_type = 'adjustment') as adjustment
  from public.technician_account_transactions
  group by technician_id
) due on due.technician_id = t.id;

-- Low stock alert (main warehouse only, admin only).
create view public.low_stock_products
  with (security_invoker = true) as
select p.id as product_id, p.name, p.sku, p.min_stock, coalesce(ws.quantity, 0) as current_quantity
from public.products p
left join public.warehouse_stock ws on ws.product_id = p.id
where p.is_active = true and coalesce(ws.quantity, 0) <= p.min_stock;

-- Live maintenance queue with position computed on every read, never stored.
-- Admin sees the whole queue; a technician sees waiting requests + their own
-- assigned ones (per the maintenance_requests RLS policy); a customer's own
-- position must NOT be read from this view (RLS would only return their own
-- row, making row_number() always 1) — use rpc_my_maintenance_position()
-- instead, which is a SECURITY DEFINER function built exactly for that.
create view public.maintenance_queue_view
  with (security_invoker = true) as
select
  mr.*,
  row_number() over (order by mr.created_at asc) as queue_position
from public.maintenance_requests mr
where mr.status in ('waiting', 'assigned', 'in_progress')
order by mr.created_at asc;

-- Daily / monthly sales summary (orders + technician sales combined), admin only.
create view public.daily_sales_summary
  with (security_invoker = true) as
select day, sum(revenue)::numeric(14,2) as revenue, sum(cogs)::numeric(14,2) as cogs
from (
  select date_trunc('day', o.created_at) as day,
    sum(oi.line_total) as revenue,
    sum(oi.quantity * oi.unit_cost_snapshot) as cogs
  from public.orders o
  join public.order_items oi on oi.order_id = o.id
  where o.status in ('confirmed', 'preparing', 'delivered', 'completed')
  group by 1
  union all
  select date_trunc('day', s.created_at) as day,
    sum(si.line_total) as revenue,
    sum(si.quantity * si.unit_cost_snapshot) as cogs
  from public.sales s
  join public.sale_items si on si.sale_id = s.id
  where s.status = 'completed'
  group by 1
) x
group by day
order by day desc;

create view public.monthly_sales_summary
  with (security_invoker = true) as
select date_trunc('month', day) as month,
  sum(revenue)::numeric(14,2) as revenue,
  sum(cogs)::numeric(14,2) as cogs
from public.daily_sales_summary
group by 1
order by 1 desc;
