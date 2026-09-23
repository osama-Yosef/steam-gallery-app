-- ============================================================================
-- 0066_push_notifications.sql
--
-- Real push notifications (arrive even with the app closed/killed), on top
-- of the existing in-app notifications table which only ever reached an
-- open, connected app via Realtime. Firebase Cloud Messaging does delivery;
-- this migration only adds where to send it and what fires the send.
--
-- Flow: any insert into public.notifications (already the single funnel —
-- see notify_user/notify_all_admins, 0010) fires a trigger that calls the
-- send-push Edge Function over pg_net, fire-and-forget. That function reads
-- the target user's fcm_token (this migration) with the service role and
-- calls FCM's HTTP v1 API. A user with no token, or whose token has gone
-- stale, simply gets no push — the in-app notification row is unaffected
-- either way, so this can never block or fail the action that created it.
-- ============================================================================

alter table public.users add column if not exists fcm_token text;

comment on column public.users.fcm_token is
  'Firebase Cloud Messaging registration token for this device. Overwritten on every app start/refresh; null means no push target.';

-- Widens the users UPDATE column grant (0029: full_name, avatar_url) to
-- include fcm_token. RLS's users_update_self policy (0011) still restricts
-- this to the caller's own row regardless of role.
grant update (fcm_token) on public.users to authenticated;

-- ----------------------------------------------------------------------------
-- pg_net: lets a Postgres trigger make an async, fire-and-forget HTTP call.
-- ----------------------------------------------------------------------------
create extension if not exists pg_net with schema extensions;

-- ----------------------------------------------------------------------------
-- Trigger: forward every new notification row to the send-push function.
--
-- The bearer token here is the publishable ("anon") key — not a secret (see
-- lib/core/config/env.dart), it only gets the call past Supabase's own
-- function gateway. The function does its own privileged lookup with the
-- service role key, which is injected into it directly by Supabase and
-- never appears in this database.
-- ----------------------------------------------------------------------------
create or replace function public.push_on_notification() returns trigger
language plpgsql security definer set search_path = public, extensions as $$
begin
  perform net.http_post(
    url := 'https://jtvformbjielhhjtnsgh.supabase.co/functions/v1/send-push',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer sb_publishable_KnfOZejEqhApFb-MCjvq_Q_vLeu36Jq'
    ),
    body := jsonb_build_object(
      'user_id', new.user_id,
      'title', new.title,
      'body', new.body,
      'data', coalesce(new.data, '{}'::jsonb)
    )
  );
  return new;
end;
$$;

drop trigger if exists trg_push_on_notification on public.notifications;
create trigger trg_push_on_notification
  after insert on public.notifications
  for each row execute function public.push_on_notification();
