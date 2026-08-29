-- ============================================================================
-- 0011_rls_policies.sql
--
-- Golden rule: RLS is enabled on every single table. `anon` gets nothing —
-- this is not a public storefront, every screen requires authentication.
-- `authenticated` gets SELECT (row-filtered by policy) on almost everything,
-- but table-level INSERT/UPDATE/DELETE grants are handed out only for plain
-- CRUD (admin catalog management, a user editing their own profile). Every
-- ledger / balance-affecting table has NO direct write grant at all — the
-- only way to write to it is through a SECURITY DEFINER RPC function
-- (0010_functions_triggers.sql), which runs as the table owner and therefore
-- bypasses both these grants and RLS, after doing its own auth.uid()/role
-- checks in code.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Enable RLS everywhere + revoke all default grants (clean slate)
-- ----------------------------------------------------------------------------
do $$
declare t text;
begin
  for t in
    select tablename from pg_tables where schemaname = 'public'
  loop
    execute format('alter table public.%I enable row level security', t);
    execute format('revoke all on public.%I from public, anon, authenticated', t);
  end loop;
end $$;

-- Sequences (bigserial columns) need USAGE for inserts performed by RPCs
-- (which run as owner anyway) — no grant needed to authenticated directly.

-- Every RPC function is reachable by any authenticated user; each function
-- does its own authorization check internally.
grant execute on all functions in schema public to authenticated;

-- ----------------------------------------------------------------------------
-- 2. users
-- ----------------------------------------------------------------------------
grant select on public.users to authenticated;
grant update (full_name, phone, avatar_url) on public.users to authenticated;
-- role, is_active, email are intentionally NOT grantable — only
-- rpc_admin_set_role / rpc_admin_set_active (SECURITY DEFINER) can change them.

create policy users_select on public.users for select to authenticated
  using (public.is_admin() or id = auth.uid());

create policy users_update_self on public.users for update to authenticated
  using (id = auth.uid())
  with check (id = auth.uid());

-- ----------------------------------------------------------------------------
-- 3. customers
-- ----------------------------------------------------------------------------
grant select, update (default_address, default_latitude, default_longitude, notes) on public.customers to authenticated;

create policy customers_select on public.customers for select to authenticated
  using (
    public.is_admin()
    or id = auth.uid()
    or (public.is_technician() and (
      -- a technician only sees the profile of a customer tied to work
      -- actually assigned to them (maintenance) or sold to by them
      -- (bag sale to a registered customer) — never the full customer list.
      id in (select customer_id from public.maintenance_requests where assigned_technician_id = auth.uid())
      or id in (select customer_id from public.sales where technician_id = auth.uid() and customer_id is not null)
    ))
  );

create policy customers_update_self on public.customers for update to authenticated
  using (id = auth.uid())
  with check (id = auth.uid());

grant select on public.customer_accounts to authenticated;
create policy customer_accounts_select on public.customer_accounts for select to authenticated
  using (public.is_admin() or id = auth.uid());

grant select on public.customer_account_transactions to authenticated;
create policy cust_txn_select on public.customer_account_transactions for select to authenticated
  using (public.is_admin() or customer_id = auth.uid());
-- no insert/update/delete grant: written only by rpc_* functions.

-- ----------------------------------------------------------------------------
-- 4. technicians / technician_bags / technician_bag_stock / accounts
-- ----------------------------------------------------------------------------
grant select on public.technicians to authenticated;
grant update (employee_code, hire_date, is_active) on public.technicians to authenticated;
create policy technicians_select on public.technicians for select to authenticated
  using (public.is_admin() or id = auth.uid());
  -- a technician cannot see other technicians' profiles (keeps summary views
  -- correctly scoped per NOTE in 0009_views.sql).
create policy technicians_update on public.technicians for update to authenticated
  using (public.is_admin()) with check (public.is_admin());

grant select on public.technician_bags to authenticated;
create policy technician_bags_select on public.technician_bags for select to authenticated
  using (public.is_admin() or technician_id = auth.uid());

