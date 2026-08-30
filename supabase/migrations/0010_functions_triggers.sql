-- ============================================================================
-- 0010_functions_triggers.sql
-- Auth/role helpers, auto-provisioning trigger, notification helper,
-- audit trigger wiring, the stock-movement ledger applier, and every
-- security-definer RPC function that performs a sensitive business
-- transaction. Flutter NEVER writes directly to a ledger/balance table;
-- it only calls the functions below via supabase.rpc(...).
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Role / auth helpers (used everywhere, including RLS policies)
-- ----------------------------------------------------------------------------
create or replace function public.auth_role() returns text
language sql stable as $$
  select coalesce(auth.jwt() -> 'app_metadata' ->> 'role', 'anon');
$$;

create or replace function public.is_admin() returns boolean
language sql stable as $$ select public.auth_role() = 'admin'; $$;

create or replace function public.is_technician() returns boolean
language sql stable as $$ select public.auth_role() = 'technician'; $$;

create or replace function public.is_customer() returns boolean
language sql stable as $$ select public.auth_role() = 'customer'; $$;

-- ----------------------------------------------------------------------------
-- 2. Auto-provision public.users (+ role-specific extension rows) whenever
--    a new auth.users row is created. role/employee_code come from
--    raw_app_meta_data set by the server (self sign-up -> defaults to
--    'customer'; technician/admin creation goes through the create-user
--    Edge Function which sets app_metadata.role explicitly).
-- ----------------------------------------------------------------------------
create or replace function public.handle_new_auth_user() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  v_role user_role := coalesce((new.raw_app_meta_data ->> 'role')::user_role, 'customer');
  -- Phone+password is the primary signup method (no email required), so the
  -- fallback chain must not depend on new.email ever being present.
  v_full_name text := coalesce(
    new.raw_user_meta_data ->> 'full_name',
    new.phone,
    new.email,
    'مستخدم جديد'
  );
  v_employee_code text;
begin
  insert into public.users (id, role, full_name, phone, email)
  values (new.id, v_role, v_full_name, coalesce(new.phone, new.raw_user_meta_data ->> 'phone'), new.email);

  if v_role = 'customer' then
    insert into public.customers (id) values (new.id);
    insert into public.customer_accounts (id) values (new.id);
  elsif v_role = 'technician' then
    v_employee_code := coalesce(new.raw_user_meta_data ->> 'employee_code', 'T-' || substr(new.id::text, 1, 8));
    insert into public.technicians (id, employee_code, created_by)
      values (new.id, v_employee_code, (new.raw_user_meta_data ->> 'created_by')::uuid);
    insert into public.technician_bags (technician_id) values (new.id);
    insert into public.technician_accounts (id) values (new.id);
  end if;

  return new;
end;
$$;

create trigger trg_on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_auth_user();

-- ----------------------------------------------------------------------------
-- 3. Notification helper (internal, used by other functions/triggers)
-- ----------------------------------------------------------------------------
create or replace function public.notify_user(
  p_user_id uuid, p_type text, p_title text, p_body text, p_data jsonb default '{}'::jsonb
) returns void language plpgsql security definer set search_path = public as $$
begin
  insert into public.notifications (user_id, type, title, body, data)
  values (p_user_id, p_type, p_title, p_body, p_data);
end;
$$;

create or replace function public.notify_all_admins(
  p_type text, p_title text, p_body text, p_data jsonb default '{}'::jsonb
) returns void language plpgsql security definer set search_path = public as $$
begin
  insert into public.notifications (user_id, type, title, body, data)
  select id, p_type, p_title, p_body, p_data from public.users where role = 'admin' and is_active;
end;
$$;

-- ----------------------------------------------------------------------------
-- 4. Generic audit trigger (attached selectively below to sensitive tables)
-- ----------------------------------------------------------------------------
create or replace function public.audit_trigger() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into public.audit_logs (actor_id, action, table_name, record_id, old_data, new_data)
  values (
    auth.uid(), TG_OP, TG_TABLE_NAME,
    coalesce((case when TG_OP = 'DELETE' then old.id else new.id end), null),
    case when TG_OP != 'INSERT' then to_jsonb(old) end,
    case when TG_OP != 'DELETE' then to_jsonb(new) end
  );
  return coalesce(new, old);
