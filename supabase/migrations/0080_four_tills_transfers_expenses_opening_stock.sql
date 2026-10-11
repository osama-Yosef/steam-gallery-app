-- ============================================================================
-- 0080_four_tills_transfers_expenses_opening_stock.sql
--
-- 1. Four tills instead of two (0059). `kind` stays the key every RPC looks
--    a till up by ("where kind = ... and is_active"), one active till per
--    kind, so nothing that already works changes meaning:
--      cash      خزنة الدرج      — the counter drawer; cash sales land here
--      main      الخزنة الرئيسية — the safe; filled by transfers/deposits
--      transfer  حساب CIB         — bank transfer / card money
--      wallet    فودافون كاش      — e-wallet transfers (new payment method)
--    The existing cash/transfer tills keep their ledgers and are renamed.
--
-- 2. payment_method 'wallet' (0079) posts to the wallet till. The
--    "cash -> cash, anything else -> transfer" mapping that 0059..0075 wrote
--    inline in every money RPC is swapped for private.fn_till_kind() by
--    patching the live function definitions (below), rather than restating
--    a dozen long functions here; every till-kind whitelist
--    ('cash', 'transfer') is widened the same way.
--
-- 3. rpc_cashbox_transfer — move money between two tills (balance only,
--    never profit): a pair of 'adjustment' rows sharing one reference id.
--
-- 4. rpc_record_expenses — several expense lines in one go, atomically,
--    each through rpc_record_expense so every line is booked exactly as a
--    single expense always was.
--
-- 5. rpc_admin_opening_stock — رصيد افتتاحي: stock the warehouse already
--    had before the app, without a supplier invoice or any money moving.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Tills
-- ----------------------------------------------------------------------------
alter table public.cashboxes drop constraint if exists cashboxes_kind_check;
alter table public.cashboxes add constraint cashboxes_kind_check
  check (kind in ('main', 'cash', 'transfer', 'wallet'));

update public.cashboxes set name = 'خزنة الدرج' where kind = 'cash' and is_active;
update public.cashboxes set name = 'حساب CIB' where kind = 'transfer' and is_active;

insert into public.cashboxes (name, kind, is_active)
select 'الخزنة الرئيسية', 'main', true
where not exists (select 1 from public.cashboxes where kind = 'main');

insert into public.cashboxes (name, kind, is_active)
select 'فودافون كاش', 'wallet', true
where not exists (select 1 from public.cashboxes where kind = 'wallet');

alter table public.supplier_payments drop constraint if exists supplier_payments_kind_check;
alter table public.supplier_payments add constraint supplier_payments_kind_check
  check (kind in ('main', 'cash', 'transfer', 'wallet'));

-- ----------------------------------------------------------------------------
-- 2. Payment method -> till
-- ----------------------------------------------------------------------------
create or replace function private.fn_till_kind(p_method payment_method)
returns text language sql immutable as $$
  select case p_method
    when 'cash' then 'cash'
    when 'wallet' then 'wallet'
    else 'transfer'
  end
$$;

do $patch$
declare
  r record;
  v_def text;
begin
  for r in
    select p.oid
    from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname in ('public', 'private') and p.prokind = 'f'
      and (p.prosrc ~ $re$case when [a-z_.]+ = 'cash' then 'cash' else 'transfer' end$re$
           or strpos(p.prosrc, $s$not in ('cash', 'transfer')$s$) > 0)
  loop
    v_def := pg_get_functiondef(r.oid);
    v_def := regexp_replace(v_def,
      $re$case when ([a-z_.]+) = 'cash' then 'cash' else 'transfer' end$re$,
      'private.fn_till_kind(\1)', 'g');
    v_def := replace(v_def, $s$not in ('cash', 'transfer')$s$, $s$not in ('main', 'cash', 'transfer', 'wallet')$s$);
    execute v_def;
  end loop;

  if exists (
    select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname in ('public', 'private') and p.prokind = 'f'
      and (p.prosrc ~ $re$case when [a-z_.]+ = 'cash' then 'cash' else 'transfer' end$re$
           or strpos(p.prosrc, $s$not in ('cash', 'transfer')$s$) > 0)
  ) then
    raise exception 'till kind patch left a function unpatched';
  end if;
