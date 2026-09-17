// tool/db_tests/phase6_catalog_test.mjs
//
// Phase 6 (0034): rpc_browse_products — search (Arabic-normalised, wildcard
// safe), filters, sorts, pagination, visibility, and that no cost column or
// hidden product ever comes back.
//
//   cd tool/db_tests && npm install && npm test

import { setup, ADMIN, TECH, CUST_A } from './harness.mjs';

const { ok, finish, as, asSuper, q, one, err } = await setup(process.argv[2]);

const browse = (args = {}) => q(
  `select * from public.rpc_browse_products(
     p_search => $1, p_category_id => $2, p_min_price => $3, p_max_price => $4,
     p_available_only => $5, p_sort => $6, p_limit => $7, p_offset => $8)`,
  [args.search ?? null, args.category ?? null, args.min ?? null, args.max ?? null,
   args.availableOnly ?? false, args.sort ?? 'newest', args.limit ?? 20, args.offset ?? 0]);
const names = rows => rows.map(r => r.name);

// ---------------------------------------------------------------- seed
await as(ADMIN);
const irons = (await one(`insert into public.product_categories (name) values ('مكاوي') returning id`)).id;
const steam = (await one(`insert into public.product_categories (name, parent_id) values ('مكاوي بخار', $1) returning id`, [irons])).id;
const parts = (await one(`insert into public.product_categories (name) values ('قطع غيار') returning id`)).id;

const mk = async (sku, name, price, category, createdOffsetMin) => (await one(
  `insert into public.products (sku, name, cost_price, selling_price, category_id, created_at)
   values ($1, $2, $3, $4, $5, now() - make_interval(mins => $6)) returning id`,
  [sku, name, price / 2, price, category, createdOffsetMin])).id;

const A = await mk('IR-100', 'مكواة إحترافية', 900, irons, 50);
const B = await mk('ST-200', 'مكواة بخار كبيرة', 1500, steam, 40);
const C = await mk('PT-300', 'خرطوم بخار', 120, parts, 30);
const D = await mk('PT-400', 'فلتر 100%_مياه', 60, parts, 20);
const E = await mk('IR-500', 'مكواة موقوفة', 700, irons, 10);
await q(`update public.products set is_active = false where id = $1`, [E]);
const S = (await one(`insert into public.products (sku, name, cost_price, selling_price, is_service) values ('SV-1', 'خدمة مكواة', 0, 50, true) returning id`)).id;

await q(`select public.rpc_receive_purchase($1, 5, 450, 'seed')`, [A]);
await q(`select public.rpc_receive_purchase($1, 3, 60, 'seed')`, [C]);
await q(`insert into public.product_images (product_id, image_url, sort_order, is_primary) values
  ($1, 'https://x/a2.jpg', 1, false), ($1, 'https://x/a1.jpg', 0, true)`, [A]);

// ---------------------------------------------------------------- visibility
console.log('\n== Visibility ==');
await as(CUST_A);
const all = await browse();
ok('customer browses the live catalogue (4 products)', all.length === 4, JSON.stringify(names(all)));
ok('inactive products are hidden', !all.some(r => r.id === E));
ok('service lines are hidden', !all.some(r => r.id === S));
ok('no cost column is returned', !Object.keys(all[0]).some(k => k.includes('cost')));
const cols = Object.keys(all[0]).sort().join(',');
const viewCols = Object.keys((await q(`select * from public.products_public limit 1`))[0]).sort().join(',');
ok('columns match products_public exactly', cols === viewCols, `${cols} vs ${viewCols}`);
ok('availability comes from stock', all.find(r => r.id === A).is_available === true && all.find(r => r.id === B).is_available === false);
ok('primary image is the is_primary one', all.find(r => r.id === A).primary_image_url === 'https://x/a1.jpg');

await as(TECH);
ok('technicians can browse too', (await browse()).length === 4);
await as(null);
ok('anon cannot call the RPC', (await err(`select * from public.rpc_browse_products()`))?.includes('permission denied'));

// ---------------------------------------------------------------- search
console.log('\n== Search ==');
await as(CUST_A);
ok('search matches name', JSON.stringify(names(await browse({ search: 'خرطوم' }))) === JSON.stringify(['خرطوم بخار']));
ok('search matches SKU case-insensitively', (await browse({ search: 'ir-100' })).map(r => r.id).join() === A);
ok('hamza-insensitive: احترافية finds إحترافية', (await browse({ search: 'احترافيه' })).some(r => r.id === A));
ok('ta marbuta / ha are equivalent', (await browse({ search: 'كبيره' })).some(r => r.id === B));
ok('diacritics are ignored', (await browse({ search: 'مِكْوَاة' })).length === 2);
ok('% is literal, not a wildcard', JSON.stringify((await browse({ search: '%' })).map(r => r.id)) === JSON.stringify([D]));
ok('_ is literal, not a wildcard', JSON.stringify((await browse({ search: '_' })).map(r => r.id)) === JSON.stringify([D]));
ok('backslash is literal', (await browse({ search: '\\' })).length === 0);
ok('blank search is no filter', (await browse({ search: '   ' })).length === 4);
ok('search never surfaces an inactive product', (await browse({ search: 'موقوفة' })).length === 0);
ok('search over 100 chars is refused', (await err(`select * from public.rpc_browse_products(p_search => repeat('a', 101))`))?.includes('INPUT_TOO_LONG'));