end;
$$;

create trigger trg_audit_products after insert or update or delete on public.products
  for each row execute function public.audit_trigger();
create trigger trg_audit_categories after insert or update or delete on public.product_categories
  for each row execute function public.audit_trigger();
create trigger trg_audit_users after update or delete on public.users
  for each row execute function public.audit_trigger();
create trigger trg_audit_technicians after insert or update or delete on public.technicians
  for each row execute function public.audit_trigger();
create trigger trg_audit_expenses after insert on public.expenses
  for each row execute function public.audit_trigger();
create trigger trg_audit_stock_movements after insert on public.stock_movements
  for each row execute function public.audit_trigger();
create trigger trg_audit_sales after insert on public.sales
  for each row execute function public.audit_trigger();
create trigger trg_audit_inventory_counts after update on public.inventory_counts
  for each row execute function public.audit_trigger();

-- ----------------------------------------------------------------------------
-- 5. Stock ledger applier — the ONLY place warehouse_stock /
--    technician_bag_stock are ever mutated. Each UPDATE below is a single
--    atomic statement with `quantity >= x` in the WHERE clause, so two
--    concurrent sales of the last unit cannot both succeed (classic
--    optimistic/atomic decrement pattern — no explicit FOR UPDATE needed
--    because the row lock is implicit in the UPDATE itself).
-- ----------------------------------------------------------------------------
create or replace function public.apply_stock_movement() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  v_rows int;
begin
  -- Decrement the source location, if any.
  if new.from_location_type = 'warehouse' then
    update public.warehouse_stock
      set quantity = quantity - new.quantity
      where warehouse_id = new.from_location_id and product_id = new.product_id
        and quantity >= new.quantity;
    get diagnostics v_rows = row_count;
    if v_rows = 0 then
      raise exception 'INSUFFICIENT_STOCK: warehouse % product %', new.from_location_id, new.product_id;
    end if;
  elsif new.from_location_type = 'technician_bag' then
    update public.technician_bag_stock
      set quantity = quantity - new.quantity
      where technician_bag_id = new.from_location_id and product_id = new.product_id
        and quantity >= new.quantity;
    get diagnostics v_rows = row_count;
    if v_rows = 0 then
      raise exception 'INSUFFICIENT_STOCK: technician_bag % product %', new.from_location_id, new.product_id;
    end if;
  end if;

  -- Increment the destination location, if any (upsert).
  if new.to_location_type = 'warehouse' then
    insert into public.warehouse_stock (warehouse_id, product_id, quantity)
      values (new.to_location_id, new.product_id, new.quantity)
      on conflict (warehouse_id, product_id)
      do update set quantity = public.warehouse_stock.quantity + excluded.quantity;
  elsif new.to_location_type = 'technician_bag' then
    insert into public.technician_bag_stock (technician_bag_id, product_id, quantity)
      values (new.to_location_id, new.product_id, new.quantity)
      on conflict (technician_bag_id, product_id)
      do update set quantity = public.technician_bag_stock.quantity + excluded.quantity;
  end if;

  return new;
end;
$$;

create trigger trg_apply_stock_movement
  after insert on public.stock_movements
  for each row execute function public.apply_stock_movement();

-- Low-stock notification: fires only when crossing the threshold downward.
create or replace function public.check_low_stock() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  v_min int;
  v_name text;
begin
  select min_stock, name into v_min, v_name from public.products where id = new.product_id;
  if new.quantity <= v_min and (old.quantity is null or old.quantity > v_min) then
    perform public.notify_all_admins(
      'low_stock', 'مخزون منخفض',
      format('%s وصل إلى %s قطعة (الحد الأدنى %s)', v_name, new.quantity, v_min),
      jsonb_build_object('product_id', new.product_id, 'quantity', new.quantity)
    );
  end if;
  return new;
end;
$$;

create trigger trg_warehouse_low_stock
  after insert or update on public.warehouse_stock
  for each row execute function public.check_low_stock();

