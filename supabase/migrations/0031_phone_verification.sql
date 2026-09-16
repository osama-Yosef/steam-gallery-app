-- ============================================================================
-- 0031_phone_verification.sql
--
-- Phase 2 (Authentication): phone numbers proven by OTP.
--
-- Supabase Auth owns the OTP itself — generation, SMS delivery through the
-- configured provider, expiry, resend cooldown, attempt rate limits. Nothing
-- here stores or checks an OTP. What the database adds is the part Auth can't
-- express on its own:
--
--   * public.users.phone_verified_at — "this account proved it holds this
--     number", set only from evidence Auth produced. auth.users.
--     phone_confirmed_at can't serve: while "Confirm phone" was disabled every
--     signup got it for free, so every existing account looks confirmed.
--   * A switch (private.app_settings.require_verified_phone) under which an
--     unverified CUSTOMER is treated as anon by every RLS policy and RPC. Off
--     by default so deploying this breaks nobody; turn it on only after the
--     SMS provider and "Confirm phone" are enabled in the Auth settings (see
--     docs/09-phase-2-authentication.md). Staff are created by an admin, who
--     vouches for their number, and are never gated.
--   * Audit rows for password changes and phone confirmations, written by a
--     trigger on auth.users so they can't be skipped or forged by a client.
--
-- Evidence accepted for phone_verified_at:
--   1. auth.users.phone_confirmed_at moving from NULL to a value while the
--      switch is on (a real signup OTP; with confirmation enabled Auth only
--      sets it after the code is verified).
--   2. rpc_mark_phone_verified() called from a session whose JWT — signed by
--      Auth — says it was established by OTP within the last hour. This is how
--      accounts created before verification existed prove their number.
--   3. Auth changing a confirmed account's number while the switch is on
--      (the profile's number follows; verification restarts from that moment).
-- Whichever path sets a number frees it from any stale profile still holding
-- it (private.release_phone, 0029), so users.phone's UNIQUE can't block it.
-- ============================================================================

alter table public.users add column if not exists phone_verified_at timestamptz;

comment on column public.users.phone_verified_at is
  'When this account last proved ownership of its phone by OTP. Never set by clients directly.';

-- phone_verified_at is not in the users UPDATE column grant (0029), so a
-- client can read it but never write it.

-- ----------------------------------------------------------------------------
-- 1. Settings
-- ----------------------------------------------------------------------------
create table if not exists private.app_settings (
  key text primary key,
  value jsonb not null,
  updated_at timestamptz not null default now(),
  updated_by uuid
);

insert into private.app_settings (key, value) values
  ('require_verified_phone', 'false'::jsonb)
on conflict (key) do nothing;

create or replace function private.setting_bool(p_key text) returns boolean
language sql stable security definer set search_path = private, public as $$
  select coalesce((select value = 'true'::jsonb from private.app_settings where key = p_key), false);
$$;
revoke all on function private.setting_bool(text) from public, anon, authenticated;

-- What the app needs to know to route a signed-in user.
create or replace function public.rpc_get_auth_settings() returns jsonb
language sql stable security definer set search_path = public as $$
  select jsonb_build_object('require_verified_phone', private.setting_bool('require_verified_phone'));
$$;

-- Admin-only switch, audited. Only known keys, only booleans for now.
create or replace function public.rpc_admin_set_setting(p_key text, p_value boolean)
returns void language plpgsql security definer set search_path = public as $$
declare
  v_old jsonb;
begin
  if not public.is_admin() then raise exception 'FORBIDDEN'; end if;
  if p_value is null then raise exception 'INVALID_INPUT'; end if;

  select value into v_old from private.app_settings where key = p_key for update;
  if not found then raise exception 'UNKNOWN_SETTING'; end if;

  update private.app_settings
    set value = to_jsonb(p_value), updated_at = now(), updated_by = auth.uid()
    where key = p_key;

  insert into public.audit_logs (actor_id, action, table_name, old_data, new_data)
  values (auth.uid(), 'SETTING_CHANGED', 'private.app_settings',
          jsonb_build_object('key', p_key, 'value', v_old),
          jsonb_build_object('key', p_key, 'value', to_jsonb(p_value)));
end;
$$;

-- ----------------------------------------------------------------------------
-- 2. auth_role(): unverified customers are anon while the switch is on
-- ----------------------------------------------------------------------------
-- Reads still work where a policy matches on `customer_id = auth.uid()` (the
-- customer can see their own history); everything gated on is_customer() —
-- placing orders, opening maintenance requests — is refused until verified.
create or replace function public.auth_role() returns text
language sql stable security definer set search_path = public as $$
  select case
    when auth.uid() is null then 'anon'
    else coalesce((
      select case
        when not u.is_active then 'anon'
        when (auth.jwt() -> 'app_metadata' ->> 'role') = 'customer'
             and u.phone_verified_at is null
             and private.setting_bool('require_verified_phone') then 'anon'
        else coalesce(auth.jwt() -> 'app_metadata' ->> 'role', 'anon')
      end
      from public.users u where u.id = auth.uid()
    ), 'anon')
  end;
$$;

-- ----------------------------------------------------------------------------
-- 3. Marking a phone verified
-- ----------------------------------------------------------------------------
create or replace function public.rpc_mark_phone_verified() returns timestamptz
language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid();
  v_phone text;
  v_otp_session boolean;
  v_verified_at timestamptz;
begin
  if v_uid is null then raise exception 'FORBIDDEN'; end if;

  select phone into v_phone from auth.users
    where id = v_uid and phone_confirmed_at is not null and coalesce(phone, '') <> '';
  if v_phone is null then raise exception 'PHONE_NOT_VERIFIED'; end if;

  -- `amr` is part of the Auth-signed JWT: it records how THIS session was
  -- established. A password session can't claim an OTP.
  select exists (
    select 1 from jsonb_array_elements(coalesce(auth.jwt() -> 'amr', '[]'::jsonb)) e
    where e ->> 'method' = 'otp'
      and to_timestamp((e ->> 'timestamp')::double precision) > now() - interval '1 hour'
  ) into v_otp_session;
  if not v_otp_session then raise exception 'OTP_SESSION_REQUIRED'; end if;

  -- Auth just proved this account holds the number; a stale profile still
  -- carrying it (see private.release_phone, 0029) would otherwise block the
  -- update below on users.phone's UNIQUE constraint.
  perform private.release_phone(v_phone, v_uid);

  update public.users
    set phone_verified_at = coalesce(phone_verified_at, now()),
        -- The number Auth just proved is the one of record.
        phone = v_phone
    where id = v_uid
    returning phone_verified_at into v_verified_at;
  if not found then raise exception 'USER_NOT_FOUND'; end if;

  insert into public.audit_logs (actor_id, action, table_name, record_id, new_data)
  values (v_uid, 'PHONE_VERIFIED', 'users', v_uid, jsonb_build_object('method', 'otp_session'));

  return v_verified_at;
end;
$$;

-- ----------------------------------------------------------------------------
-- 4. Security events on auth.users (Auth's own writes)
-- ----------------------------------------------------------------------------
-- Runs in Auth's connection, where there is no end-user JWT: the actor is the
-- account itself. Nothing secret is copied — only that the event happened.
create or replace function public.on_auth_user_security_event() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  v_has_profile boolean := exists (select 1 from public.users where id = new.id);
  -- With "Confirm phone" on (which the switch requires), Auth only confirms
  -- or changes a number after its OTP is entered.
  v_trusted boolean := private.setting_bool('require_verified_phone');
begin
  if new.phone_confirmed_at is not null and old.phone_confirmed_at is null then
    if v_trusted then
      perform private.release_phone(new.phone, new.id);
      update public.users
        set phone_verified_at = coalesce(phone_verified_at, now()),
            phone = coalesce(nullif(new.phone, ''), phone)
        where id = new.id;
    end if;
    if v_has_profile then
      insert into public.audit_logs (actor_id, action, table_name, record_id, new_data)
      values (new.id, 'PHONE_CONFIRMED', 'auth.users', new.id,
              jsonb_build_object('counted_as_verified', v_trusted));
    end if;

  -- A confirmed account moving to a different number (Auth's phone-change
  -- flow). The profile follows the auth number — otherwise orders, tickets
  -- and the verified badge keep pointing at a number the user gave up — and
  -- the verification restarts: it counts only if Auth proved the new number.
  elsif new.phone is distinct from old.phone and new.phone_confirmed_at is not null
        and v_has_profile then
    perform private.release_phone(new.phone, new.id);
    update public.users
      set phone = nullif(new.phone, ''),
          phone_verified_at = case when v_trusted then now() else null end
      where id = new.id;
    insert into public.audit_logs (actor_id, action, table_name, record_id, new_data)
    values (new.id, 'PHONE_CHANGED', 'auth.users', new.id,
            jsonb_build_object('counted_as_verified', v_trusted));
  end if;

  if new.encrypted_password is distinct from old.encrypted_password and v_has_profile then
    insert into public.audit_logs (actor_id, action, table_name, record_id)
    values (new.id, 'PASSWORD_CHANGED', 'auth.users', new.id);
  end if;

  return new;
end;
$$;

drop trigger if exists trg_on_auth_user_security_event on auth.users;
create trigger trg_on_auth_user_security_event
  after update of phone, phone_confirmed_at, encrypted_password on auth.users
  for each row execute function public.on_auth_user_security_event();

-- ----------------------------------------------------------------------------
-- 5. Grants (rule from 0029)
-- ----------------------------------------------------------------------------
insert into private.rpc_allowlist (function_name, note) values
  ('rpc_get_auth_settings', 'any signed-in user'),
  ('rpc_mark_phone_verified', 'any signed-in user, OTP session'),
  ('rpc_admin_set_setting', 'admin')
on conflict (function_name) do nothing;

select private.apply_function_grants();
