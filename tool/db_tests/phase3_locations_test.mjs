// tool/db_tests/phase3_locations_test.mjs
//
// Phase 3 (0032): coverage (countries → cities → service areas), customer
// addresses, server-side availability, and re-resolution when coverage
// changes.
//
//   cd tool/db_tests && npm install && npm test

import { setup, ADMIN, TECH, CUST_A, CUST_B } from './harness.mjs';

const { ok, finish, as, asSuper, q, one, err } = await setup(process.argv[2]);

// Points used throughout (approximate, Cairo).
const NASR_CITY = [30.0561, 31.3301];       // inside "مدينة نصر" (seeded)
const NEW_CAIRO = [30.0074, 31.4913];       // inside "التجمع الخامس" (seeded)
const MAADI = [29.9602, 31.2569];           // Cairo, no seeded area
const ASWAN = [24.0889, 32.8998];           // far from Cairo

await asSuper();
const cairo = (await one(`select id from public.cities where name_ar = 'القاهرة'`)).id;
const giza = (await one(`select id from public.cities where name_ar = 'الجيزة'`)).id;
const egypt = (await one(`select id from public.countries where iso_code = 'EG'`)).id;

const save = (customer, args) => as(customer).then(() => one(
  `select public.rpc_save_my_address(
     p_address_id => $1, p_city_id => $2, p_label => $3, p_address_line => $4,
     p_latitude => $5, p_longitude => $6, p_make_default => $7, p_phone => $8) as r`,
  [args.id ?? null, args.city ?? cairo, args.label ?? 'المنزل', args.line ?? 'شارع عباس العقاد',
   args.point[0], args.point[1], args.makeDefault ?? false, args.phone ?? null]));
const saveErr = (customer, args) => as(customer).then(() => err(
  `select public.rpc_save_my_address(
     p_address_id => $1, p_city_id => $2, p_label => $3, p_address_line => $4,
     p_latitude => $5, p_longitude => $6, p_phone => $7)`,
  [args.id ?? null, args.city ?? cairo, args.label ?? 'المنزل', args.line ?? 'شارع عباس العقاد',
   args.point[0], args.point[1], args.phone ?? null]));
const addr = async (id) => { await asSuper(); return one(`select * from public.customer_addresses where id = $1`, [id]); };

// ---------------------------------------------------------------- launch data
console.log('\n== Launch data ==');
await as(CUST_A);
ok('customer sees Egypt only', (await q(`select iso_code from public.countries`)).map(r => r.iso_code).join() === 'EG');
ok('customer sees the three launch cities', (await q(`select 1 from public.cities`)).length === 3);
ok('three seeded Cairo areas', (await q(`select 1 from public.service_areas where city_id = $1`, [cairo])).length === 3);

// ---------------------------------------------------------------- availability check
console.log('\n== Availability check (before saving) ==');
const check = async (city, [lat, lng]) => (await one(`select public.rpc_check_service_availability($1, $2, $3) as r`, [city, lat, lng])).r;
await as(CUST_A);
ok('Nasr City pin is covered', (await check(cairo, NASR_CITY)).available === true);
ok('covered pin names its area', (await check(cairo, NASR_CITY)).service_area_name === 'مدينة نصر');
ok('New Cairo pin resolves to its own area', (await check(cairo, NEW_CAIRO)).service_area_name === 'التجمع الخامس');
ok('Maadi pin is not covered',(await check(cairo, MAADI)).available === false);
ok('a covered point under the wrong city is not covered', (await check(giza, NASR_CITY)).available === false);
ok('out-of-range coordinates refused', (await err(`select public.rpc_check_service_availability($1, 95, 31)`, [cairo]))?.includes('INVALID_LOCATION'));
await as(null);
ok('anon cannot probe coverage', (await err(`select public.rpc_check_service_availability($1, 30, 31)`, [cairo]))?.includes('permission denied'));

// ---------------------------------------------------------------- saving
console.log('\n== Saving addresses ==');
const home = (await save(CUST_A, { point: NASR_CITY, phone: '010 1234 5678' })).r;
ok('save returns availability', home.available === true && home.service_area_name === 'مدينة نصر');
let row = await addr(home.id);
ok('first address becomes default automatically', row.is_default === true);
ok('area and country resolved server-side', row.service_area_id !== null && row.country_id === egypt);
ok('phone normalised', row.phone === '01012345678');

const work = (await save(CUST_A, { point: MAADI, label: 'الشغل' })).r;
ok('uncovered address still saves, flagged unavailable', work.available === false && (await addr(work.id)).service_area_id === null);
ok('second address is not default', (await addr(work.id)).is_default === false);