-- ----------------------------------------------------------------------------
-- 6. Maintenance status history + notifications — automatic on any status
--    change, regardless of which RPC performed it.
-- ----------------------------------------------------------------------------
create or replace function public.log_maintenance_status_change() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if TG_OP = 'INSERT' or old.status is distinct from new.status then
    insert into public.maintenance_status_history (maintenance_request_id, old_status, new_status, changed_by, notes)
    values (new.id, case when TG_OP = 'INSERT' then null else old.status end, new.status, auth.uid(), null);

    if new.status = 'assigned' and new.assigned_technician_id is not null then
      perform public.notify_user(new.assigned_technician_id, 'maintenance_new', 'طلب صيانة جديد',
        format('تم إسناد طلب صيانة #%s لك', new.ticket_number),
        jsonb_build_object('maintenance_request_id', new.id));
    end if;

    if new.status = 'completed' then
      perform public.notify_user(new.customer_id, 'maintenance_completed', 'تم تنفيذ الصيانة',
        format('تم الانتهاء من طلب الصيانة #%s', new.ticket_number),
        jsonb_build_object('maintenance_request_id', new.id));
    end if;
  end if;
  return new;
end;
$$;

create trigger trg_maintenance_status_change
  after insert or update on public.maintenance_requests
  for each row execute function public.log_maintenance_status_change();

-- ============================================================================
-- 7. RPC FUNCTIONS — the only write path for every sensitive operation.
-- ============================================================================

-- 7.1 Admin: change a user's role (the ONLY legitimate way role ever changes).
create or replace function public.rpc_admin_set_role(p_user_id uuid, p_new_role user_role)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_admin() then raise exception 'FORBIDDEN'; end if;
  update public.users set role = p_new_role where id = p_user_id;
  update auth.users
    set raw_app_meta_data = raw_app_meta_data || jsonb_build_object('role', p_new_role::text)
    where id = p_user_id;
end;
$$;

-- 7.2 Admin: activate/deactivate a user (soft delete).
create or replace function public.rpc_admin_set_active(p_user_id uuid, p_is_active boolean)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_admin() then raise exception 'FORBIDDEN'; end if;
  update public.users set is_active = p_is_active where id = p_user_id;
end;
$$;

-- ----------------------------------------------------------------------------
-- 7.3 Orders
-- ----------------------------------------------------------------------------
create or replace function public.rpc_create_order(
  p_customer_id uuid, p_items jsonb, p_delivery_address text,
  p_latitude numeric, p_longitude numeric, p_notes text, p_client_request_id uuid
) returns uuid language plpgsql security definer set search_path = public as $$
declare
  v_order_id uuid;
  v_existing uuid;
  v_item jsonb;
  v_product record;
  v_subtotal numeric(12,2) := 0;
  v_line_total numeric(12,2);
begin
  if not (public.is_admin() or (public.is_customer() and p_customer_id = auth.uid())) then
    raise exception 'FORBIDDEN';
  end if;

  if p_client_request_id is not null then
    select id into v_existing from public.orders where client_request_id = p_client_request_id;
    if v_existing is not null then return v_existing; end if;
  end if;

  insert into public.orders (customer_id, status, delivery_address, delivery_latitude, delivery_longitude, notes, client_request_id)
  values (p_customer_id, 'pending', p_delivery_address, p_latitude, p_longitude, p_notes, p_client_request_id)
  returning id into v_order_id;

  for v_item in select * from jsonb_array_elements(p_items) loop
    select id, name, selling_price, cost_price into v_product
      from public.products where id = (v_item ->> 'product_id')::uuid and is_active for update;
    if v_product.id is null then raise exception 'PRODUCT_NOT_FOUND: %', v_item ->> 'product_id'; end if;

    v_line_total := (v_item ->> 'quantity')::int * v_product.selling_price - coalesce((v_item ->> 'discount')::numeric, 0);
    v_subtotal := v_subtotal + v_line_total;

    insert into public.order_items (order_id, product_id, product_name_snapshot, quantity, unit_price_snapshot, unit_cost_snapshot, discount)
    values (v_order_id, v_product.id, v_product.name, (v_item ->> 'quantity')::int, v_product.selling_price, v_product.cost_price, coalesce((v_item ->> 'discount')::numeric, 0));
  end loop;

  update public.orders set subtotal = v_subtotal where id = v_order_id;
  return v_order_id;
end;
$$;

create or replace function public.rpc_confirm_order(p_order_id uuid)
returns void language plpgsql security definer set search_path = public as $$
declare
  v_warehouse_id uuid;
  v_item record;
  v_customer_id uuid;
  v_total numeric(12,2);
