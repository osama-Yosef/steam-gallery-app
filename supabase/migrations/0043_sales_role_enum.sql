-- ============================================================================
-- 0043_sales_role_enum.sql  (Phase 16 — a fourth role: sales)
--
-- Adds the enum value only. Postgres will not let a new enum value be used
-- inside the SAME transaction that adds it (in a function body, a policy
-- expression, or a cast), so this is its own migration file/transaction —
-- 0044 is the one that actually references 'sales' anywhere.
-- ============================================================================

alter type user_role add value if not exists 'sales';