grant select on public.technician_bag_stock to authenticated;
create policy bag_stock_select on public.technician_bag_stock for select to authenticated
  using (
    public.is_admin()
    or technician_bag_id in (select id from public.technician_bags where technician_id = auth.uid())
  );
-- no direct write grant: only apply_stock_movement() (SECURITY DEFINER) mutates this.

grant select on public.technician_accounts to authenticated;
create policy technician_accounts_select on public.technician_accounts for select to authenticated
  using (public.is_admin() or id = auth.uid());

grant select on public.technician_account_transactions to authenticated;
create policy tech_txn_select on public.technician_account_transactions for select to authenticated
  using (public.is_admin() or technician_id = auth.uid());

grant select on public.technician_supplies to authenticated;
create policy tech_supplies_select on public.technician_supplies for select to authenticated
  using (public.is_admin() or technician_id = auth.uid());

-- ----------------------------------------------------------------------------
-- 5. Catalog: product_categories, products, product_images
--    Plain CRUD by admin is fine here — no financial atomicity concerns.
-- ----------------------------------------------------------------------------
grant select on public.product_categories to authenticated;
grant insert, update, delete on public.product_categories to authenticated;
create policy categories_select on public.product_categories for select to authenticated using (true);
create policy categories_write on public.product_categories for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

grant select on public.products to authenticated;
grant insert, update, delete on public.products to authenticated;
create policy products_select on public.products for select to authenticated
  using (is_active or public.is_admin());
create policy products_write on public.products for all to authenticated
  using (public.is_admin()) with check (public.is_admin());
-- NOTE: the customer app should query the `products_public` view (no
-- cost_price column at all) rather than this table directly.

grant select on public.products_public to authenticated;

grant select on public.product_images to authenticated;
grant insert, update, delete on public.product_images to authenticated;
create policy product_images_select on public.product_images for select to authenticated using (true);
create policy product_images_write on public.product_images for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

-- ----------------------------------------------------------------------------
-- 6. Warehouses / warehouse_stock / stock_movements
-- ----------------------------------------------------------------------------
grant select on public.warehouses to authenticated;
grant insert, update on public.warehouses to authenticated;
create policy warehouses_select on public.warehouses for select to authenticated using (public.is_admin());
create policy warehouses_write on public.warehouses for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

grant select on public.warehouse_stock to authenticated;
create policy warehouse_stock_select on public.warehouse_stock for select to authenticated
  using (public.is_admin());
-- no direct write grant: only apply_stock_movement() mutates this.

grant select on public.stock_movements to authenticated;
create policy stock_movements_select on public.stock_movements for select to authenticated
  using (
    public.is_admin()
    or (public.is_technician() and (
      from_location_id in (select id from public.technician_bags where technician_id = auth.uid())
      or to_location_id in (select id from public.technician_bags where technician_id = auth.uid())
    ))
  );
-- no insert/update/delete grant: only rpc_* functions insert here; the table
-- also self-blocks UPDATE/DELETE via trg_stock_movements_no_update.

-- ----------------------------------------------------------------------------
-- 7. Orders / order_items
-- ----------------------------------------------------------------------------
grant select on public.orders to authenticated;
create policy orders_select on public.orders for select to authenticated
  using (public.is_admin() or customer_id = auth.uid());
-- no insert/update grant: rpc_create_order / rpc_confirm_order / etc only.

grant select on public.order_items to authenticated;
create policy order_items_select on public.order_items for select to authenticated
  using (
    public.is_admin()
    or order_id in (select id from public.orders where customer_id = auth.uid())
  );

-- ----------------------------------------------------------------------------
-- 8. Maintenance
-- ----------------------------------------------------------------------------
grant select on public.maintenance_requests to authenticated;
create policy maintenance_select on public.maintenance_requests for select to authenticated
  using (
    public.is_admin()
    or customer_id = auth.uid()
    or assigned_technician_id = auth.uid()
    or (public.is_technician() and status = 'waiting')
  );
-- no insert/update grant: rpc_create_maintenance_request / rpc_assign_maintenance /
-- rpc_start_maintenance / rpc_complete_maintenance / rpc_cancel_maintenance only.