begin
  if not public.is_admin() then raise exception 'FORBIDDEN'; end if;

  select id into v_warehouse_id from public.warehouses where type = 'main' and is_active limit 1;
  if v_warehouse_id is null then raise exception 'NO_MAIN_WAREHOUSE'; end if;

  select customer_id, total into v_customer_id, v_total from public.orders where id = p_order_id and status = 'pending' for update;
  if v_customer_id is null then raise exception 'ORDER_NOT_PENDING'; end if;

  for v_item in select * from public.order_items where order_id = p_order_id loop
    insert into public.stock_movements (product_id, movement_type, quantity, from_location_type, from_location_id, to_location_type, unit_cost, reference_type, reference_id, notes, created_by)
    values (v_item.product_id, 'sale', v_item.quantity, 'warehouse', v_warehouse_id, 'external', v_item.unit_cost_snapshot, 'order', p_order_id, 'بيع - تأكيد طلب', auth.uid());
  end loop;

  update public.orders set status = 'confirmed', confirmed_by = auth.uid() where id = p_order_id;

  insert into public.customer_account_transactions (customer_id, transaction_type, amount, order_id, notes, created_by)
  values (v_customer_id, 'order_charge', v_total, p_order_id, 'قيمة الطلب', auth.uid());

  perform public.notify_user(v_customer_id, 'order_status', 'تم تأكيد طلبك', 'جاري تجهيز طلبك الآن', jsonb_build_object('order_id', p_order_id));
end;
$$;

create or replace function public.rpc_update_order_status(p_order_id uuid, p_new_status order_status)
returns void language plpgsql security definer set search_path = public as $$
declare
  v_customer_id uuid;
begin
  if not public.is_admin() then raise exception 'FORBIDDEN'; end if;
  if p_new_status not in ('preparing', 'delivered', 'completed') then
    raise exception 'USE_DEDICATED_FUNCTION_FOR_%', p_new_status;
  end if;
  update public.orders set status = p_new_status where id = p_order_id returning customer_id into v_customer_id;
  if v_customer_id is null then raise exception 'ORDER_NOT_FOUND'; end if;
  perform public.notify_user(v_customer_id, 'order_status', 'تحديث حالة الطلب', format('حالة طلبك الآن: %s', p_new_status), jsonb_build_object('order_id', p_order_id));
end;
$$;

create or replace function public.rpc_cancel_order(p_order_id uuid, p_reason text)
returns void language plpgsql security definer set search_path = public as $$
declare
  v_order record;
  v_warehouse_id uuid;
  v_item record;
begin
  if not public.is_admin() then raise exception 'FORBIDDEN'; end if;
  select * into v_order from public.orders where id = p_order_id for update;
  if v_order.id is null then raise exception 'ORDER_NOT_FOUND'; end if;
  if v_order.status in ('completed', 'cancelled', 'returned') then raise exception 'ORDER_NOT_CANCELLABLE'; end if;

  if v_order.status != 'pending' then
    select id into v_warehouse_id from public.warehouses where type = 'main' and is_active limit 1;
    for v_item in select * from public.order_items where order_id = p_order_id loop
      insert into public.stock_movements (product_id, movement_type, quantity, from_location_type, to_location_type, to_location_id, unit_cost, reference_type, reference_id, notes, created_by)
      values (v_item.product_id, 'return_from_customer', v_item.quantity, 'external', 'warehouse', v_warehouse_id, v_item.unit_cost_snapshot, 'order', p_order_id, 'إلغاء طلب', auth.uid());
    end loop;
    if v_order.paid_amount > 0 then
      insert into public.cash_transactions (cashbox_id, transaction_type, amount, reference_type, reference_id, notes, created_by)
      select id, 'refund', -v_order.paid_amount, 'order', p_order_id, 'استرداد إلغاء طلب', auth.uid() from public.cashboxes where is_active limit 1;
    end if;
    insert into public.customer_account_transactions (customer_id, transaction_type, amount, order_id, notes, created_by)
    values (v_order.customer_id, 'return_credit', -v_order.total, p_order_id, 'إلغاء طلب', auth.uid());
  end if;

  update public.orders set status = 'cancelled', cancelled_reason = p_reason where id = p_order_id;
  perform public.notify_user(v_order.customer_id, 'order_status', 'تم إلغاء طلبك', p_reason, jsonb_build_object('order_id', p_order_id));
