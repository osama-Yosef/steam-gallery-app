-- ============================================================================
-- 0051_reload_schema_cache.sql
--
-- Forces PostgREST to re-read the function/table list from Postgres. Every
-- migration that adds/changes a function or table should really end with
-- this, but it was missing after 0049 — Supabase does auto-reload on DDL
-- most of the time, but the API layer sometimes keeps serving the old
-- function list for a while after a manual SQL Editor run, which reads
-- exactly like "works in SQL, fails from the app" (PGRST202 / "function
-- not found" collapsing to the generic error message client-side).
-- ============================================================================

notify pgrst, 'reload schema';
