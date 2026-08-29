-- ============================================================================
-- 0008_indexes.sql
-- ============================================================================

-- users / technicians / customers
create index idx_users_role on public.users(role);
create index idx_users_phone on public.users(phone);

-- catalog
create index idx_products_category on public.products(category_id);
create index idx_products_active on public.products(is_active);
create index idx_products_name_trgm on public.products using gin (name gin_trgm_ops);
create index idx_products_sku on public.products(sku);
create index idx_product_images_product on public.product_images(product_id);
create index idx_categories_parent on public.product_categories(parent_id);

-- warehouse / bags
create index idx_warehouse_stock_wh on public.warehouse_stock(warehouse_id);
create index idx_warehouse_stock_product on public.warehouse_stock(product_id);
create index idx_bag_stock_bag on public.technician_bag_stock(technician_bag_id);
create index idx_bag_stock_product on public.technician_bag_stock(product_id);
create index idx_technician_bags_tech on public.technician_bags(technician_id);

-- stock movements
create index idx_stock_mov_product on public.stock_movements(product_id, created_at desc);
create index idx_stock_mov_reference on public.stock_movements(reference_type, reference_id);
create index idx_stock_mov_from on public.stock_movements(from_location_type, from_location_id);
create index idx_stock_mov_to on public.stock_movements(to_location_type, to_location_id);
create index idx_stock_mov_type on public.stock_movements(movement_type, created_at desc);

-- orders
create index idx_orders_customer on public.orders(customer_id, created_at desc);
create index idx_orders_status on public.orders(status, created_at desc);
create index idx_order_items_order on public.order_items(order_id);
create index idx_order_items_product on public.order_items(product_id);

-- maintenance
create index idx_maintenance_status_active on public.maintenance_requests(status, created_at)
  where status in ('waiting', 'assigned', 'in_progress');
create index idx_maintenance_customer on public.maintenance_requests(customer_id, created_at desc);
create index idx_maintenance_technician on public.maintenance_requests(assigned_technician_id, status);
create index idx_maintenance_history_req on public.maintenance_status_history(maintenance_request_id, changed_at);

-- sales
create index idx_sales_technician on public.sales(technician_id, created_at desc);
create index idx_sales_customer on public.sales(customer_id, created_at desc);
create index idx_sale_items_sale on public.sale_items(sale_id);
create index idx_sale_items_product on public.sale_items(product_id);

-- technician finance
create index idx_tech_txn_technician on public.technician_account_transactions(technician_id, created_at desc);
create index idx_tech_supplies_technician on public.technician_supplies(technician_id, created_at desc);

-- cashbox / customer / expenses
create index idx_cash_txn_cashbox on public.cash_transactions(cashbox_id, created_at desc);
create index idx_cash_txn_reference on public.cash_transactions(reference_type, reference_id);
create index idx_cust_txn_customer on public.customer_account_transactions(customer_id, created_at desc);
create index idx_expenses_category on public.expenses(category_id, expense_date desc);
create index idx_expenses_date on public.expenses(expense_date desc);

-- inventory
create index idx_inv_count_items_count on public.inventory_count_items(inventory_count_id);
create index idx_inv_counts_location on public.inventory_counts(location_type, location_id);

-- notifications / audit
create index idx_notifications_user on public.notifications(user_id, is_read, created_at desc);
create index idx_audit_table_record on public.audit_logs(table_name, record_id);
create index idx_audit_actor on public.audit_logs(actor_id, created_at desc);
