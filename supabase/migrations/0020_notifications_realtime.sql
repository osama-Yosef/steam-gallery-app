-- ============================================================================
-- 0020_notifications_realtime.sql
-- Enable Realtime on notifications for the in-app bell/badge (Module 12) —
-- same pattern as 0015 (orders) and 0018 (maintenance_requests).
-- ============================================================================

alter publication supabase_realtime add table public.notifications;
