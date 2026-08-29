-- ============================================================================
-- 0013_seed.sql
-- Minimal seed data required for the system to function. No fake/demo
-- business data (products, customers, orders) is seeded — production data
-- only.
-- ============================================================================

insert into public.warehouses (name, type) values ('المخزن الرئيسي', 'main');

insert into public.cashboxes (name) values ('خزنة المعرض الرئيسية');

insert into public.expense_categories (name) values
  ('كهرباء'), ('إيجار'), ('نقل'), ('مرتبات'), ('صيانة'), ('شراء أدوات'), ('مصاريف أخرى');

-- ----------------------------------------------------------------------------
-- Bootstrapping the FIRST admin account:
-- This cannot be done in a plain SQL migration because it requires creating
-- an auth.users row with a hashed password, which must go through
-- Supabase Auth (not a raw INSERT). After deploying this schema, run ONCE
-- from a trusted machine (never from Flutter):
--
--   supabase.auth.admin.createUser({
--     email: 'admin@yourgallery.com',
--     password: '<strong-password>',
--     email_confirm: true,
--     app_metadata: { role: 'admin' },
--     user_metadata: { full_name: 'المدير العام' }
--   })
--
-- using the SERVICE ROLE KEY (see supabase/functions/create-user/README.md).
-- The handle_new_auth_user() trigger will then create the matching
-- public.users row with role='admin' automatically.
-- ============================================================================
