-- ============================================================================
-- 0056_support_contact.sql
--
-- Customer service contact: the customer account screen gets a "تواصل معنا"
-- button that opens WhatsApp. The number
-- is a business fact, not something to hardcode — same reasoning and same
-- private.app_settings / rpc_admin_set_text_setting machinery 0039 already
-- built for the InstaPay handle, just a new key.
-- ============================================================================

insert into private.app_settings (key, value) values
  ('support_whatsapp', '"01096525584"'::jsonb)
on conflict (key) do nothing;

-- Widen the existing allowlist (same function, same signature — a plain
-- replace, not a new overload) rather than adding a parallel RPC.
create or replace function public.rpc_admin_set_text_setting(p_key text, p_value text)
returns void language plpgsql security definer set search_path = public as $$
declare
  v_old jsonb;
  v_allowed_keys text[] := array['instapay_ipa_address', 'instapay_beneficiary_name', 'support_whatsapp'];
begin
  if not public.is_admin() then raise exception 'FORBIDDEN'; end if;
  if p_key <> all(v_allowed_keys) then raise exception 'UNKNOWN_SETTING'; end if;
  if length(p_value) > 200 then raise exception 'INPUT_TOO_LONG'; end if;

  select value into v_old from private.app_settings where key = p_key for update;
  if not found then raise exception 'UNKNOWN_SETTING'; end if;

  update private.app_settings
    set value = to_jsonb(nullif(btrim(p_value), '')), updated_at = now(), updated_by = auth.uid()
    where key = p_key;

  insert into public.audit_logs (actor_id, action, table_name, old_data, new_data)
  values (auth.uid(), 'SETTING_CHANGED', 'private.app_settings',
          jsonb_build_object('key', p_key, 'value', v_old),
          jsonb_build_object('key', p_key, 'value', to_jsonb(p_value)));
end;
$$;

-- Any signed-in user needs this to know who to message.
create or replace function public.rpc_get_support_contact() returns jsonb
language sql stable security definer set search_path = public as $$
  select jsonb_build_object('whatsapp', private.setting_text('support_whatsapp'));
$$;

insert into private.rpc_allowlist (function_name, note) values
  ('rpc_get_support_contact', 'any signed-in user')
on conflict (function_name) do nothing;

select private.apply_function_grants();
notify pgrst, 'reload schema';
