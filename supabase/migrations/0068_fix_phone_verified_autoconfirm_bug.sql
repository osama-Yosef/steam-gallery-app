-- ============================================================================
-- 0068_fix_phone_verified_autoconfirm_bug.sql
--
-- on_auth_user_security_event() (0031) treated auth.users.phone_confirmed_at
-- moving from null to a value as evidence a real OTP was entered, and used
-- that to set public.users.phone_verified_at. That was true under the
-- original design (Supabase's own paid SMS OTP, "Confirm phone" on).
--
-- It stopped being true the moment sms_autoconfirm was switched on for this
-- project (Management API, alongside 0067) to stop Supabase ever attempting
-- its own SMS: with autoconfirm, Auth sets phone_confirmed_at on EVERY
-- signup instantly, with no code ever sent or checked. The trigger kept
-- trusting it anyway, so every new customer's phone_verified_at got set
-- immediately at signup — silently defeating 0067's whole point (found live:
-- a fresh signup landed straight on the customer home, skipping
-- VerifyPhoneScreen entirely).
--
-- The only trustworthy evidence now is a completed Firebase verification,
-- recorded by the verify-phone-firebase Edge Function writing
-- phone_verified_at directly with the service role (see its source). This
-- trigger no longer sets that column at all — it keeps doing everything
-- else on_auth_user_security_event did (the audit trail, following the
-- profile's phone number to whatever Auth has on file).
-- ============================================================================

create or replace function public.on_auth_user_security_event() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  v_has_profile boolean := exists (select 1 from public.users where id = new.id);
begin
  if new.phone_confirmed_at is not null and old.phone_confirmed_at is null then
    -- No longer counted as verification evidence — see this file's header.
    -- Still the number of record once Auth has it, so a stale profile
    -- holding it doesn't block the UNIQUE constraint.
    perform private.release_phone(new.phone, new.id);
    if v_has_profile then
      update public.users set phone = coalesce(nullif(new.phone, ''), phone) where id = new.id;
      insert into public.audit_logs (actor_id, action, table_name, record_id, new_data)
      values (new.id, 'PHONE_CONFIRMED', 'auth.users', new.id,
              jsonb_build_object('counted_as_verified', false));
    end if;

  elsif new.phone is distinct from old.phone and new.phone_confirmed_at is not null
        and v_has_profile then
    perform private.release_phone(new.phone, new.id);
    -- A number change through Auth's own flow is not Firebase evidence
    -- either — always restart verification from here.
    update public.users
      set phone = nullif(new.phone, ''), phone_verified_at = null
      where id = new.id;
    insert into public.audit_logs (actor_id, action, table_name, record_id, new_data)
    values (new.id, 'PHONE_CHANGED', 'auth.users', new.id,
            jsonb_build_object('counted_as_verified', false));
  end if;

  if new.encrypted_password is distinct from old.encrypted_password and v_has_profile then
    insert into public.audit_logs (actor_id, action, table_name, record_id)
    values (new.id, 'PASSWORD_CHANGED', 'auth.users', new.id);
  end if;

  return new;
end;
$$;

-- rpc_mark_phone_verified() (0031) is unaffected: it still requires the
-- caller's JWT to have amr = 'otp' from a Supabase-native OTP session,
-- which sms_autoconfirm never produces (there's no code to enter, so
-- nothing ever signs in "by otp"). It's effectively unreachable now, same
-- as it was reachable-but-never-called before this fix — the client only
-- ever calls markPhoneVerifiedWithFirebaseToken (verify-phone-firebase).

-- One-time repair: the only signup that happened during this bug's short
-- window (sms_autoconfirm going live in 0067 to this fix) — a live test
-- account, false-positive verified at the same instant it was created.
update public.users set phone_verified_at = null
where id = 'da819c56-fe85-44e2-8c9c-500af3f65152';