ok('pin far from the chosen city refused', (await saveErr(CUST_A, { point: ASWAN }))?.includes('LOCATION_OUTSIDE_CITY'));
ok('empty label refused', (await saveErr(CUST_A, { point: NASR_CITY, label: '  ' }))?.includes('INVALID_INPUT'));
ok('bad phone refused', (await saveErr(CUST_A, { point: NASR_CITY, phone: 'abc' }))?.includes('INVALID_PHONE'));
ok('over-long label refused', (await saveErr(CUST_A, { point: NASR_CITY, label: 'x'.repeat(41) }))?.includes('INPUT_TOO_LONG'));

await as(ADMIN);
await q(`update public.cities set is_active = false where id = $1`, [giza]);
ok('inactive city refused', (await saveErr(CUST_A, { city: giza, point: [30.0131, 31.2089] }))?.includes('CITY_NOT_AVAILABLE'));
await as(ADMIN);
await q(`update public.cities set is_active = true where id = $1`, [giza]);

// ---------------------------------------------------------------- defaults
console.log('\n== Default address ==');
await save(CUST_A, { id: work.id, point: MAADI, label: 'الشغل', makeDefault: true });
ok('making another address default moves the default', (await addr(work.id)).is_default && !(await addr(home.id)).is_default);
await as(CUST_A);
await q(`select public.rpc_set_default_address($1)`, [home.id]);
ok('rpc_set_default_address moves it back', (await addr(home.id)).is_default && !(await addr(work.id)).is_default);
await asSuper();
ok('never two defaults', (await one(`select count(*)::int as n from public.customer_addresses where customer_id = $1 and is_default`, [CUST_A])).n === 1);

await as(CUST_A);
await q(`select public.rpc_delete_my_address($1)`, [home.id]);
ok('deleting is a soft delete', (await addr(home.id)).is_active === false);
ok('deleting the default promotes a remaining address', (await addr(work.id)).is_default === true);
await as(CUST_A);
ok('deleted address disappears from the customer\'s list', (await q(`select id from public.customer_addresses where id = $1`, [home.id])).length === 0);
ok('deleting twice refused', (await err(`select public.rpc_delete_my_address($1)`, [home.id]))?.includes('ADDRESS_NOT_FOUND'));

// ---------------------------------------------------------------- ownership / IDOR
console.log('\n== Ownership ==');
await as(CUST_B);
ok('customer B cannot read A\'s addresses', (await q(`select id from public.customer_addresses where customer_id = $1`, [CUST_A])).length === 0);
ok('customer B cannot edit A\'s address', (await saveErr(CUST_B, { id: work.id, point: NASR_CITY }))?.includes('ADDRESS_NOT_FOUND'));
await as(CUST_B);
ok('customer B cannot default A\'s address', (await err(`select public.rpc_set_default_address($1)`, [work.id]))?.includes('ADDRESS_NOT_FOUND'));
ok('customer B cannot delete A\'s address', (await err(`select public.rpc_delete_my_address($1)`, [work.id]))?.includes('ADDRESS_NOT_FOUND'));
await as(CUST_A);
ok('customer cannot insert addresses directly',
  (await err(`insert into public.customer_addresses (customer_id, country_id, city_id, label, address_line, latitude, longitude) values ($1, $2, $3, 'x', 'xxx', 30, 31)`, [CUST_A, egypt, cairo]))?.includes('permission denied'));
ok('customer cannot force a service area on their address',
  (await err(`update public.customer_addresses set service_area_id = null where id = $1`, [work.id]))?.includes('permission denied'));
await as(TECH);
ok('technician cannot save addresses', (await saveErr(TECH, { point: NASR_CITY }))?.includes('FORBIDDEN'));
await as(ADMIN);
ok('admin reads all addresses', (await q(`select id from public.customer_addresses where customer_id = $1`, [CUST_A])).length === 2);

// ---------------------------------------------------------------- cap
console.log('\n== Per-customer cap ==');
for (let i = 0; i < 9; i++) await save(CUST_B, { point: NASR_CITY, label: `عنوان ${i}` });
ok('tenth address saves', (await save(CUST_B, { point: NASR_CITY, label: 'عنوان 9' })).r.id !== undefined);
ok('eleventh address refused', (await saveErr(CUST_B, { point: NASR_CITY, label: 'عنوان 10' }))?.includes('TOO_MANY_ADDRESSES'));

// ---------------------------------------------------------------- coverage management
console.log('\n== Coverage management re-resolves addresses ==');
await as(CUST_A);
ok('customer cannot create service areas',
  (await err(`insert into public.service_areas (city_id, name_ar, center_latitude, center_longitude, radius_km) values ($1, 'x', 30, 31, 1)`, [cairo]))?.includes('row-level security'));
