-- ============================================================================
-- tool/sql/verify_security.sql
--
-- READ-ONLY checks for the live database (Supabase SQL editor, or
-- `psql -f`). Nothing here writes. Run it:
--   * before applying 0029/0030, to capture the "before" state and detect
--     drift from the migration files;
--   * right after applying them — every query marked "expect 0 rows" must
--     return 0 rows;
--   * after any later migration that creates or replaces a function.
-- ============================================================================

-- 0. Which migrations does the database think it has? (Drift check: compare
--    against supabase/migrations/ in the repo.)
select version, name
from supabase_migrations.schema_migrations
order by version;

-- 1. Expect 0 rows: functions in `public` that anon can execute.
select p.oid::regprocedure as function_executable_by_anon
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public' and p.prokind = 'f'
  and not exists (select 1 from pg_depend d where d.classid = 'pg_proc'::regclass and d.objid = p.oid and d.deptype = 'e')
  and has_function_privilege('anon', p.oid, 'execute');

-- 2. Expect 0 rows: functions authenticated can execute that are not on the
--    allowlist (e.g. notify_user, notify_all_admins, post_technician_supply).
select p.oid::regprocedure as function_executable_but_not_allowlisted
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public' and p.prokind = 'f'
  and not exists (select 1 from pg_depend d where d.classid = 'pg_proc'::regclass and d.objid = p.oid and d.deptype = 'e')
  and has_function_privilege('authenticated', p.oid, 'execute')
  and p.proname not in (select function_name from private.rpc_allowlist);

-- 3. Expect 0 rows: allowlisted names with no matching function (typo or a
--    function dropped without updating the allowlist).
select a.function_name as allowlisted_but_missing
from private.rpc_allowlist a
where not exists (
  select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public' and p.proname = a.function_name
);

-- 4. Expect `false` in every column.
select
  has_column_privilege('authenticated', 'public.users', 'phone', 'update')     as can_update_phone,
  has_column_privilege('authenticated', 'public.users', 'role', 'update')      as can_update_role,
  has_column_privilege('authenticated', 'public.users', 'is_active', 'update') as can_update_is_active;

-- 5. Review: SELECT policies guarding cost columns. Expected:
--      products     -> is_admin() OR is_technician()
--      order_items  -> is_admin()
--      sale_items   -> is_admin() OR own technician's sales
select tablename, policyname, cmd, qual
from pg_policies
where schemaname = 'public'
  and tablename in ('products', 'order_items', 'sale_items')
  and cmd = 'SELECT'
order by tablename;

-- 6. Customer-facing views: none may expose a cost column, and all three are
--    definer views (security_invoker off) that do their own row filtering.
select c.relname as view_name,
       coalesce(c.reloptions::text, '{}') as options,
       exists (
         select 1 from pg_attribute a
         where a.attrelid = c.oid and a.attnum > 0 and not a.attisdropped
           and a.attname like '%cost%'
       ) as exposes_cost_column
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public'
  and c.relname in ('products_public', 'order_items_display', 'sale_items_display');

-- 7. Expect 0 rows: ledger tables missing their immutability trigger.
select t.table_name as ledger_without_immutability_trigger
from (values
  ('stock_movements'), ('order_items'), ('sale_items'), ('maintenance_status_history'),
  ('technician_account_transactions'), ('cash_transactions'),
  ('customer_account_transactions'), ('expenses'), ('audit_logs')
) as t(table_name)
where not exists (
  select 1 from pg_trigger tg
  join pg_class c on c.oid = tg.tgrelid
  join pg_namespace n on n.oid = c.relnamespace
  join pg_proc p on p.oid = tg.tgfoid
  where n.nspname = 'public' and c.relname = t.table_name
    and p.proname = 'prevent_mutation' and not tg.tgisinternal
);

-- 8. Expect 0 rows: tables in `public` with RLS disabled.
select c.relname as table_without_rls
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public' and c.relkind = 'r' and not c.relrowsecurity;

-- 9. Expect 0 rows: singleton setup rows the RPCs depend on (see 0023).
select 'no active main warehouse' as missing_setup
where not exists (select 1 from public.warehouses where type = 'main' and is_active)
union all
select 'no active cashbox'
where not exists (select 1 from public.cashboxes where is_active);

-- 10. Review: deactivated users and whether their auth user is banned.
select u.id, u.role, u.full_name, au.banned_until
from public.users u
join auth.users au on au.id = u.id
where not u.is_active;

-- 11. Review: supplies waiting for an admin (0030).
select id, supply_number, technician_id, amount, created_at
from public.technician_supplies
where status = 'pending'
order by created_at;
