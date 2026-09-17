// tool/db_tests/phase5_storefront_test.mjs
//
// Phase 5 (0033): featured products, offers, home banners — visibility by
// schedule, admin-only management, and above all that offers never change
// what an order costs.
//
//   cd tool/db_tests && npm install && npm test

import { setup, ADMIN, TECH, CUST_A } from './harness.mjs';

const { ok, finish, as, asSuper, q, one, err } = await setup(process.argv[2]);

await as(ADMIN);
const P1 = (await one(`insert into public.products (sku, name, cost_price, selling_price) values ('F1', 'مكواة 1', 60, 100) returning id`)).id;
const P2 = (await one(`insert into public.products (sku, name, cost_price, selling_price) values ('F2', 'مكواة 2', 70, 150) returning id`)).id;
await q(`select public.rpc_receive_purchase($1, 10, 60, 'seed')`, [P1]);
const cat = (await one(`insert into public.product_categories (name) values ('مكاوي') returning id`)).id;

// ---------------------------------------------------------------- featured
console.log('\n== Featured products ==');
await as(CUST_A);
ok('customer cannot mark a product featured (RLS matches no row)',
  (await q(`update public.products set is_featured = true where id = $1 returning id`, [P1])).length === 0);
await as(ADMIN);
await q(`update public.products set is_featured = true, featured_sort = 1 where id = $1`, [P1]);
await as(CUST_A);
const pub = await one(`select * from public.products_public where id = $1`, [P1]);
ok('products_public exposes is_featured', pub.is_featured === true && pub.featured_sort === 1);
ok('products_public still has no cost column', !Object.keys(pub).some(k => k.includes('cost')));
ok('products_public still lists availability and image columns', 'is_available' in pub && 'primary_image_url' in pub);

// ---------------------------------------------------------------- offers
console.log('\n== Offers ==');
await as(CUST_A);
ok('customer cannot create an offer',
  (await err(`insert into public.offers (title, is_active) values ('x', true)`))?.includes('row-level security'));

await as(ADMIN);
const live = (await one(`insert into public.offers (title, badge_text, is_active) values ('توصيل مجاني', 'توصيل مجاني', true) returning id`)).id;
const draft = (await one(`insert into public.offers (title, is_active) values ('مسودة', false) returning id`)).id;
const future = (await one(`insert into public.offers (title, is_active, starts_at) values ('قادم', true, now() + interval '1 day') returning id`)).id;
const expired = (await one(`insert into public.offers (title, is_active, ends_at) values ('انتهى', true, now() - interval '1 minute') returning id`)).id;
for (const o of [live, draft, future, expired]) {
  await q(`insert into public.offer_products (offer_id, product_id) values ($1, $2), ($1, $3)`, [o, P1, P2]);
}
ok('end before start refused', (await err(`insert into public.offers (title, starts_at, ends_at) values ('x', now(), now() - interval '1 hour')`)) !== null);

await as(CUST_A);
const visible = (await q(`select id from public.offers`)).map(r => r.id);
ok('customer sees the live offer', visible.includes(live));
ok('customer does not see a switched-off offer', !visible.includes(draft));
ok('customer does not see an offer before it starts', !visible.includes(future));
ok('customer does not see an expired offer', !visible.includes(expired));
ok('live offer lists its products', (await q(`select * from public.rpc_offer_products($1)`, [live])).length === 2);
ok('offer products carry no cost column',
  !Object.keys((await q(`select * from public.rpc_offer_products($1)`, [live]))[0]).some(k => k.includes('cost')));
ok('a hidden offer\'s products are hidden too', (await q(`select * from public.rpc_offer_products($1)`, [draft])).length === 0);
ok('customer cannot attach products to an offer',
  (await err(`insert into public.offer_products (offer_id, product_id) values ($1, $2)`, [draft, P1]))?.includes('row-level security'));
ok('customer cannot switch an offer on', (await q(`update public.offers set is_active = true where id = $1 returning id`, [draft])).length === 0);
await as(TECH);
ok('technician cannot create offers either',
  (await err(`insert into public.offers (title) values ('x')`))?.includes('row-level security'));

await as(ADMIN);
ok('admin sees every offer', (await q(`select id from public.offers`)).length === 4);
ok('admin can detach a product', (await err(`delete from public.offer_products where offer_id = $1 and product_id = $2`, [live, P2])) === null);
ok('nobody can delete an offer', (await err(`delete from public.offers where id = $1`, [expired]))?.includes('permission denied'));

