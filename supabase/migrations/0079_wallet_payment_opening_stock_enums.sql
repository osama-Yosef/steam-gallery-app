-- ============================================================================
-- 0079_wallet_payment_opening_stock_enums.sql
--
-- Enum values only — Postgres will not let a new enum value be used inside
-- the same transaction that adds it (see 0043), so 0080/0081 are the ones
-- that actually reference them.
--
--   payment_method 'wallet'            تحويل محفظة (Vodafone Cash & co.)
--   stock_movement_type 'opening_balance'  رصيد افتتاحي للمخزن
-- ============================================================================

alter type payment_method add value if not exists 'wallet';
alter type stock_movement_type add value if not exists 'opening_balance';
