// tool/db_tests/phase32_backup_restore_test.mjs
//
// 0093: rpc_backup_export / rpc_backup_restore — a backup taken, the shop
// keeps working, the backup is put back: every table is exactly what it was
// when the backup was taken, numbering continues, the data from before the
// restore is kept as a snapshot, and a bad backup changes nothing.
//
//   cd tool/db_tests && npm install && node phase32_backup_restore_test.mjs

import { randomUUID } from 'node:crypto';
import { setup, ADMIN, TECH } from './harness.mjs';

const { ok, finish, as, asSuper, q, one, err } = await setup(process.argv[2]);

const items = arr => JSON.stringify(arr);

// Every covered table's rows, sorted, as text — what "the same" means.
const state = async () => {
  await asSuper();
  const tables = (await q(`select t from private.fn_backup_tables() t`)).map(r => r.t);
  const out = {};
  for (const t of tables) {
    if (t === 'public.audit_logs') continue; // the restore itself is logged
    const rows = await q(`select coalesce(jsonb_agg(to_jsonb(x) order by to_jsonb(x)::text), '[]') as r from ${t} x`);
    out[t] = JSON.stringify(rows[0].r);
  }
  return out;
};
const diff = (a, b) => Object.keys({ ...a, ...b }).filter(k => a[k] !== b[k]);

// ------------------------------------------------------------- the shop runs
console.log('\n== A working shop ==');
await as(ADMIN);
const P = (await one(`insert into public.products (sku, name, cost_price, selling_price) values ('B1', 'مكواة', 40, 100) returning id`)).id;
await q(`select public.rpc_cashbox_deposit(1000, 'رصيد', 'cash')`);
await q(`select public.rpc_create_purchase_invoice(null, 'مورد', null, $1, 0, 0, null, null, null, null, $2)`,
  [items([{ product_id: P, quantity: 20, unit_cost: 40 }]), randomUUID()]);
const S1 = (await one(`select public.rpc_admin_walk_in_sale(null, null, $1, 'cash', 0, $2, null) as id`,
  [items([{ product_id: P, quantity: 5 }]), randomUUID()])).id;
await q(`select public.rpc_admin_edit_sale($1, $2, 0, 'تعديل', null)`, [S1, items([{ product_id: P, quantity: 3 }])]);
const cat = (await one(`select id from public.expense_categories order by name limit 1`)).id;
await q(`select public.rpc_record_expense($1, 75, current_date, 'كهرباء', null)`, [cat]);
await q(`select public.rpc_replay($1, 'rpc_cashbox_deposit', $2)`,
  [randomUUID(), JSON.stringify({ p_amount: 10, p_notes: 'أوفلاين', p_kind: 'cash' })]);

// -------------------------------------------------------------- the backup
console.log('\n== Backup ==');
await as(TECH);
ok('a technician cannot take a backup', /FORBIDDEN/.test(await err(`select public.rpc_backup_export()`) ?? ''));
await as(ADMIN);
const backup = (await one(`select public.rpc_backup_export() as b`)).b;
ok('the backup is marked as one', backup.format === 'mokoji-backup' && backup.schema === '0093');
ok('it holds the sales', backup.tables['public.sales']?.length === 1);
ok('it holds the offline-request record', backup.tables['private.processed_requests']?.length >= 1);
const atBackup = await state();
const stockAtBackup = Number((await one(`select quantity from public.warehouse_stock where product_id = $1`, [P])).quantity);
ok('taking it changed nothing', diff(atBackup, await state()).length === 0);

// --------------------------------------------------------- life goes on
console.log('\n== After the backup ==');
await as(ADMIN);
for (let i = 0; i < 2; i++) {
  await q(`select public.rpc_admin_walk_in_sale(null, null, $1, 'cash', 0, $2, null)`,
    [items([{ product_id: P, quantity: 1 }]), randomUUID()]);
}
await q(`select public.rpc_record_expense($1, 500, current_date, 'إيجار', null)`, [cat]);
const P2 = (await one(`insert into public.products (sku, name, cost_price, selling_price) values ('B2', 'جديد', 1, 2) returning id`)).id;
const afterwards = await state();
ok('the data moved on', diff(atBackup, afterwards).length > 0);

