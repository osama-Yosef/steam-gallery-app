-- ============================================================================
-- 0001_extensions_and_types.sql
-- Extensions + ENUM types used across the whole schema
-- ============================================================================

create extension if not exists "pgcrypto";   -- gen_random_uuid()
create extension if not exists "pg_trgm";    -- fuzzy / ILIKE search performance

-- ----------------------------------------------------------------------------
-- ENUM types
-- ----------------------------------------------------------------------------

create type user_role as enum ('admin', 'technician', 'customer');

create type warehouse_type as enum ('main');

create type location_type as enum ('warehouse', 'technician_bag', 'external');

create type stock_movement_type as enum (
  'purchase',              -- شراء / إضافة أولية للمخزن الرئيسي
  'sale',                  -- بيع من طلب عميل (order)
  'issue_to_technician',   -- صرف من المخزن الرئيسي لشنطة صنايعي
  'technician_sale',       -- بيع الصنايعي من شنطته
  'return_from_customer',  -- مرتجع من عميل
  'return_to_supplier',    -- مرتجع لمورد
  'damage',                -- تالف
  'inventory_adjustment',  -- تسوية جرد
  'transfer'                -- نقل بين مخازن (مستقبلي)
);

create type order_status as enum (
  'pending', 'confirmed', 'preparing', 'delivered', 'completed', 'cancelled', 'returned'
);

create type maintenance_status as enum (
  'waiting', 'assigned', 'in_progress', 'completed', 'cancelled'
);

create type payment_method as enum ('cash', 'card', 'transfer', 'deferred');

create type sale_status as enum ('completed', 'returned', 'cancelled');

create type tech_txn_type as enum ('sale_credit', 'supply_debit', 'adjustment');

create type cust_txn_type as enum ('order_charge', 'payment', 'return_credit', 'adjustment');

create type cash_txn_type as enum (
  'sale', 'technician_deposit', 'expense', 'refund', 'adjustment', 'purchase',
  'other_income', 'other_expense'
);

create type inventory_count_status as enum ('draft', 'completed');