end;
$$;

create or replace function public.rpc_record_customer_payment(p_customer_id uuid, p_amount numeric, p_order_id uuid, p_notes text)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_admin() then raise exception 'FORBIDDEN'; end if;
  if p_amount <= 0 then raise exception 'INVALID_AMOUNT'; end if;

  insert into public.customer_account_transactions (customer_id, transaction_type, amount, order_id, notes, created_by)
  values (p_customer_id, 'payment', -p_amount, p_order_id, p_notes, auth.uid());

  insert into public.cash_transactions (cashbox_id, transaction_type, amount, reference_type, reference_id, notes, created_by)
  select id, 'sale', p_amount, 'order', p_order_id, p_notes, auth.uid() from public.cashboxes where is_active limit 1;

  if p_order_id is not null then
    update public.orders set paid_amount = paid_amount + p_amount where id = p_order_id;
  end if;
end;
$$;

-- ----------------------------------------------------------------------------
-- 7.4 Warehouse -> technician bag issue
-- ----------------------------------------------------------------------------
create or replace function public.rpc_issue_stock_to_technician(p_technician_id uuid, p_items jsonb, p_notes text)
returns void language plpgsql security definer set search_path = public as $$
declare
  v_warehouse_id uuid;
  v_bag_id uuid;
  v_item jsonb;
  v_cost numeric(12,2);
begin
  if not public.is_admin() then raise exception 'FORBIDDEN'; end if;
  select id into v_warehouse_id from public.warehouses where type = 'main' and is_active limit 1;
  select id into v_bag_id from public.technician_bags where technician_id = p_technician_id;
  if v_bag_id is null then raise exception 'TECHNICIAN_BAG_NOT_FOUND'; end if;

  for v_item in select * from jsonb_array_elements(p_items) loop
    select cost_price into v_cost from public.products where id = (v_item ->> 'product_id')::uuid;
    insert into public.stock_movements (product_id, movement_type, quantity, from_location_type, from_location_id, to_location_type, to_location_id, unit_cost, reference_type, notes, created_by)
    values ((v_item ->> 'product_id')::uuid, 'issue_to_technician', (v_item ->> 'quantity')::int, 'warehouse', v_warehouse_id, 'technician_bag', v_bag_id, v_cost, 'issue', p_notes, auth.uid());
  end loop;
end;
$$;

-- ----------------------------------------------------------------------------
-- 7.5 Technician direct sale from their bag
-- ----------------------------------------------------------------------------
create or replace function public.rpc_technician_sale(
  p_technician_id uuid, p_customer_id uuid, p_customer_name text, p_customer_phone text,
  p_items jsonb, p_payment_method payment_method, p_discount numeric, p_paid_amount numeric,
  p_client_request_id uuid, p_notes text
) returns uuid language plpgsql security definer set search_path = public as $$
declare
  v_sale_id uuid;
  v_existing uuid;
  v_bag_id uuid;
  v_item jsonb;
  v_product record;
  v_subtotal numeric(12,2) := 0;
  v_line_total numeric(12,2);