// ---------------------------------------------------------------- filters
console.log('\n== Filters ==');
ok('category includes its sub-categories', (await browse({ category: irons })).map(r => r.id).sort().join() === [A, B].sort().join());
ok('sub-category alone', (await browse({ category: steam })).map(r => r.id).join() === B);
ok('price range', (await browse({ min: 100, max: 1000 })).map(r => r.id).sort().join() === [A, C].sort().join());
ok('available only', (await browse({ availableOnly: true })).map(r => r.id).sort().join() === [A, C].sort().join());
ok('filters combine with search', (await browse({ search: 'بخار', category: parts })).map(r => r.id).join() === C);
ok('min > max refused', (await err(`select * from public.rpc_browse_products(p_min_price => 10, p_max_price => 5)`))?.includes('INVALID_PRICE_RANGE'));
ok('negative price refused', (await err(`select * from public.rpc_browse_products(p_min_price => -1)`))?.includes('INVALID_PRICE_RANGE'));

// ---------------------------------------------------------------- sort + pages
console.log('\n== Sorting and pagination ==');
ok('newest first', JSON.stringify((await browse()).map(r => r.id)) === JSON.stringify([D, C, B, A]));
ok('price ascending', JSON.stringify((await browse({ sort: 'price_asc' })).map(r => r.id)) === JSON.stringify([D, C, A, B]));
ok('price descending', JSON.stringify((await browse({ sort: 'price_desc' })).map(r => r.id)) === JSON.stringify([B, A, C, D]));
ok('unknown sort refused', (await err(`select * from public.rpc_browse_products(p_sort => 'cost_price')`))?.includes('INVALID_SORT'));

const p1 = await browse({ sort: 'price_asc', limit: 3, offset: 0 });
const p2 = await browse({ sort: 'price_asc', limit: 3, offset: 3 });
ok('pages are disjoint and complete', p1.length === 3 && p2.length === 1
  && new Set([...p1, ...p2].map(r => r.id)).size === 4);

// Equal prices: the id tiebreak keeps page boundaries stable.
await as(ADMIN);
for (let i = 0; i < 6; i++) await mk(`EQ-${i}`, `منتج بنفس السعر ${i}`, 333, null, 5);
await as(CUST_A);
const eqPages = [];
for (let off = 0; off < 6; off += 2) eqPages.push(...await browse({ search: 'بنفس السعر', sort: 'price_asc', limit: 2, offset: off }));
ok('ties never repeat or skip across pages', new Set(eqPages.map(r => r.id)).size === 6 && eqPages.length === 6);

ok('limit above 50 refused', (await err(`select * from public.rpc_browse_products(p_limit => 51)`))?.includes('INVALID_PAGE'));
ok('limit 0 refused', (await err(`select * from public.rpc_browse_products(p_limit => 0)`))?.includes('INVALID_PAGE'));
ok('negative offset refused', (await err(`select * from public.rpc_browse_products(p_offset => -1)`))?.includes('INVALID_PAGE'));

// ---------------------------------------------------------------- misc
console.log('\n== Suspension, index, grants ==');
await asSuper();
await q(`update public.users set is_active = false where id = $1`, [CUST_A]);
await as(CUST_A);
ok('suspended customer cannot browse', (await err(`select * from public.rpc_browse_products()`))?.includes('FORBIDDEN'));
await asSuper();
await q(`update public.users set is_active = true where id = $1`, [CUST_A]);

await as(ADMIN);
ok('admin product writes still work with the expression index',
  (await err(`update public.products set name = 'مكواة احترافية جديدة' where id = $1`, [A])) === null);
ok('category name cannot be blank', (await err(`update public.product_categories set name = '  ' where id = $1`, [parts]))?.includes('product_categories_name_len'));
ok('category cannot be its own parent', (await err(`update public.product_categories set parent_id = id where id = $1`, [parts]))?.includes('product_categories_not_own_parent'));
await as(CUST_A);
ok('customer cannot edit categories', (await q(`update public.product_categories set name = 'x' where id = $1 returning id`, [parts])).length === 0);
ok('renamed product is found by its new name', (await browse({ search: 'جديدة' })).some(r => r.id === A));
const key = (await one(`select public.search_key('أإآ ة ى مِكْوَاة IR') as k`)).k;
ok('search_key normalises Arabic', key === 'ااا ه ي مكواه ir', JSON.stringify(key));

await asSuper();
ok('search index exists', (await q(`select 1 from pg_indexes where indexname = 'idx_products_search_key_trgm'`)).length === 1);
const leaked = await q(`
  select p.oid::regprocedure::text as f from pg_proc p join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public' and p.prokind = 'f'
    and not exists (select 1 from pg_depend d where d.classid = 'pg_proc'::regclass and d.objid = p.oid and d.deptype = 'e')
    and (has_function_privilege('anon', p.oid, 'execute')
         or (has_function_privilege('authenticated', p.oid, 'execute')
             and p.proname not in (select function_name from private.rpc_allowlist)))`);
ok('no function executable beyond the allowlist', leaked.length === 0, JSON.stringify(leaked));

finish();
