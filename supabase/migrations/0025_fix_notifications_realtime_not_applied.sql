-- ============================================================================
-- 0025_fix_notifications_realtime_not_applied.sql
--
-- Bug found via live testing: the notifications screen showed "تعذَّر تحميل
-- الإشعارات" for every role, and the bell badge never updated.
--
-- Root cause: notification_repository watches the table with
-- .stream(primaryKey: ['id']), which requires the table to be a member of
-- the supabase_realtime publication. 0020_notifications_realtime.sql was
-- recorded as applied, but the publication actually only contained
-- `orders, maintenance_requests` — its ALTER PUBLICATION never took effect
-- on this project, so every subscription attempt failed.
--
-- Re-applies it, guarded so it is safe to run whether or not the table is
-- already a member (a bare ALTER PUBLICATION ... ADD TABLE errors if it is,
-- which would block the whole migration).
-- ============================================================================

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'notifications'
  ) then
    alter publication supabase_realtime add table public.notifications;
  end if;
end $$;
