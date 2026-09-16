// tool/db_tests/phase8_checkout_test.mjs
//
// Phase 8 (0036): rpc_create_order now takes a saved address id instead of
// free text — server-side service-availability enforcement, address
// ownership, and a delivery snapshot that survives later edits/deletion of
// the saved address.
//
//   cd tool/db_tests && npm install && npm test

import { setup, ADMIN, CUST_A, CUST_B } from './harness.mjs';

const { ok, finish, as, asSuper, q, one, err } = await setup(process.argv[2]);

// Seeded by 0032: النصر (مدينة نصر) is covered, المعادي (Maadi) is not.
const NASR_CITY = [30.0561, 31.3301];
const MAADI = [29.9602, 31.2569];

await asSuper();
const cairo = (await one(`select id from public.cities where name_ar = 'القاهرة'`)).id;

const saveAddress = (customer, point, extra = {}) => as(customer).then(() => one(
  `select public.rpc_save_my_address(
     p_address_id => null, p_city_id => $1, p_label => $2, p_address_line => $3,
     p_latitude => $4, p_longitude => $5, p_building => $6, p_floor => $7,
     p_apartment => $8, p_landmark => $9, p_recipient_name => $10, p_phone => $11) as r`,
  [cairo, extra.label ?? 'المنزل', extra.line ?? 'شارع عباس العقاد',
   point[0], point[1], extra.building ?? '12', extra.floor ?? '3', extra.apartment ?? '7',
   extra.landmark ?? 'جنب الصيدلية', extra.recipient ?? 'أحمد علي', extra.phone ?? '+201001234567']));

await as(ADMIN);
const P1 = (await one(`insert into public.products (sku, name, cost_price, selling_price) values ('CK1', 'مكواة', 60, 100) returning id`)).id;
await q(`select public.rpc_receive_purchase($1, 10, 60, 'seed')`, [P1]);

const createOrder = (customer, items, addressId, requestId) => as(customer).then(() => one(
  `select public.rpc_create_order($1, $2, $3, $4, $5) as id`,
  [customer, JSON.stringify(items), addressId, 'اطرق الجرس', requestId ?? null]));
const createOrderErr = (customer, items, addressId, requestId) => as(customer).then(() => err(
  `select public.rpc_create_order($1, $2, $3, $4, $5)`,
  [customer, JSON.stringify(items), addressId, null, requestId ?? null]));

// ---------------------------------------------------------------- serviceable address
console.log('\n== Ordering to a serviceable address ==');
const homeA = (await saveAddress(CUST_A, NASR_CITY, { label: 'بيت العيلة' })).r;
ok('the saved address is covered', homeA.available === true);

const orderId = (await createOrder(CUST_A, [{ product_id: P1, quantity: 2 }], homeA.id)).id;
await asSuper();
const order = await one(`select * from public.orders where id = $1`, [orderId]);
ok('order snapshots the address line', order.delivery_address === 'شارع عباس العقاد');
ok('order snapshots recipient and phone', order.delivery_recipient_name === 'أحمد علي' && order.delivery_phone === '+201001234567');
ok('order snapshots building/floor/apartment/landmark', order.delivery_building === '12' && order.delivery_floor === '3'
  && order.delivery_apartment === '7' && order.delivery_landmark === 'جنب الصيدلية');
ok('order snapshots the address id, city and service area', order.delivery_address_id === homeA.id
  && order.delivery_city_id === cairo && order.delivery_service_area_id === homeA.service_area_id);
ok('total still comes from the database price (2 × 100)', Number(order.total) === 200);

// ---------------------------------------------------------------- uncovered address
console.log('\n== An uncovered address is refused ==');
const workA = (await saveAddress(CUST_A, MAADI, { label: 'الشغل' })).r;
ok('this address is not covered', workA.available === false);
ok('order to an uncovered address is refused',
  (await createOrderErr(CUST_A, [{ product_id: P1, quantity: 1 }], workA.id))?.includes('ADDRESS_NOT_SERVICEABLE'));

// ---------------------------------------------------------------- ownership
console.log('\n== Address ownership ==');
const homeB = (await saveAddress(CUST_B, NASR_CITY, { label: 'بيت ب' })).r;
ok('customer A cannot order to customer B\'s address',
  (await createOrderErr(CUST_A, [{ product_id: P1, quantity: 1 }], homeB.id))?.includes('ADDRESS_NOT_FOUND'));
ok('a made-up address id is refused',
  (await createOrderErr(CUST_A, [{ product_id: P1, quantity: 1 }], '00000000-0000-4000-8000-000000000000'))?.includes('ADDRESS_NOT_FOUND'));

// ---------------------------------------------------------------- the old signature is gone
console.log('\n== The free-text signature no longer exists ==');
await as(CUST_A);
ok('the pre-0036 rpc_create_order(text, numeric, numeric, ...) is gone',
  (await err(`select public.rpc_create_order($1, $2, 'free text address', 30.0, 31.0, 'note', null)`,
    [CUST_A, JSON.stringify([{ product_id: P1, quantity: 1 }])]))?.includes('does not exist'));

// ---------------------------------------------------------------- idempotency survives the new signature
console.log('\n== Idempotency ==');
const reqId = '11111111-2222-4333-8444-555555555555';
const first = await createOrder(CUST_A, [{ product_id: P1, quantity: 1 }], homeA.id, reqId);
const second = await createOrder(CUST_A, [{ product_id: P1, quantity: 1 }], homeA.id, reqId);
ok('same client_request_id returns the same order', first.id === second.id);

// ---------------------------------------------------------------- snapshot independence
console.log('\n== The snapshot is independent of the live address ==');
await as(CUST_A);
await one(
  `select public.rpc_save_my_address(
     p_address_id => $1, p_city_id => $2, p_label => $3, p_address_line => 'عنوان جديد بعد الطلب',
     p_latitude => $4, p_longitude => $5, p_building => '99') as r`,
  [homeA.id, cairo, 'بيت العيلة', NASR_CITY[0], NASR_CITY[1]]);
await asSuper();
const afterEdit = await one(`select delivery_address, delivery_building from public.orders where id = $1`, [orderId]);
ok('editing the saved address does not change a past order',
  afterEdit.delivery_address === 'شارع عباس العقاد' && afterEdit.delivery_building === '12');

await as(CUST_A);
await q(`select public.rpc_delete_my_address($1)`, [homeA.id]);
await asSuper();
const afterDelete = await one(`select delivery_address_id, delivery_address from public.orders where id = $1`, [orderId]);
ok('deleting (soft) the saved address leaves the order\'s snapshot intact',
  afterDelete.delivery_address_id === homeA.id && afterDelete.delivery_address === 'شارع عباس العقاد');

// ---------------------------------------------------------------- grants
console.log('\n== Grants ==');
const leaked = await q(`
  select p.oid::regprocedure::text as f from pg_proc p join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public' and p.prokind = 'f'
    and not exists (select 1 from pg_depend d where d.classid = 'pg_proc'::regclass and d.objid = p.oid and d.deptype = 'e')
    and (has_function_privilege('anon', p.oid, 'execute')
         or (has_function_privilege('authenticated', p.oid, 'execute')
             and p.proname not in (select function_name from private.rpc_allowlist)))`);
ok('no function executable beyond the allowlist', leaked.length === 0, JSON.stringify(leaked));

finish();