ok('customer cannot switch an area off',
  (await q(`update public.service_areas set is_active = false returning id`)).length === 0);

await as(ADMIN);
const maadi = (await one(`insert into public.service_areas (city_id, name_ar, center_latitude, center_longitude, radius_km)
  values ($1, 'المعادي', $2, $3, 3) returning id`, [cairo, MAADI[0], MAADI[1]])).id;
ok('adding an area covers existing addresses inside it', (await addr(work.id)).service_area_id === maadi);

await as(ADMIN);
await q(`update public.service_areas set is_active = false where id = $1`, [maadi]);
ok('switching the area off uncovers them', (await addr(work.id)).service_area_id === null);
await as(ADMIN);
await q(`update public.service_areas set is_active = true, radius_km = 0.5, center_latitude = 29.99 where id = $1`, [maadi]);
ok('moving the area away keeps them uncovered', (await addr(work.id)).service_area_id === null);
await as(ADMIN);
await q(`update public.service_areas set center_latitude = $2, radius_km = 3 where id = $1`, [maadi, MAADI[0]]);
ok('moving it back covers them again', (await addr(work.id)).service_area_id === maadi);

await as(ADMIN);
await q(`update public.cities set is_active = false where id = $1`, [cairo]);
ok('switching the city off uncovers its addresses', (await addr(work.id)).service_area_id === null);
await as(ADMIN);
await q(`update public.cities set is_active = true where id = $1`, [cairo]);
ok('switching it back on restores coverage', (await addr(work.id)).service_area_id === maadi);
await as(ADMIN);
await q(`update public.countries set is_active = false where id = $1`, [egypt]);
ok('switching the country off uncovers everything in it', (await addr(work.id)).service_area_id === null);
await as(ADMIN);
await q(`update public.countries set is_active = true where id = $1`, [egypt]);
ok('and back on restores it', (await addr(work.id)).service_area_id === maadi);

await asSuper();
const before = (await addr(work.id)).updated_at;
await as(ADMIN);
await q(`update public.service_areas set notes = 'x' where id = $1`, [maadi]);
ok('re-resolution does not count as the customer editing the address', (await addr(work.id)).updated_at.getTime() === before.getTime());
await asSuper();
ok('coverage changes are audited', (await one(`select count(*)::int as n from public.audit_logs where table_name = 'service_areas'`)).n >= 5);

// ---------------------------------------------------------------- profile city
console.log('\n== Profile city ==');
await as(CUST_A);
await q(`select public.rpc_set_my_city($1)`, [giza]);
await asSuper();
ok('customer sets their city', (await one(`select city_id from public.customers where id = $1`, [CUST_A])).city_id === giza);
await as(CUST_A);
ok('customer cannot write city_id directly', (await err(`update public.customers set city_id = $1 where id = $2`, [cairo, CUST_A]))?.includes('permission denied'));
await as(ADMIN);
await q(`update public.cities set is_active = false where id = $1`, [giza]);
await as(CUST_A);
ok('inactive city refused', (await err(`select public.rpc_set_my_city($1)`, [giza]))?.includes('CITY_NOT_AVAILABLE'));

// ---------------------------------------------------------------- serviceability helper + grants
console.log('\n== Checkout helper and grants ==');
await asSuper();
ok('address_is_serviceable reflects coverage', (await one(`select private.address_is_serviceable($1) as s`, [work.id])).s === true);
ok('a deleted address is never serviceable', (await one(`select private.address_is_serviceable($1) as s`, [home.id])).s === false);
await as(CUST_A);
ok('clients cannot call the private helpers', (await err(`select private.address_is_serviceable($1)`, [work.id]))?.includes('permission denied'));
await asSuper();
const leaked = await q(`
  select p.oid::regprocedure::text as f from pg_proc p join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public' and p.prokind = 'f'
    and not exists (select 1 from pg_depend d where d.classid = 'pg_proc'::regclass and d.objid = p.oid and d.deptype = 'e')
    and (has_function_privilege('anon', p.oid, 'execute')
         or (has_function_privilege('authenticated', p.oid, 'execute')
             and p.proname not in (select function_name from private.rpc_allowlist)))`);
ok('no function executable beyond the allowlist', leaked.length === 0, JSON.stringify(leaked));
const anonTables = await q(`
  select c.relname from pg_class c join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public' and c.relname in ('countries','cities','service_areas','customer_addresses')
    and (has_table_privilege('anon', c.oid, 'select') or has_table_privilege('authenticated', c.oid, 'delete'))`);
ok('new tables: no anon access, no DELETE for anyone', anonTables.length === 0, JSON.stringify(anonTables));

finish();
