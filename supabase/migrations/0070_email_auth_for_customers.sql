-- ============================================================================
-- 0070_email_auth_for_customers.sql
--
-- Customer self sign-up moves from phone+password (SMS a paid, currently
-- non-functional dead end — see 0067/0068/0069) to email+password. Email
-- confirmation and password recovery are both native, free Supabase Auth
-- features (mailer_autoconfirm is already off on this project — a real code
-- is genuinely required and checked, unlike phone's broken sms_autoconfirm
-- episode). Phone stays a required field on every customer, but purely as
-- contact/delivery info now — never an Auth identifier, never SMS-verified.
--
-- Staff (admin/technician/sales) are unaffected: the create-user Edge
-- Function still sets a real phone on auth.users directly with the service
-- role, and they still sign in with phone+password exactly as before.
-- ============================================================================

alter table public.users add column if not exists email_verified_at timestamptz;

comment on column public.users.email_verified_at is
  'When this account last proved ownership of its email by the code sent to it. Never set by clients directly.';

-- ----------------------------------------------------------------------------
-- 1. handle_new_auth_user(): a customer signing up with email has no
--    auth.users.phone at all (that slot is unused for them) — their phone
--    comes from raw_user_meta_data instead, same field the client already
--    fills in on the sign-up form. Staff creation (create-user Edge
--    Function) still sets phone directly on auth.users with the service
--    role, so new.phone stays authoritative whenever it's present — this
--    only falls back to metadata when Auth has no phone of its own.
-- ----------------------------------------------------------------------------
create or replace function public.handle_new_auth_user() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  v_role user_role := coalesce((new.raw_app_meta_data ->> 'role')::user_role, 'customer');
  v_phone text := coalesce(nullif(new.phone, ''), nullif(btrim(new.raw_user_meta_data ->> 'phone'), ''));
  v_full_name text := left(coalesce(
    nullif(btrim(new.raw_user_meta_data ->> 'full_name'), ''),
    v_phone,
    new.email,
    'مستخدم جديد'
  ), 100);
  v_employee_code text;
begin
  perform private.release_phone(v_phone, new.id);

  insert into public.users (id, role, full_name, phone, email)
  values (new.id, v_role, v_full_name, v_phone, new.email);

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

  update auth.users
    set raw_app_meta_data = coalesce(raw_app_meta_data, '{}'::jsonb) || jsonb_build_object('role', v_role::text)
    where id = new.id;

  return new;
end;
$$;

-- ----------------------------------------------------------------------------
-- 2. Mirror a real email confirmation onto public.users.email_verified_at,
--    the same way phone_verified_at used to mirror phone_confirmed_at
--    before that stopped being trustworthy (0068). email_confirmed_at IS
--    trustworthy: mailer_autoconfirm is off, so Auth only sets it after the
--    mailed code is checked (verifyOTP), never automatically.
-- ----------------------------------------------------------------------------
create or replace function public.on_auth_user_email_confirmed() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if new.email_confirmed_at is not null and old.email_confirmed_at is null then
    update public.users
      set email_verified_at = coalesce(email_verified_at, now()),
          email = coalesce(nullif(new.email, ''), email)
      where id = new.id;
    if exists (select 1 from public.users where id = new.id) then
      insert into public.audit_logs (actor_id, action, table_name, record_id, new_data)
      values (new.id, 'EMAIL_CONFIRMED', 'auth.users', new.id, '{}'::jsonb);
    end if;
  -- A confirmed email changing to a different one (add-email or change-email
  -- flow) — restart verification from here, same reasoning as the phone
  -- equivalent in 0068.
  elsif new.email is distinct from old.email and new.email_confirmed_at is not null then
    update public.users
      set email = nullif(new.email, ''), email_verified_at = now()
      where id = new.id;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_on_auth_user_email_confirmed on auth.users;
create trigger trg_on_auth_user_email_confirmed
  after update of email, email_confirmed_at on auth.users
  for each row execute function public.on_auth_user_email_confirmed();