grant select, insert on public.maintenance_images to authenticated;
create policy maintenance_images_select on public.maintenance_images for select to authenticated
  using (
    public.is_admin()
    or maintenance_request_id in (
      select id from public.maintenance_requests
      where customer_id = auth.uid() or assigned_technician_id = auth.uid()
    )
  );
create policy maintenance_images_insert on public.maintenance_images for insert to authenticated
  with check (
    maintenance_request_id in (
      select id from public.maintenance_requests
      where customer_id = auth.uid() or assigned_technician_id = auth.uid() or public.is_admin()
    )
  );

grant select on public.maintenance_status_history to authenticated;
create policy maintenance_history_select on public.maintenance_status_history for select to authenticated
  using (
    public.is_admin()
    or maintenance_request_id in (
      select id from public.maintenance_requests
      where customer_id = auth.uid() or assigned_technician_id = auth.uid()
    )
  );
-- writes only via log_maintenance_status_change() trigger.

-- ----------------------------------------------------------------------------
-- 9. Sales / sale_items (technician direct sales)
-- ----------------------------------------------------------------------------
grant select on public.sales to authenticated;
create policy sales_select on public.sales for select to authenticated
  using (public.is_admin() or technician_id = auth.uid());
-- no insert grant: rpc_technician_sale only.

grant select on public.sale_items to authenticated;
create policy sale_items_select on public.sale_items for select to authenticated
  using (
    public.is_admin()
    or sale_id in (select id from public.sales where technician_id = auth.uid())
  );

-- ----------------------------------------------------------------------------
-- 10. Cashbox / expenses
-- ----------------------------------------------------------------------------
grant select on public.cashboxes to authenticated;
create policy cashboxes_select on public.cashboxes for select to authenticated using (public.is_admin());

grant select on public.cash_transactions to authenticated;
create policy cash_txn_select on public.cash_transactions for select to authenticated using (public.is_admin());
-- no write grant: rpc_* functions only (sale confirmation, supply, expense, refund).

grant select on public.expense_categories to authenticated;
grant insert, update on public.expense_categories to authenticated;
create policy expense_categories_select on public.expense_categories for select to authenticated
  using (public.is_admin());
create policy expense_categories_write on public.expense_categories for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

grant select on public.expenses to authenticated;
create policy expenses_select on public.expenses for select to authenticated using (public.is_admin());
-- no insert grant: rpc_record_expense only (keeps expenses <-> cash_transactions atomic).

-- ----------------------------------------------------------------------------
-- 11. Inventory counts
-- ----------------------------------------------------------------------------
grant select on public.inventory_counts to authenticated;
create policy inventory_counts_select on public.inventory_counts for select to authenticated
  using (public.is_admin());

grant select on public.inventory_count_items to authenticated;
create policy inventory_count_items_select on public.inventory_count_items for select to authenticated
  using (public.is_admin());
-- all writes via rpc_start_inventory_count / rpc_save_inventory_count_item /
-- rpc_complete_inventory_count.

-- ----------------------------------------------------------------------------
-- 12. Notifications
-- ----------------------------------------------------------------------------
grant select, update (is_read) on public.notifications to authenticated;
create policy notifications_select on public.notifications for select to authenticated
  using (user_id = auth.uid());
create policy notifications_update_self on public.notifications for update to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());
-- inserts only via notify_user() / notify_all_admins() (SECURITY DEFINER).

-- ----------------------------------------------------------------------------
-- 13. Audit logs — admin read-only, no writes ever from a client role.
-- ----------------------------------------------------------------------------
grant select on public.audit_logs to authenticated;
create policy audit_logs_select on public.audit_logs for select to authenticated
  using (public.is_admin());

-- ----------------------------------------------------------------------------
-- 14. Reporting views — grant SELECT; RLS on the underlying tables (combined
--     with `security_invoker = true` from 0009) does the actual row filtering.
-- ----------------------------------------------------------------------------
grant select on
  public.cashbox_balances,
  public.customer_account_summary,
  public.technician_bag_value,
  public.warehouse_stock_value,
  public.technician_account_summary,
  public.low_stock_products,
  public.maintenance_queue_view,
  public.daily_sales_summary,
  public.monthly_sales_summary
to authenticated;
