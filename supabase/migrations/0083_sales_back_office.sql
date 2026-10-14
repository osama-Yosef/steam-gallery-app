-- ============================================================================
-- 0083_sales_back_office.sql
--
-- The sales role gets the shop's back office, the same as admin: the full
-- warehouse (stock, purchase invoices, suppliers, opening stock, issuing to
-- technicians, technician bags and accounts, stock counts), products and
-- categories, employees and payroll, customers' accounts and wallets — and
-- with them its own dashboard (cashbox balance, today's sales and expenses,
-- technician dues, low stock, customer debts).
--
-- This reverses 0047's lockdown of products/warehouse for sales. Still
-- admin-only: users and roles, app settings, service areas, the audit log,
-- reports, maintenance management, and expense categories.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Read access — every table behind those screens.
-- ----------------------------------------------------------------------------

-- Names and phones of customers, technicians and staff on every list.
alter policy users_select on public.users
  using (public.is_admin() or public.is_sales() or id = auth.uid());

-- Customers, their accounts (debts) and wallets.
alter policy customers_select on public.customers
  using (
    public.is_admin() or public.is_sales() or id = auth.uid()
    or (public.is_technician() and (
      id in (select customer_id from public.maintenance_requests where assigned_technician_id = auth.uid())
      or id in (select customer_id from public.sales where technician_id = auth.uid() and customer_id is not null)
    ))
  );
alter policy customer_accounts_select on public.customer_accounts
  using (public.is_admin() or public.is_sales() or id = auth.uid());
alter policy cust_txn_select on public.customer_account_transactions
  using (public.is_admin() or public.is_sales() or customer_id = auth.uid());
alter policy customer_addresses_select on public.customer_addresses
  using (public.is_admin() or public.is_sales() or (customer_id = auth.uid() and is_active));
alter policy wallets_select on public.wallets
  using (customer_id = auth.uid() or public.is_admin() or public.is_sales());
alter policy wallet_transactions_select on public.wallet_transactions
  using (
    public.is_admin() or public.is_sales()
    or wallet_id in (select id from public.wallets where customer_id = auth.uid())
  );

-- Warehouse: locations, movement history, stock counts.
alter policy warehouses_select on public.warehouses
  using (public.is_admin() or public.is_sales());
alter policy stock_movements_select on public.stock_movements
  using (
    public.is_admin() or public.is_sales()
    or (public.is_technician() and (
      from_location_id in (select id from public.technician_bags where technician_id = auth.uid())
      or to_location_id in (select id from public.technician_bags where technician_id = auth.uid())
    ))
  );
alter policy inventory_counts_select on public.inventory_counts
  using (public.is_admin() or public.is_sales());
alter policy inventory_count_items_select on public.inventory_count_items
  using (public.is_admin() or public.is_sales());

-- Technicians: bags, accounts (dues), supplies.
alter policy technicians_select on public.technicians
  using (public.is_admin() or public.is_sales() or id = auth.uid());
alter policy technician_bags_select on public.technician_bags
  using (public.is_admin() or public.is_sales() or technician_id = auth.uid());
alter policy bag_stock_select on public.technician_bag_stock
  using (
    public.is_admin() or public.is_sales()
    or technician_bag_id in (select id from public.technician_bags where technician_id = auth.uid())
  );
alter policy technician_accounts_select on public.technician_accounts
  using (public.is_admin() or public.is_sales() or id = auth.uid());
alter policy tech_txn_select on public.technician_account_transactions
  using (public.is_admin() or public.is_sales() or technician_id = auth.uid());
alter policy tech_supplies_select on public.technician_supplies
  using (public.is_admin() or public.is_sales() or technician_id = auth.uid());

-- Purchase invoices and suppliers.
alter policy purchase_invoices_select on public.purchase_invoices
  using (public.is_admin() or public.is_sales());
