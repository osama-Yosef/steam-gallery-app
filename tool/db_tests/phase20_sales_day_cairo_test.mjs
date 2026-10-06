// tool/db_tests/phase20_sales_day_cairo_test.mjs
//
// 0078: daily_sales_summary groups by the Cairo calendar day. Regression for
// the live report: a sale at 00:30 Cairo time (21:30 UTC the day before)
// didn't count in "مبيعات اليوم".
//
//   cd tool/db_tests && npm install && node phase20_sales_day_cairo_test.mjs

import { randomUUID } from 'node:crypto';
import { setup, ADMIN } from './harness.mjs';

const { ok, finish, as, asSuper, q, one } = await setup(process.argv[2]);

await as(ADMIN);
const P = (await one(`insert into public.products (sku, name, cost_price, selling_price) values ('TZ1', 'مكواة', 40, 100) returning id`)).id;
await q(`select public.rpc_receive_purchase($1, 10, 40, 'seed')`, [P]);

const sell = async (atUtc) => {
  await as(ADMIN);
  const id = (await one(`select public.rpc_admin_walk_in_sale(null, null, $1, 'cash', 0, $2, null) as id`,
    [JSON.stringify([{ product_id: P, quantity: 1 }]), randomUUID()])).id;
  await asSuper();
  await q(`alter table public.sales disable trigger user`);
  await q(`update public.sales set created_at = $1 where id = $2`, [atUtc, id]);
  await q(`alter table public.sales enable trigger user`);
};

console.log('\n== A sale after midnight Cairo time counts on the Cairo day ==');
await sell('2026-10-06T21:30:00Z'); // 00:30 on 7 Oct in Cairo (UTC+3)
await sell('2026-10-06T20:30:00Z'); // 23:30 on 6 Oct in Cairo

await as(ADMIN);
const rows = await q(`select to_char(day at time zone 'Africa/Cairo', 'YYYY-MM-DD HH24:MI') as cairo_day, revenue::numeric
                      from public.daily_sales_summary order by day`);
const byDay = Object.fromEntries(rows.map((r) => [r.cairo_day, Number(r.revenue)]));
ok('00:30 Cairo sale is on 7 Oct', byDay['2026-10-07 00:00'] === 100, JSON.stringify(rows));
ok('23:30 Cairo sale is on 6 Oct', byDay['2026-10-06 00:00'] === 100, JSON.stringify(rows));

const month = await one(`select to_char(month at time zone 'Africa/Cairo', 'YYYY-MM-DD') as m, revenue::numeric
                         from public.monthly_sales_summary order by month desc limit 1`);
ok('monthly summary starts on the Cairo 1st', month.m === '2026-10-01' && Number(month.revenue) >= 200, JSON.stringify(month));

finish();