// ---------------------------------------------------------------- price is fixed
console.log('\n== Offers never change the order price ==');
// 0036: rpc_create_order now takes a saved, serviceable address.
await as(CUST_A);
const cairo = (await one(`select id from public.cities where name_ar = 'القاهرة'`)).id;
const addrA = (await one(`select public.rpc_save_my_address(
  p_address_id => null, p_city_id => $1, p_label => 'المنزل', p_address_line => 'addr',
  p_latitude => 30.0561, p_longitude => 31.3301) as r`, [cairo])).r.id;
const orderId = (await one(`select public.rpc_create_order($1, $2, $3, null, null) as id`,
  [CUST_A, JSON.stringify([{ product_id: P1, quantity: 2 }]), addrA])).id;
ok('order in a live offer charges selling_price × qty (200)',
  Number((await one(`select total from public.orders where id = $1`, [orderId])).total) === 200);

// ---------------------------------------------------------------- banners
console.log('\n== Home banners ==');
await as(ADMIN);
const bLive = (await one(`insert into public.home_banners (title, image_url, target_type, target_id, is_active) values ('عرض', 'https://x/b.jpg', 'offer', $1, true) returning id`, [live])).id;
const bOff = (await one(`insert into public.home_banners (title, image_url, is_active) values ('مقفول', 'https://x/c.jpg', false) returning id`)).id;
await q(`insert into public.home_banners (title, image_url, target_type, is_active, ends_at) values ('قديم', 'https://x/d.jpg', 'maintenance', true, now() - interval '1 hour')`);
await q(`insert into public.home_banners (title, image_url, target_type, target_id, is_active) values ('قسم', 'https://x/e.jpg', 'category', $1, true)`, [cat]);
ok('banner to a missing product refused',
  (await err(`insert into public.home_banners (title, image_url, target_type, target_id) values ('x', 'https://x', 'product', gen_random_uuid())`))?.includes('BANNER_TARGET_NOT_FOUND'));
ok('offer/category/product targets need an id',
  (await err(`insert into public.home_banners (title, image_url, target_type) values ('x', 'https://x', 'offer')`)) !== null);
ok('"none" and "maintenance" must not carry an id',
  (await err(`insert into public.home_banners (title, image_url, target_type, target_id) values ('x', 'https://x', 'none', $1)`, [cat])) !== null);

await as(CUST_A);
const bannerRows = await q(`select id, title from public.home_banners`);
ok('customer reads the live banner by id', bannerRows.some(r => r.id === bLive));
const banners = bannerRows.map(r => r.title).sort();
ok('customer sees only live banners', JSON.stringify(banners) === JSON.stringify(['عرض', 'قسم'].sort()));
ok('customer cannot create banners',
  (await err(`insert into public.home_banners (title, image_url) values ('x', 'https://x')`))?.includes('row-level security'));
ok('customer cannot switch a banner on', (await q(`update public.home_banners set is_active = true where id = $1 returning id`, [bOff])).length === 0);
await as(null);
ok('anon reads no banners', (await err(`select * from public.home_banners`))?.includes('permission denied'));
ok('anon reads no offers', (await err(`select * from public.offers`))?.includes('permission denied'));

await asSuper();
ok('offer and banner changes are audited',
  (await one(`select count(*)::int as n from public.audit_logs where table_name in ('offers', 'home_banners')`)).n >= 8);

// ---------------------------------------------------------------- storage + grants
console.log('\n== Storage and grants ==');
await asSuper();
ok('marketing bucket is public', (await one(`select public from storage.buckets where id = 'marketing'`)).public === true);
const leaked = await q(`
  select p.oid::regprocedure::text as f from pg_proc p join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public' and p.prokind = 'f'
    and not exists (select 1 from pg_depend d where d.classid = 'pg_proc'::regclass and d.objid = p.oid and d.deptype = 'e')
    and (has_function_privilege('anon', p.oid, 'execute')
         or (has_function_privilege('authenticated', p.oid, 'execute')
             and p.proname not in (select function_name from private.rpc_allowlist)))`);
ok('no function executable beyond the allowlist', leaked.length === 0, JSON.stringify(leaked));

finish();
