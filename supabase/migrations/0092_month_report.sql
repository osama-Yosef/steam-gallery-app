-- ============================================================================
-- 0092_month_report.sql
--
-- rpc_month_report: the whole month on one page, admin only. Read-only.
--
-- For the Cairo calendar month of p_month:
--   sales        invoice totals, as "مبيعات الشهر" shows them: completed sales
--                (walk-in and technicians') plus confirmed+ online orders —
--                after every discount and return. An online order's total
--                includes its approved shipping fee.
--   cost         what was sold cost: the cost snapshot of what stayed sold.
--   expenses     by expense_date. Salaries are in here at what was earned;
--                advances are not (they are owed back, 0081).
--   purchases    supplier invoices by invoice date.
--   payments     paid to suppliers in the month.
--   gross_profit = sales - cost
--   net_profit   = gross_profit - expenses
--
-- Purchases don't reduce profit: goods reach it through `cost`, when sold.
-- A return counts against the month of its invoice.
--
-- As of now, whichever month is asked for:
--   supplier_debt  what the shop still owes its suppliers.
--   stock          warehouse and technicians' bags at current cost price.
--
-- Also fixed: a salary's expense was dated current_date, the server's UTC
-- day, so one paid in the first hours of the 1st in Cairo landed in the
-- previous month. Patched in place, like 0086.
-- ============================================================================

do $patch$
declare
  v_fn regprocedure;
  v_def text;
begin
  foreach v_fn in array array[
    'public.rpc_pay_salary(uuid, date, numeric, numeric, numeric, text, text)'::regprocedure,
    'public.rpc_edit_payroll(uuid, numeric, numeric, numeric, text)'::regprocedure
  ] loop
    v_def := pg_get_functiondef(v_fn);
    if strpos(v_def, 'current_date') = 0 then
      raise exception '0092: no current_date in %', v_fn;
    end if;
    execute replace(v_def, 'current_date', $s$(now() at time zone 'Africa/Cairo')::date$s$);
  end loop;
end
$patch$;

create or replace function public.rpc_month_report(p_month date default null)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare
  v_month date := date_trunc('month',
    coalesce(p_month, (now() at time zone 'Africa/Cairo')::date))::date;
  v_from timestamptz := v_month::timestamp at time zone 'Africa/Cairo';
  v_to timestamptz := (v_month + interval '1 month')::timestamp at time zone 'Africa/Cairo';
  v_walk_in numeric(14,2);
  v_technician numeric(14,2);
  v_online numeric(14,2);
  v_invoices int;
  v_sale_cost numeric(14,2);
  v_order_cost numeric(14,2);
  v_sales numeric(14,2);
  v_cost numeric(14,2);
  v_expenses numeric(14,2);
  v_categories jsonb;
  v_purchases numeric(14,2);
  v_purchase_count int;
  v_payments numeric(14,2);
  v_debt numeric(14,2);
  v_debts jsonb;
  v_warehouse numeric(14,2);
  v_bags numeric(14,2);
begin
  if not public.is_admin() then raise exception 'FORBIDDEN'; end if;

  select
    coalesce(sum(total) filter (where technician_id is null), 0),
    coalesce(sum(total) filter (where technician_id is not null), 0),
    count(*)
  into v_walk_in, v_technician, v_invoices
  from public.sales
  where status = 'completed' and created_at >= v_from and created_at < v_to;

  select coalesce(sum((si.quantity - si.returned_quantity) * si.unit_cost_snapshot), 0)
  into v_sale_cost
  from public.sales s
  join public.sale_items_with_returns si on si.sale_id = s.id
  where s.status = 'completed' and s.created_at >= v_from and s.created_at < v_to;

  select coalesce(sum(total), 0), v_invoices + count(*) into v_online, v_invoices
  from public.orders
  where status in ('confirmed', 'preparing', 'delivered', 'completed')
    and created_at >= v_from and created_at < v_to;

  select coalesce(sum(oi.quantity * oi.unit_cost_snapshot), 0) into v_order_cost
  from public.orders o
  join public.order_items oi on oi.order_id = o.id
  where o.status in ('confirmed', 'preparing', 'delivered', 'completed')
    and o.created_at >= v_from and o.created_at < v_to;

  v_sales := v_walk_in + v_technician + v_online;
  v_cost := v_sale_cost + v_order_cost;

  select coalesce(sum(x.total), 0),
         coalesce(jsonb_agg(jsonb_build_object('name', x.name, 'total', x.total) order by x.total desc), '[]'::jsonb)
  into v_expenses, v_categories
  from (
    select c.name, sum(e.amount)::numeric(14,2) as total
    from public.expenses e
    join public.expense_categories c on c.id = e.category_id
    where e.expense_date >= v_month and e.expense_date < v_month + interval '1 month'
    group by c.name
  ) x;

  select coalesce(sum(total), 0), count(*) into v_purchases, v_purchase_count
  from public.purchase_invoices
  where invoice_date >= v_month and invoice_date < v_month + interval '1 month';

  select coalesce(sum(amount), 0) into v_payments
  from public.supplier_payments
  where created_at >= v_from and created_at < v_to;

  select coalesce(sum(x.balance), 0),
         coalesce(jsonb_agg(jsonb_build_object('name', x.name, 'balance', x.balance) order by x.balance desc), '[]'::jsonb)
  into v_debt, v_debts
  from (select name, balance from public.supplier_balances where balance > 0) x;

  select coalesce(sum(stock_value), 0) into v_warehouse from public.warehouse_stock_value;
  select coalesce(sum(bag_value), 0) into v_bags from public.technician_bag_value;

  return jsonb_build_object(
    'month', v_month,
    'sales', v_sales,
    'sales_walk_in', v_walk_in,
    'sales_technician', v_technician,
    'sales_online', v_online,
    'invoices', v_invoices,
    'cost', v_cost,
    'gross_profit', v_sales - v_cost,
    'expenses', v_expenses,
    'expense_categories', v_categories,
    'net_profit', v_sales - v_cost - v_expenses,
    'purchases', v_purchases,
    'purchase_invoices', v_purchase_count,
    'supplier_payments', v_payments,
    'supplier_debt', v_debt,
    'supplier_debts', v_debts,
    'stock_warehouse', v_warehouse,
    'stock_bags', v_bags
  );
end;
$$;

insert into private.rpc_allowlist (function_name, note) values ('rpc_month_report', 'admin')
on conflict (function_name) do nothing;

select private.apply_function_grants();
notify pgrst, 'reload schema';
