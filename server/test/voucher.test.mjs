/** Test mã giảm giá (voucher): tạo, áp vào giỏ, và áp khi checkout. */
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { api, loginAs, bearer } from './helpers/agent.mjs';

/** Lấy 1 variant còn hàng (giá + id) từ shop cho trước. */
async function firstVariant(shopName) {
  const list = await api.get('/api/products');
  const card =
    list.body.data.items.find((c) => c.shopName === shopName) ?? list.body.data.items[0];
  const detail = await api.get(`/api/products/${card.id}`);
  const p = detail.body.data;
  const v = p.variants.find((x) => x.stock > 0) ?? p.variants[0];
  return { price: v.price, variantId: v.id };
}

const uniqueCode = (prefix) => `${prefix}${Date.now().toString().slice(-6)}`;

test('voucher percent: apply đúng mức giảm, checkout áp giảm + tăng used_count', async (t) => {
  const admin = bearer((await loginAs('admin')).token);
  const buyer = bearer((await loginAs('buyer')).token);

  const code = uniqueCode('PCT');
  const create = await api
    .post('/api/admin/vouchers')
    .set(...admin)
    .send({ code, type: 'percent', value: 10, maxDiscount: 50000, minOrder: 0, usageLimit: 2 });
  assert.equal(create.status, 201);

  const v = await firstVariant('Shop Táo Xanh');
  await api
    .post('/api/cart/items')
    .set(...buyer)
    .send({ variantId: v.variantId, quantity: 1 });

  const expected = Math.min(Math.floor(v.price * 0.1), 50000);

  await t.test('apply trả đúng discount (không phân biệt hoa/thường)', async () => {
    const res = await api
      .post('/api/vouchers/apply')
      .set(...buyer)
      .send({ code: code.toLowerCase() });
    assert.equal(res.status, 200);
    assert.equal(res.body.data.discount, expected);
  });

  await t.test('checkout áp giảm và tăng used_count', async () => {
    const addrs = await api.get('/api/users/me/addresses').set(...buyer);
    const res = await api
      .post('/api/orders/checkout')
      .set(...buyer)
      .send({ addressId: addrs.body.data[0].id, paymentMethod: 'cod', voucherCode: code });
    assert.equal(res.status, 201);
    assert.equal(res.body.data.discount, expected);
    assert.equal(res.body.data.voucherCode, code);

    const list = await api.get('/api/admin/vouchers').set(...admin);
    assert.equal(list.body.data.find((x) => x.code === code).usedCount, 1);
  });
});

test('voucher: chặn đơn dưới mức tối thiểu (400)', async () => {
  const admin = bearer((await loginAs('admin')).token);
  const buyer = bearer((await loginAs('buyer')).token);

  const code = uniqueCode('MIN');
  await api
    .post('/api/admin/vouchers')
    .set(...admin)
    .send({ code, type: 'fixed', value: 50000, minOrder: 999999999 });

  const v = await firstVariant('Shop Táo Xanh');
  await api
    .post('/api/cart/items')
    .set(...buyer)
    .send({ variantId: v.variantId, quantity: 1 });

  const res = await api
    .post('/api/vouchers/apply')
    .set(...buyer)
    .send({ code });
  assert.equal(res.status, 400);
});

test('voucher: mã không tồn tại trả 404', async () => {
  const buyer = bearer((await loginAs('buyer')).token);
  const v = await firstVariant('Shop Táo Xanh');
  await api
    .post('/api/cart/items')
    .set(...buyer)
    .send({ variantId: v.variantId, quantity: 1 });
  const res = await api
    .post('/api/vouchers/apply')
    .set(...buyer)
    .send({ code: 'KHONGTONTAI' });
  assert.equal(res.status, 404);
});
