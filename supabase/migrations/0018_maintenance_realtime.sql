-- ============================================================================
-- 0018_maintenance_realtime.sql
-- Enable Realtime on maintenance_requests for the live queue (Module 4).
-- ============================================================================

alter publication supabase_realtime add table public.maintenance_requests;