begin
  if not (public.is_admin() or (public.is_technician() and p_technician_id = auth.uid())) then
    raise exception 'FORBIDDEN';
  end if;

  if p_client_request_id is not null then
    select id into v_existing from public.sales where client_request_id = p_client_request_id;
    if v_existing is not null then return v_existing; end if;
  end if;

  select id into v_bag_id from public.technician_bags where technician_id = p_technician_id;
  if v_bag_id is null then raise exception 'TECHNICIAN_BAG_NOT_FOUND'; end if;

  insert into public.sales (technician_id, customer_id, customer_name, customer_phone, payment_method, discount, paid_amount, client_request_id)
  values (p_technician_id, p_customer_id, p_customer_name, p_customer_phone, p_payment_method, coalesce(p_discount, 0), coalesce(p_paid_amount, 0), p_client_request_id)
  returning id into v_sale_id;

  for v_item in select * from jsonb_array_elements(p_items) loop
    select id, name, selling_price, cost_price into v_product from public.products where id = (v_item ->> 'product_id')::uuid;
    v_line_total := (v_item ->> 'quantity')::int * v_product.selling_price - coalesce((v_item ->> 'discount')::numeric, 0);
    v_subtotal := v_subtotal + v_line_total;

    insert into public.sale_items (sale_id, product_id, product_name_snapshot, quantity, unit_price_snapshot, unit_cost_snapshot, discount)
    values (v_sale_id, v_product.id, v_product.name, (v_item ->> 'quantity')::int, v_product.selling_price, v_product.cost_price, coalesce((v_item ->> 'discount')::numeric, 0));

    -- Atomic decrement happens inside apply_stock_movement(); raises INSUFFICIENT_STOCK
    -- and rolls back the whole sale if the bag doesn't have enough units.
    insert into public.stock_movements (product_id, movement_type, quantity, from_location_type, from_location_id, to_location_type, unit_cost, reference_type, reference_id, notes, created_by)
    values (v_product.id, 'technician_sale', (v_item ->> 'quantity')::int, 'technician_bag', v_bag_id, 'external', v_product.cost_price, 'sale', v_sale_id, p_notes, auth.uid());
  end loop;

  update public.sales set subtotal = v_subtotal where id = v_sale_id;

  if p_payment_method = 'deferred' and p_customer_id is not null then
    insert into public.customer_account_transactions (customer_id, transaction_type, amount, notes, created_by)
    values (p_customer_id, 'order_charge', v_subtotal - coalesce(p_discount, 0), 'بيع صنايعي آجل', auth.uid());
  elsif coalesce(p_paid_amount, 0) > 0 then
    insert into public.technician_account_transactions (technician_id, transaction_type, amount, sale_id, notes, created_by)
    values (p_technician_id, 'sale_credit', p_paid_amount, v_sale_id, 'تحصيل بيع', auth.uid());
  end if;

  return v_sale_id;
end;
$$;

-- ----------------------------------------------------------------------------
-- 7.6 Technician supply (توريد) to the gallery cashbox
-- ----------------------------------------------------------------------------
create or replace function public.rpc_technician_supply(p_technician_id uuid, p_amount numeric, p_notes text)
returns uuid language plpgsql security definer set search_path = public as $$
declare
  v_supply_id uuid;
begin
  if not (public.is_admin() or (public.is_technician() and p_technician_id = auth.uid())) then
    raise exception 'FORBIDDEN';
  end if;
  if p_amount <= 0 then raise exception 'INVALID_AMOUNT'; end if;

  insert into public.technician_supplies (technician_id, amount, notes, recorded_by)
  values (p_technician_id, p_amount, p_notes, auth.uid())
  returning id into v_supply_id;

  insert into public.technician_account_transactions (technician_id, transaction_type, amount, supply_id, notes, created_by)
  values (p_technician_id, 'supply_debit', p_amount, v_supply_id, 'توريد للخزنة', auth.uid());

  insert into public.cash_transactions (cashbox_id, transaction_type, amount, reference_type, reference_id, notes, created_by)
  select id, 'technician_deposit', p_amount, 'technician_supply', v_supply_id, p_notes, auth.uid() from public.cashboxes where is_active limit 1;

  return v_supply_id;
end;
$$;

-- ----------------------------------------------------------------------------
-- 7.7 Maintenance queue
-- ----------------------------------------------------------------------------
create or replace function public.rpc_create_maintenance_request(
  p_customer_id uuid, p_customer_name text, p_phone text, p_address text,
  p_latitude numeric, p_longitude numeric, p_device_type text, p_problem_description text, p_notes text
) returns uuid language plpgsql security definer set search_path = public as $$
declare
  v_id uuid;
begin
  if not (public.is_admin() or (public.is_customer() and p_customer_id = auth.uid())) then
    raise exception 'FORBIDDEN';
  end if;

  insert into public.maintenance_requests (customer_id, customer_name, phone, address, latitude, longitude, device_type, problem_description, notes)
  values (p_customer_id, p_customer_name, p_phone, p_address, p_latitude, p_longitude, p_device_type, p_problem_description, p_notes)
  returning id into v_id;

  return v_id;
end;
$$;

