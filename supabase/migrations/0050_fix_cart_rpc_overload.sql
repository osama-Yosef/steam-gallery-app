-- ============================================================================
-- 0050_fix_cart_rpc_overload.sql
--
-- 0049 changed rpc_cart_set_item/rpc_cart_add_item from 2 parameters to 3
-- (added p_option_ids) but used `create or replace function`, which in
-- Postgres only replaces a function with the exact same parameter type
-- list. A different signature creates a second, overloaded function
-- instead of replacing the old one — so both the old 2-arg and new 3-arg
-- versions have been live at once since 0049, and PostgREST cannot pick
-- one unambiguously, making every rpc_cart_set_item/rpc_cart_add_item call
-- fail (customers saw "تعذَّرت العملية. حاول مرة أخرى." on every add-to-cart).
--
-- Every other migration that changed an RPC's signature (0027, 0030, 0036,
-- 0046) already dropped the old overload first — 0049 is the one place
-- that step was missed. This drops the stale 2-arg overloads so only the
-- option-aware 3-arg versions remain.
-- ============================================================================

drop function if exists public.rpc_cart_set_item(uuid, int);
drop function if exists public.rpc_cart_add_item(uuid, int);
