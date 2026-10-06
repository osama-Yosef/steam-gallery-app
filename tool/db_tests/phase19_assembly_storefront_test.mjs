// tool/db_tests/phase19_assembly_storefront_test.mjs
//
// 0077: assembly products ("صنف تجميع") in the customer storefront —
// availability from components in the catalog / browse / cart, and customer
// orders taking (and on cancel/return giving back) the components.
//
//   cd tool/db_tests && npm install && node phase19_assembly_storefront_test.mjs

import { setup, ADMIN, CUST_A } from './harness.mjs';

const { ok, finish, as, asSuper, q, one, err } = await setup(process.argv[2]);

const stock = async (productId) => {
  await asSuper();
  return (await one(`select coalesce(sum(quantity), 0)::int as q from public.warehouse_stock where product_id = $1`, [productId])).q;
};

await as(ADMIN);
const cairo = (await one(`select id from public.cities where name_ar = 'القاهرة'`)).id;
const mk = async (sku, name, cost, price) =>
  (await one(`insert into public.products (sku, name, cost_price, selling_price) values ($1, $2, $3, $4) returning id`, [sku, name, cost, price])).id;
const IRON = await mk('AS1', 'مكواة', 50, 100);
const FILTER = await mk('AS2', 'فلتر', 5, 20);
const KIT = await mk('AS3', 'طقم مكواة', 0, 150);
await q(`select public.rpc_receive_purchase($1, 3, 50, 'seed')`, [IRON]);
await q(`select public.rpc_receive_purchase($1, 4, 5, 'seed')`, [FILTER]);
await q(`select public.rpc_admin_set_assembly($1, true, $2)`,
  [KIT, JSON.stringify([{ product_id: IRON, quantity: 1 }, { product_id: FILTER, quantity: 2 }])]);

const addr = (await as(CUST_A).then(() => one(`select public.rpc_save_my_address(
  p_address_id => null, p_city_id => $1, p_label => 'المنزل', p_address_line => 'addr',
  p_latitude => 30.0561, p_longitude => 31.3301) as r`, [cairo]))).r.id;

// ---------------------------------------------------------------- availability
console.log('\n== The storefront sees an assembly as available from its components ==');
await as(CUST_A);
let pub = await one(`select is_available from public.products_public where id = $1`, [KIT]);
ok('products_public: kit available (2 can be built)', pub?.is_available === true);
const browsed = await q(`select id, is_available from public.rpc_browse_products(p_search => 'طقم', p_available_only => true)`);
ok('rpc_browse_products lists it under "available only"', browsed.some((r) => r.id === KIT && r.is_available));

await q(`select public.rpc_cart_set_item($1, 2)`, [KIT]);
let cart = (await one(`select public.rpc_get_my_cart() as c`)).c;
ok('cart: 2 kits available', cart.items.find((i) => i.product_id === KIT)?.is_available === true);
await q(`select public.rpc_cart_set_item($1, 3)`, [KIT]);
cart = (await one(`select public.rpc_get_my_cart() as c`)).c;
ok('cart: 3 kits not available (only 4 filters)', cart.items.find((i) => i.product_id === KIT)?.is_available === false);
await q(`select public.rpc_cart_set_item($1, 0)`, [KIT]);

// ---------------------------------------------------------------- order: confirm takes components
console.log('\n== Confirming an order takes the components ==');
const placeOrder = async (qty) => {
  await as(CUST_A);
  const id = (await one(`select public.rpc_create_order($1, $2, $3, null, null) as id`,
    [CUST_A, JSON.stringify([{ product_id: KIT, quantity: qty }]), addr])).id;
  await as(ADMIN);
  await q(`select public.rpc_admin_set_shipping_fee($1, 0)`, [id]);
  await as(CUST_A);
  await q(`select public.rpc_customer_respond_shipping_fee($1, true)`, [id]);
  await as(ADMIN);
  return id;
};
const o1 = await placeOrder(1);
await q(`select public.rpc_confirm_order($1)`, [o1]);
ok('1 iron out', await stock(IRON) === 2);
ok('2 filters out', await stock(FILTER) === 2);
await asSuper();
ok('components remembered on the order line',
  (await one(`select count(*)::int as n from public.order_item_components oic
              join public.order_items oi on oi.id = oic.order_item_id where oi.order_id = $1`, [o1])).n === 1);
await as(CUST_A);
pub = await one(`select is_available from public.products_public where id = $1`, [KIT]);
ok('still available (1 more can be built)', pub?.is_available === true);

// ---------------------------------------------------------------- cancel puts them back
console.log('\n== Cancelling a confirmed order puts the components back ==');
await as(ADMIN);
await q(`select public.rpc_cancel_order($1, 'العميل لغى')`, [o1]);
ok('iron back', await stock(IRON) === 3);
ok('filters back', await stock(FILTER) === 4);

// ---------------------------------------------------------------- return puts them back
console.log('\n== Returning a delivered order puts the components back ==');
const o2 = await placeOrder(2);
await q(`select public.rpc_confirm_order($1)`, [o2]);
ok('2 kits: 2 irons + 4 filters out', await stock(IRON) === 1 && await stock(FILTER) === 0);
await as(CUST_A);
pub = await one(`select is_available from public.products_public where id = $1`, [KIT]);
ok('now unavailable (no filters left)', pub?.is_available === false);
await as(ADMIN);
await q(`select public.rpc_update_order_status($1, 'preparing')`, [o2]);
await q(`select public.rpc_update_order_status($1, 'delivered')`, [o2]);
await q(`select public.rpc_admin_return_order($1, 'مرتجع')`, [o2]);
ok('return restocks components', await stock(IRON) === 3 && await stock(FILTER) === 4);

// ---------------------------------------------------------------- short component refuses confirm
console.log('\n== Confirm is refused when a component is short ==');
const o3 = await placeOrder(3);
const e = await err(`select public.rpc_confirm_order($1)`, [o3]);
ok('INSUFFICIENT_COMPONENT naming the filter', /INSUFFICIENT_COMPONENT: فلتر/.test(e ?? ''), e);
ok('nothing taken', await stock(IRON) === 3 && await stock(FILTER) === 4);
await asSuper();
ok('order still pending', (await one(`select status from public.orders where id = $1`, [o3])).status === 'pending');

// ---------------------------------------------------------------- normal products unchanged
console.log('\n== A normal product order still works as before ==');
await as(CUST_A);
const o4 = (await one(`select public.rpc_create_order($1, $2, $3, null, null) as id`,
  [CUST_A, JSON.stringify([{ product_id: IRON, quantity: 1 }]), addr])).id;
await as(ADMIN);
await q(`select public.rpc_admin_set_shipping_fee($1, 0)`, [o4]);
await as(CUST_A);
await q(`select public.rpc_customer_respond_shipping_fee($1, true)`, [o4]);
await as(ADMIN);
await q(`select public.rpc_confirm_order($1)`, [o4]);
ok('iron out', await stock(IRON) === 2);
await q(`select public.rpc_cancel_order($1, 'x')`, [o4]);
ok('iron back', await stock(IRON) === 3);

finish();