create or replace function public.rpc_assign_maintenance(p_request_id uuid, p_technician_id uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_admin() then raise exception 'FORBIDDEN'; end if;
  update public.maintenance_requests
    set status = 'assigned', assigned_technician_id = p_technician_id, assigned_at = now()
    where id = p_request_id and status = 'waiting';
  if not found then raise exception 'REQUEST_NOT_WAITING'; end if;
end;
$$;

create or replace function public.rpc_start_maintenance(p_request_id uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  update public.maintenance_requests
    set status = 'in_progress', started_at = now()
    where id = p_request_id and status = 'assigned'
      and (public.is_admin() or assigned_technician_id = auth.uid());
  if not found then raise exception 'FORBIDDEN_OR_NOT_ASSIGNED'; end if;
end;
$$;

create or replace function public.rpc_complete_maintenance(p_request_id uuid, p_notes text)
returns void language plpgsql security definer set search_path = public as $$
begin
  update public.maintenance_requests
    set status = 'completed', completed_at = now(), notes = coalesce(p_notes, notes)
    where id = p_request_id and status = 'in_progress'
      and (public.is_admin() or assigned_technician_id = auth.uid());
  if not found then raise exception 'FORBIDDEN_OR_NOT_IN_PROGRESS'; end if;
end;
$$;

create or replace function public.rpc_cancel_maintenance(p_request_id uuid, p_reason text)
returns void language plpgsql security definer set search_path = public as $$
begin
  update public.maintenance_requests
    set status = 'cancelled', cancelled_at = now(), cancelled_reason = p_reason
    where id = p_request_id and status in ('waiting', 'assigned', 'in_progress')
      and (public.is_admin() or customer_id = auth.uid());
  if not found then raise exception 'FORBIDDEN_OR_NOT_CANCELLABLE'; end if;
end;
$$;

-- ----------------------------------------------------------------------------
-- 7.8 Expenses
-- ----------------------------------------------------------------------------
create or replace function public.rpc_record_expense(p_category_id uuid, p_amount numeric, p_expense_date date, p_notes text, p_attachment_url text)
returns uuid language plpgsql security definer set search_path = public as $$
declare
  v_expense_id uuid;
begin
  if not public.is_admin() then raise exception 'FORBIDDEN'; end if;
  if p_amount <= 0 then raise exception 'INVALID_AMOUNT'; end if;

  insert into public.expenses (category_id, amount, expense_date, notes, attachment_url, created_by)
  values (p_category_id, p_amount, coalesce(p_expense_date, current_date), p_notes, p_attachment_url, auth.uid())
  returning id into v_expense_id;

  insert into public.cash_transactions (cashbox_id, transaction_type, amount, reference_type, reference_id, notes, created_by)
  select id, 'expense', -p_amount, 'expense', v_expense_id, p_notes, auth.uid() from public.cashboxes where is_active limit 1;

  return v_expense_id;
end;
$$;

-- ----------------------------------------------------------------------------
-- 7.9 Purchases into the main warehouse (adding new stock)
-- ----------------------------------------------------------------------------
create or replace function public.rpc_receive_purchase(p_product_id uuid, p_quantity int, p_unit_cost numeric, p_notes text)
returns void language plpgsql security definer set search_path = public as $$
declare
  v_warehouse_id uuid;
begin
  if not public.is_admin() then raise exception 'FORBIDDEN'; end if;
  select id into v_warehouse_id from public.warehouses where type = 'main' and is_active limit 1;

  insert into public.stock_movements (product_id, movement_type, quantity, from_location_type, to_location_type, to_location_id, unit_cost, reference_type, notes, created_by)
  values (p_product_id, 'purchase', p_quantity, 'external', 'warehouse', v_warehouse_id, p_unit_cost, 'purchase', p_notes, auth.uid());

  update public.products set cost_price = p_unit_cost where id = p_product_id;
end;
$$;

-- ----------------------------------------------------------------------------
-- 7.10 Inventory counts
-- ----------------------------------------------------------------------------
create or replace function public.rpc_start_inventory_count(p_location_type location_type, p_location_id uuid, p_product_ids uuid[])
returns uuid language plpgsql security definer set search_path = public as $$
declare
  v_count_id uuid;
begin
  if not public.is_admin() then raise exception 'FORBIDDEN'; end if;

  insert into public.inventory_counts (location_type, location_id, started_by)
  values (p_location_type, p_location_id, auth.uid())
  returning id into v_count_id;

  if p_location_type = 'warehouse' then
    insert into public.inventory_count_items (inventory_count_id, product_id, system_quantity)
    select v_count_id, product_id, quantity from public.warehouse_stock
    where warehouse_id = p_location_id and (p_product_ids is null or product_id = any (p_product_ids));
  else
    insert into public.inventory_count_items (inventory_count_id, product_id, system_quantity)
    select v_count_id, product_id, quantity from public.technician_bag_stock
    where technician_bag_id = p_location_id and (p_product_ids is null or product_id = any (p_product_ids));
  end if;

  return v_count_id;
end;
$$;

create or replace function public.rpc_save_inventory_count_item(p_item_id uuid, p_actual_quantity int, p_reason text, p_notes text)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_admin() then raise exception 'FORBIDDEN'; end if;
  update public.inventory_count_items
    set actual_quantity = p_actual_quantity, reason = p_reason, notes = p_notes
    where id = p_item_id
      and inventory_count_id in (select id from public.inventory_counts where status = 'draft');
  if not found then raise exception 'ITEM_NOT_FOUND_OR_COUNT_CLOSED'; end if;
end;
$$;

create or replace function public.rpc_complete_inventory_count(p_count_id uuid)
returns void language plpgsql security definer set search_path = public as $$
declare
  v_count record;
  v_item record;
  v_cost numeric(12,2);
begin
  if not public.is_admin() then raise exception 'FORBIDDEN'; end if;
  select * into v_count from public.inventory_counts where id = p_count_id and status = 'draft' for update;
  if v_count.id is null then raise exception 'COUNT_NOT_DRAFT'; end if;

  for v_item in
    select * from public.inventory_count_items
    where inventory_count_id = p_count_id and actual_quantity is not null and difference != 0
  loop
    select cost_price into v_cost from public.products where id = v_item.product_id;
    if v_item.difference > 0 then
      insert into public.stock_movements (product_id, movement_type, quantity, from_location_type, to_location_type, to_location_id, unit_cost, reference_type, reference_id, notes, created_by)
      values (v_item.product_id, 'inventory_adjustment', v_item.difference, 'external', v_count.location_type, v_count.location_id, v_cost, 'inventory_count', p_count_id, v_item.reason, auth.uid());
    else
      insert into public.stock_movements (product_id, movement_type, quantity, from_location_type, from_location_id, to_location_type, unit_cost, reference_type, reference_id, notes, created_by)
      values (v_item.product_id, 'inventory_adjustment', abs(v_item.difference), v_count.location_type, v_count.location_id, 'external', v_cost, 'inventory_count', p_count_id, v_item.reason, auth.uid());
    end if;
  end loop;

  update public.inventory_counts set status = 'completed', completed_at = now() where id = p_count_id;
end;
$$;

-- ----------------------------------------------------------------------------
-- 7.11 Customer's own queue position. SECURITY DEFINER on purpose: it must
--      count across ALL active requests (bypassing the customer's own
--      row-level RLS restriction on maintenance_requests) but only returns a
--      number for a request the caller is actually allowed to see — never
--      exposes any other customer's data.
-- ----------------------------------------------------------------------------
create or replace function public.rpc_my_maintenance_position(p_request_id uuid)
returns table (queue_position int, people_ahead int, total_active int)
language plpgsql security definer set search_path = public as $$
declare
  v_created_at timestamptz;
  v_customer_id uuid;
  v_technician_id uuid;
  v_status maintenance_status;
begin
  select created_at, customer_id, assigned_technician_id, status
    into v_created_at, v_customer_id, v_technician_id, v_status
    from public.maintenance_requests where id = p_request_id;

  if v_created_at is null then raise exception 'REQUEST_NOT_FOUND'; end if;
  if not (public.is_admin() or v_customer_id = auth.uid() or v_technician_id = auth.uid()) then
    raise exception 'FORBIDDEN';
  end if;

  if v_status not in ('waiting', 'assigned', 'in_progress') then
    return query select 0, 0, 0;
    return;
  end if;

  return query
    select
      count(*) filter (where mr.created_at <= v_created_at)::int as queue_position,
      count(*) filter (where mr.created_at < v_created_at)::int as people_ahead,
      count(*)::int as total_active
    from public.maintenance_requests mr
    where mr.status in ('waiting', 'assigned', 'in_progress');
end;
$$;