end
$patch$;

-- ----------------------------------------------------------------------------
-- 3. Transfer between tills
-- ----------------------------------------------------------------------------
create or replace function public.rpc_cashbox_transfer(
  p_from_kind text, p_to_kind text, p_amount numeric, p_notes text
) returns uuid language plpgsql security definer set search_path = public as $$
declare
  v_from uuid;
  v_to uuid;
  v_balance numeric(14,2);
  v_ref uuid := gen_random_uuid();
  v_notes text := coalesce(nullif(btrim(p_notes), ''), 'تحويل بين الخزن');
begin
  if not (public.is_admin() or public.is_sales()) then raise exception 'FORBIDDEN'; end if;
  if p_amount is null or p_amount <= 0 or p_amount <> round(p_amount, 2) then raise exception 'INVALID_AMOUNT'; end if;
  if p_from_kind is null or p_to_kind is null
     or p_from_kind not in ('main', 'cash', 'transfer', 'wallet')
     or p_to_kind not in ('main', 'cash', 'transfer', 'wallet') then
    raise exception 'INVALID_INPUT';
  end if;
  if p_from_kind = p_to_kind then raise exception 'SAME_CASHBOX'; end if;
  if length(v_notes) > 500 then raise exception 'INPUT_TOO_LONG'; end if;

  -- Both rows locked in one fixed order, so two opposite transfers at the
  -- same moment can't deadlock.
  perform 1 from public.cashboxes
    where kind in (p_from_kind, p_to_kind) and is_active order by id for update;
  select id into v_from from public.cashboxes where kind = p_from_kind and is_active;
  select id into v_to from public.cashboxes where kind = p_to_kind and is_active;
  if v_from is null or v_to is null then raise exception 'NO_CASHBOX'; end if;

  select coalesce(sum(amount), 0) into v_balance from public.cash_transactions where cashbox_id = v_from;
  if p_amount > v_balance then raise exception 'INSUFFICIENT_CASH: %', v_balance; end if;

  insert into public.cash_transactions (cashbox_id, transaction_type, amount, reference_type, reference_id, notes, created_by)
  values (v_from, 'adjustment', -p_amount, 'cashbox_transfer', v_ref, v_notes, auth.uid()),
         (v_to, 'adjustment', p_amount, 'cashbox_transfer', v_ref, v_notes, auth.uid());

  return v_ref;
end;
$$;

-- ----------------------------------------------------------------------------
-- 4. Several expense lines at once
--    p_items: [{category_id, amount, notes?}], all from the p_kind till on
--    p_expense_date. All or nothing.
-- ----------------------------------------------------------------------------
create or replace function public.rpc_record_expenses(
  p_items jsonb, p_expense_date date, p_kind text default 'cash'
) returns jsonb language plpgsql security definer set search_path = public as $$
declare
  v_item jsonb;
  v_category_id uuid;
  v_amount numeric;
  v_notes text;
  v_ids uuid[] := '{}';
begin
  if not (public.is_admin() or public.is_sales()) then raise exception 'FORBIDDEN'; end if;
  if p_items is null or jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then
    raise exception 'INVALID_INPUT';
  end if;
  if jsonb_array_length(p_items) > 50 then raise exception 'TOO_MANY_ITEMS'; end if;

  for v_item in select value from jsonb_array_elements(p_items) loop
    if jsonb_typeof(v_item) <> 'object' then raise exception 'INVALID_ITEM'; end if;
    begin
      v_category_id := (v_item ->> 'category_id')::uuid;
      v_amount := (v_item ->> 'amount')::numeric;
    exception when invalid_text_representation or numeric_value_out_of_range then
      raise exception 'INVALID_ITEM';
    end;
    if v_category_id is null then raise exception 'INVALID_ITEM'; end if;
    if v_amount is null or v_amount <= 0 or v_amount <> round(v_amount, 2) then raise exception 'INVALID_AMOUNT'; end if;
    v_notes := nullif(btrim(v_item ->> 'notes'), '');
    if length(v_notes) > 500 then raise exception 'INPUT_TOO_LONG'; end if;
    if not exists (select 1 from public.expense_categories where id = v_category_id and is_active) then
      raise exception 'CATEGORY_NOT_FOUND';
    end if;

    v_ids := v_ids || public.rpc_record_expense(v_category_id, v_amount, p_expense_date, v_notes, null, p_kind);
  end loop;

  return to_jsonb(v_ids);