// --------------------------------------------------------------- restore
console.log('\n== Restore ==');
await as(TECH);
ok('a technician cannot restore', /FORBIDDEN/.test(await err(`select public.rpc_backup_restore($1)`, [backup]) ?? ''));
ok('...and nothing changed', diff(afterwards, await state()).length === 0);

await as(ADMIN);
ok('a file that is not a backup is refused',
  /INVALID_BACKUP/.test(await err(`select public.rpc_backup_restore($1)`, [{ hello: 1 }]) ?? ''));
ok('a backup from a newer version is refused',
  /BACKUP_TOO_NEW/.test(await err(`select public.rpc_backup_restore($1)`, [{ ...backup, schema: '9999' }]) ?? ''));

// A damaged backup: one sale line points at a product that isn't there.
const broken = structuredClone(backup);
broken.tables['public.sale_items'][0].product_id = randomUUID();
ok('a damaged backup fails...', (await err(`select public.rpc_backup_restore($1)`, [broken])) !== null);
ok('...and changes nothing at all', diff(afterwards, await state()).length === 0);
await asSuper();
ok('...not even a snapshot', Number((await one(`select count(*)::int as n from private.backup_snapshots`)).n) === 0);

await as(ADMIN);
const res = (await one(`select public.rpc_backup_restore($1) as r`, [backup])).r;
ok('the restore reports what it loaded', res.tables['public.sales'] === 1 && !!res.snapshot_id);
const restored = await state();
const changed = diff(atBackup, restored).filter(t => t !== 'private.backup_snapshots');
ok('every table is exactly as backed up', changed.length === 0, changed.join(', '));
ok('the product added afterwards is gone',
  (await one(`select count(*)::int as n from public.products where id = $1`, [P2])).n === 0);
ok('stock is as backed up',
  Number((await one(`select quantity from public.warehouse_stock where product_id = $1`, [P])).quantity) === stockAtBackup);
ok('the restore is in the audit log',
  (await one(`select count(*)::int as n from public.audit_logs where action = 'BACKUP_RESTORED'`)).n === 1);
ok('no audit rows were re-created by the load',
  (await one(`select count(*)::int as n from public.audit_logs`)).n === backup.tables['public.audit_logs'].length + 1);

// ------------------------------------------------- the shop works after it
console.log('\n== Working after the restore ==');
await as(ADMIN);
const maxNo = Number((await one(`select max(sale_number) as n from public.sales`)).n);
const S2 = (await one(`select public.rpc_admin_walk_in_sale(null, null, $1, 'cash', 0, $2, null) as id`,
  [items([{ product_id: P, quantity: 1 }]), randomUUID()])).id;
ok('the next sale number follows the restored ones',
  Number((await one(`select sale_number from public.sales where id = $1`, [S2])).sale_number) === maxNo + 1);
ok('triggers are back on: the sale took stock',
  Number((await one(`select quantity from public.warehouse_stock where product_id = $1`, [P])).quantity) === stockAtBackup - 1);
ok('...and was audited',
  (await one(`select count(*)::int as n from public.audit_logs where record_id = $1`, [S2])).n >= 1);

// ------------------------------------------------- undoing the restore
console.log('\n== Undo ==');
await asSuper();
const snap = await one(`select data from private.backup_snapshots where id = $1`, [res.snapshot_id]);
ok('the snapshot holds the data from just before the restore',
  snap.data.tables['public.sales'].length === 3);
await as(ADMIN);
await q(`select public.rpc_backup_restore($1)`, [snap.data]);
const undone = await state();
const undoChanged = diff(afterwards, undone).filter(t => t !== 'private.backup_snapshots');
ok('restoring the snapshot brings back what was there', undoChanged.length === 0, undoChanged.join(', '));
await asSuper();
ok('snapshots are kept (2 restores = 2)',
  Number((await one(`select count(*)::int as n from private.backup_snapshots`)).n) === 2);

finish();
