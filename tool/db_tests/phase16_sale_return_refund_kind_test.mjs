// tool/db_tests/phase16_sale_return_refund_kind_test.mjs
//
// 0063: sale returns let the caller say which till (cash/transfer) the
// refund comes out of, instead of always inferring it from the original
// sale's payment_method. Regression coverage for the reported bug: a
// return recorded successfully but the expected cashbox balance didn't
// move, because the refund silently landed in the other till.
//
//   cd tool/db_tests && npm install && npm test

import { randomUUID } from 'node:crypto';
import { setup, ADMIN } from './harness.mjs';

const { ok, finish, as, asSuper, q, one } = await setup(process.argv[2]);

await as(ADMIN);
const P = (await one(`insert into public.products (sku, name, cost_price, selling_price) values ('RK1', 'مكواة بخار', 50, 200) returning id`)).id;
await q(`select public.rpc_receive_purchase($1, 10, 50, 'seed')`, [P]);
await q(`select public.rpc_cashbox_deposit(1000, 'float', 'cash')`);
await q(`select public.rpc_cashbox_deposit(1000, 'float', 'transfer')`);

const cashboxBalance = async (kind) => {
  await asSuper();
  return Number((await one(
    `select coalesce(sum(ct.amount), 0)::numeric as b
     from public.cash_transactions ct join public.cashboxes cb on cb.id = ct.cashbox_id
     where cb.kind = $1 and cb.is_active`, [kind])).b);
};

const makeSale = async (paymentMethod) => {
  await as(ADMIN);
  const r = await one(
    `select public.rpc_admin_walk_in_sale($1, $2, $3, $4, $5, $6, $7) as id`,
    [null, null, JSON.stringify([{ product_id: P, quantity: 1, unit_price: 200 }]), paymentMethod, 0,
     randomUUID(), null]);
  const item = await one(`select id from public.sale_items where sale_id = $1`, [r.id]);
  return { saleId: r.id, saleItemId: item.id };
};

// ---------------------------------------------------------------- explicit refund kind overrides the sale's own payment_method
console.log('\n== Returning a cash-paid sale explicitly into the transfer till ==');
{
  const transferBefore = await cashboxBalance('transfer');
  const { saleItemId } = await makeSale('cash');
  // The sale itself just credited +200 to the cash till (paid in cash);
  // capture that as the new baseline before returning.
  const cashAfterSale = await cashboxBalance('cash');
  await as(ADMIN);
  await q(`select public.rpc_return_sale_item($1, 1, $2, $3)`, [saleItemId, 'تجربة', 'transfer']);
  ok('cash till untouched when refund_kind=transfer', await cashboxBalance('cash') === cashAfterSale);
  ok('transfer till debited by the refund amount', await cashboxBalance('transfer') === transferBefore - 200);
}

// ---------------------------------------------------------------- omitting it falls back to the old payment_method-derived behaviour
console.log('\n== Returning without a refund_kind still falls back to the sale\'s own payment_method ==');
{
  const cashBefore = await cashboxBalance('cash');
  const { saleItemId } = await makeSale('cash');
  // Sale credits cash +200, then the default-kind return should debit it
  // straight back out, netting to where it started.
  await as(ADMIN);
  await q(`select public.rpc_return_sale_item($1, 1, $2)`, [saleItemId, 'تجربة بدون اختيار']);
  ok('cash till nets back to baseline by default when no refund_kind given', await cashboxBalance('cash') === cashBefore);
}

// ---------------------------------------------------------------- invalid kind rejected
console.log('\n== An invalid refund_kind is rejected, not silently ignored ==');
{
  const { saleItemId } = await makeSale('cash');
  await as(ADMIN);
  let threw = false;
  try {
    await q(`select public.rpc_return_sale_item($1, 1, $2, $3)`, [saleItemId, 'تجربة خطأ', 'bank']);
  } catch (e) {
    threw = /INVALID_REFUND_KIND/.test(e.message);
  }
  ok('INVALID_REFUND_KIND raised for an unknown kind', threw);
}

// ---------------------------------------------------------------- whole-invoice return also takes the explicit kind
console.log('\n== Whole-invoice return also honours an explicit refund_kind ==');
{
  const transferBefore = await cashboxBalance('transfer');
  const { saleId } = await makeSale('cash');
  await as(ADMIN);
  await q(`select public.rpc_admin_return_sale($1, $2, $3)`, [saleId, 'تجربة فاتورة كاملة', 'transfer']);
  ok('whole-sale return moved the transfer till, not cash', await cashboxBalance('transfer') === transferBefore - 200);
}

finish();