end;
$$;

-- ----------------------------------------------------------------------------
-- 5. Opening stock
--    p_items: [{product_id, quantity, unit_cost?}]. unit_cost defaults to
--    the product's current cost price; when given, it becomes the cost
--    price (as a purchase invoice does).
-- ----------------------------------------------------------------------------
create or replace function public.rpc_admin_opening_stock(p_items jsonb, p_notes text)
returns int language plpgsql security definer set search_path = public as $$
declare
  v_warehouse_id uuid;
  v_item jsonb;
  v_product_id uuid;
  v_product record;
  v_qty int;
  v_cost numeric;
  v_notes text := coalesce(nullif(btrim(p_notes), ''), 'رصيد افتتاحي');
  v_lines int := 0;
begin
  if not public.is_admin() then raise exception 'FORBIDDEN'; end if;
  if p_items is null or jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then
    raise exception 'EMPTY_ORDER';
  end if;
  if jsonb_array_length(p_items) > 200 then raise exception 'TOO_MANY_ITEMS'; end if;
  if length(v_notes) > 500 then raise exception 'INPUT_TOO_LONG'; end if;

  select id into v_warehouse_id from public.warehouses where type = 'main' and is_active limit 1;
  if v_warehouse_id is null then raise exception 'NO_MAIN_WAREHOUSE'; end if;

  for v_item in select value from jsonb_array_elements(p_items) loop
    if jsonb_typeof(v_item) <> 'object' then raise exception 'INVALID_ITEM'; end if;
    begin
      v_product_id := (v_item ->> 'product_id')::uuid;
      v_qty := (v_item ->> 'quantity')::int;
      v_cost := (v_item ->> 'unit_cost')::numeric;
    exception when invalid_text_representation or numeric_value_out_of_range then
      raise exception 'INVALID_ITEM';
    end;
    if v_product_id is null then raise exception 'INVALID_ITEM'; end if;
    if v_qty is null or v_qty <= 0 or v_qty > 100000 then raise exception 'INVALID_QUANTITY'; end if;
    if v_cost is not null and (v_cost < 0 or v_cost <> round(v_cost, 2)) then raise exception 'INVALID_AMOUNT'; end if;

    select id, name, cost_price, is_service, is_assembly into v_product
      from public.products where id = v_product_id for update;
    if not found then raise exception 'PRODUCT_NOT_FOUND: %', v_product_id; end if;
    if v_product.is_service or v_product.is_assembly then raise exception 'NOT_A_STOCK_PRODUCT: %', v_product.name; end if;

    insert into public.stock_movements (product_id, movement_type, quantity, from_location_type, to_location_type,
      to_location_id, unit_cost, reference_type, notes, created_by)
    values (v_product.id, 'opening_balance', v_qty, 'external', 'warehouse',
      v_warehouse_id, coalesce(v_cost, v_product.cost_price), 'opening_balance', v_notes, auth.uid());

    if v_cost is not null and v_cost <> v_product.cost_price then
      update public.products set cost_price = v_cost where id = v_product.id;
    end if;
    v_lines := v_lines + 1;
  end loop;

  insert into public.audit_logs (actor_id, action, table_name, new_data)
  values (auth.uid(), 'OPENING_STOCK_ADDED', 'stock_movements',
          jsonb_build_object('items', p_items, 'notes', v_notes));

  return v_lines;
end;
$$;

insert into private.rpc_allowlist (function_name, note) values
  ('rpc_cashbox_transfer', 'admin/sales'),
  ('rpc_record_expenses', 'admin/sales'),
  ('rpc_admin_opening_stock', 'admin')
on conflict (function_name) do nothing;

select private.apply_function_grants();
notify pgrst, 'reload schema';