alter policy purchase_invoice_items_select on public.purchase_invoice_items
  using (public.is_admin() or public.is_sales());
alter policy suppliers_select on public.suppliers
  using (public.is_admin() or public.is_sales());
alter policy supplier_payments_select on public.supplier_payments
  using (public.is_admin() or public.is_sales());

-- Employees: advances and payrolls are written by RPCs only.
alter policy employee_advances_select on public.employee_advances
  using (public.is_admin() or public.is_sales());
alter policy employee_payrolls_select on public.employee_payrolls
  using (public.is_admin() or public.is_sales());

-- ----------------------------------------------------------------------------
-- 2. Direct writes — records the screens edit in place.
-- ----------------------------------------------------------------------------
alter policy employees_admin on public.employees
  using (public.is_admin() or public.is_sales())
  with check (public.is_admin() or public.is_sales());
alter policy employee_attendance_admin on public.employee_attendance
  using (public.is_admin() or public.is_sales())
  with check (public.is_admin() or public.is_sales());

alter policy products_write on public.products
  using (public.is_admin() or public.is_sales())
  with check (public.is_admin() or public.is_sales());
alter policy categories_write on public.product_categories
  using (public.is_admin() or public.is_sales())
  with check (public.is_admin() or public.is_sales());
alter policy product_images_write on public.product_images
  using (public.is_admin() or public.is_sales())
  with check (public.is_admin() or public.is_sales());
alter policy product_options_write on public.product_options
  using (public.is_admin() or public.is_sales())
  with check (public.is_admin() or public.is_sales());

-- Product photos.
alter policy products_admin_write on storage.objects
  with check (bucket_id = 'products' and (public.is_admin() or public.is_sales()));
alter policy products_admin_update on storage.objects
  using (bucket_id = 'products' and (public.is_admin() or public.is_sales()));
alter policy products_admin_delete on storage.objects
  using (bucket_id = 'products' and (public.is_admin() or public.is_sales()));

-- ----------------------------------------------------------------------------
-- 3. RPCs — each opens with exactly one `public.is_admin()` role check
--    (rpc_technician_supply's also lets a technician supply for themselves).
--    That check becomes `(public.is_admin() or public.is_sales())`; the rest
--    of each body is left as its latest migration wrote it. A function that
--    no longer has exactly one such check stops this migration rather than
--    being guessed at.
-- ----------------------------------------------------------------------------
do $$
declare
  v_name text;
  v_fn record;
  v_def text;
  v_count int;
begin
  foreach v_name in array array[
    -- warehouse
    'rpc_admin_opening_stock', 'rpc_receive_purchase', 'rpc_issue_stock_to_technician',
    'rpc_start_inventory_count', 'rpc_save_inventory_count_item', 'rpc_complete_inventory_count',
    'rpc_technician_supply', 'rpc_admin_review_technician_supply',
    -- purchase invoices and suppliers
    'rpc_create_purchase_invoice', 'rpc_pay_supplier',
    -- employees
    'rpc_employee_advance', 'rpc_payroll_preview', 'rpc_pay_salary',
    -- products
    'rpc_admin_set_assembly'
  ] loop
    v_count := 0;
    for v_fn in
      select p.oid from pg_proc p join pg_namespace n on n.oid = p.pronamespace
      where n.nspname = 'public' and p.proname = v_name
    loop
      v_def := pg_get_functiondef(v_fn.oid);
      if (length(v_def) - length(replace(v_def, 'public.is_admin()', ''))) / length('public.is_admin()') <> 1 then
        raise exception '0083: % does not have exactly one is_admin() check', v_name;
      end if;
      execute replace(v_def, 'public.is_admin()', '(public.is_admin() or public.is_sales())');
      v_count := v_count + 1;
    end loop;
    if v_count = 0 then raise exception '0083: function % not found', v_name; end if;
  end loop;
end;
$$;

select private.apply_function_grants();
notify pgrst, 'reload schema';
