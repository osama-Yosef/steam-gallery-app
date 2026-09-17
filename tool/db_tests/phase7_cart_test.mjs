// tool/db_tests/phase7_cart_test.mjs
//
// Phase 7 (0035): server-side cart — ownership, bounds, server pricing,
// price-change and availability flags, no direct writes.
//
//   cd tool/db_tests && npm install && npm test

import { setup, ADMIN, TECH, CUST_A, CUST_B } from './harness.mjs';

const { ok, finish, as, asSuper, q, one, err } = await setup(process.argv[2]);

await as(ADMIN);
const mk = async (sku, price) => (await one(
  `insert into public.products (sku, name, cost_price, selling_price) values ($1, $1, $2, $3) returning id`,
  [sku, price / 2, price])).id;
const P1 = await mk('C1', 100);
const P2 = await mk('C2', 250.5);
const P3 = await mk('C3', 40);
const SVC = (await one(`insert into public.products (sku, name, cost_price, selling_price, is_service) values ('SV', 'خدمة', 0, 30, true) returning id`)).id;
await q(`select public.rpc_receive_purchase($1, 5, 50, 'seed')`, [P1]);
await q(`select public.rpc_receive_purchase($1, 1, 100, 'seed')`, [P2]);

const cart = async () => (await one(`select public.rpc_get_my_cart() as c`)).c;
const set = (p, n) => one(`select public.rpc_cart_set_item($1, $2) as c`, [p, n]).then(r => r.c);
const add = (p, n) => one(`select public.rpc_cart_add_item($1, $2) as c`, [p, n]).then(r => r.c);

// ---------------------------------------------------------------- basics
console.log('\n== Basics ==');
await as(CUST_A);
let c = await cart();
ok('empty cart', c.items.length === 0 && Number(c.subtotal) === 0 && c.item_count === 0);
c = await add(P1, 2);
c = await add(P2, 1);
ok('two lines', c.items.length === 2 && c.item_count === 3);
ok('subtotal is computed from DB prices (2×100 + 250.50)', Number(c.subtotal) === 450.5, c.subtotal);
ok('lines carry no cost column', !JSON.stringify(c).includes('cost'));
c = await add(P1, 3);
ok('add accumulates', c.items.find(i => i.product_id === P1).quantity === 5);
c = await add(P1, 19);
ok('add caps at 20', c.items.find(i => i.product_id === P1).quantity === 20);
c = await set(P1, 4);
ok('set replaces the quantity', c.items.find(i => i.product_id === P1).quantity === 4);
c = await set(P2, 0);
ok('set 0 removes the line', !c.items.some(i => i.product_id === P2));

ok('quantity above 20 refused', (await err(`select public.rpc_cart_set_item($1, 21)`, [P1]))?.includes('INVALID_QUANTITY'));
ok('negative quantity refused', (await err(`select public.rpc_cart_set_item($1, -1)`, [P1]))?.includes('INVALID_QUANTITY'));
ok('service lines cannot be added', (await err(`select public.rpc_cart_add_item($1, 1)`, [SVC]))?.includes('PRODUCT_NOT_FOUND'));
ok('unknown product refused', (await err(`select public.rpc_cart_add_item(gen_random_uuid(), 1)`))?.includes('PRODUCT_NOT_FOUND'));

// ---------------------------------------------------------------- isolation
console.log('\n== Ownership ==');
await as(CUST_B);
ok('another customer sees an empty cart', (await cart()).items.length === 0);
ok('and cannot read A\'s rows directly', (await q(`select * from public.cart_items`)).length === 0);
ok('direct insert is denied', (await err(`insert into public.cart_items (customer_id, product_id, quantity, price_seen) values ($1, $2, 1, 0)`, [CUST_A, P3]))?.includes('permission denied'));
await as(CUST_A);
ok('direct update is denied (price_seen tampering)', (await err(`update public.cart_items set price_seen = 1`))?.includes('permission denied'));
ok('direct delete is denied', (await err(`delete from public.cart_items`))?.includes('permission denied'));
await as(TECH);
ok('technicians have no cart', (await err(`select public.rpc_get_my_cart()`))?.includes('FORBIDDEN'));
await as(null);
ok('anon cannot call cart RPCs', (await err(`select public.rpc_get_my_cart()`))?.includes('permission denied'));
await as(ADMIN);
ok('admin can read carts for support', (await q(`select * from public.cart_items where customer_id = $1`, [CUST_A])).length === 1);

// ---------------------------------------------------------------- price / availability
console.log('\n== Price changes and availability ==');
await as(CUST_A);
await add(P2, 3); // only 1 in stock
await as(ADMIN);
await q(`update public.products set selling_price = 120 where id = $1`, [P1]);
await as(CUST_A);
c = await cart();
const l1 = c.items.find(i => i.product_id === P1);
ok('price change is flagged with old and new price', l1.price_changed === true && Number(l1.price_seen) === 100 && Number(l1.unit_price) === 120);
ok('subtotal uses the new price', Number(c.subtotal) === 4 * 120 + 3 * 250.5, c.subtotal);
ok('quantity above stock is flagged unavailable', c.items.find(i => i.product_id === P2).is_available === false);
ok('has_issues set', c.has_issues === true);
c = (await one(`select public.rpc_cart_acknowledge_prices() as c`)).c;
ok('acknowledging clears the price flag', !c.items.find(i => i.product_id === P1).price_changed);

await as(ADMIN);
await q(`update public.products set is_active = false where id = $1`, [P2]);
await as(CUST_A);
c = await cart();
const l2 = c.items.find(i => i.product_id === P2);
ok('switched-off product stays visible but inactive', l2 && l2.is_active === false && Number(l2.line_total) === 0);
ok('and is excluded from subtotal and count', Number(c.subtotal) === 480 && c.item_count === 4);
ok('cannot raise quantity of a switched-off product', (await err(`select public.rpc_cart_set_item($1, 2)`, [P2]))?.includes('PRODUCT_NOT_FOUND'));
c = await set(P2, 0);
ok('but can remove it', !c.items.some(i => i.product_id === P2));

// ---------------------------------------------------------------- cap + clear
console.log('\n== Line cap and clear ==');
await as(ADMIN);
const many = [];
for (let i = 0; i < 30; i++) many.push(await mk(`M${i}`, 10));
await as(CUST_A);
let full = null;
for (const p of many) { full = await err(`select public.rpc_cart_add_item($1, 1)`, [p]); if (full) break; }
ok('31st distinct line refused with CART_FULL', full?.includes('CART_FULL'), full);
ok('existing lines can still change when full', (await err(`select public.rpc_cart_set_item($1, 2)`, [P1])) === null);
c = (await one(`select public.rpc_cart_clear() as c`)).c;
ok('clear empties the cart', c.items.length === 0);

await asSuper();
const leaked = await q(`
  select p.oid::regprocedure::text as f from pg_proc p join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public' and p.prokind = 'f'
    and not exists (select 1 from pg_depend d where d.classid = 'pg_proc'::regclass and d.objid = p.oid and d.deptype = 'e')
    and (has_function_privilege('anon', p.oid, 'execute')
         or (has_function_privilege('authenticated', p.oid, 'execute')
             and p.proname not in (select function_name from private.rpc_allowlist)))`);
ok('no function executable beyond the allowlist', leaked.length === 0, JSON.stringify(leaked));

finish();
