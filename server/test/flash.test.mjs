/** Test flash sale: tạo đợt -> giá sale hiện ở sản phẩm/giỏ -> checkout áp giá + trừ SL. */
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { api, loginAs, bearer } from './helpers/agent.mjs';

async function aProduct() {
  const list = await api.get('/api/products');
  const card = list.body.data.items[0];
  const detail = await api.get(`/api/products/${card.id}`);
  const p = detail.body.data;
  const v = p.variants.find((x) => x.stock > 1) ?? p.variants[0];
  return { productId: p.id, variantId: v.id, price: v.price };
}

const iso = (msFromNow) => new Date(Date.now() + msFromNow).toISOString();

test('flash sale: tạo đợt, hiện giá sale, checkout áp giá + trừ số lượng', async (t) => {
  const admin = bearer((await loginAs('admin')).token);
  const buyer = bearer((await loginAs('buyer')).token);
  const prod = await aProduct();
  const expectedSale = Math.floor((prod.price * 75) / 100); // giảm 25%

  await t.test('admin tạo đợt (giảm 25%, limit 10)', async () => {
    const res = await api
      .post('/api/admin/flash-sales')
      .set(...admin)
      .send({
        name: 'Flash test',
        startsAt: iso(-60000),
        endsAt: iso(2 * 3600 * 1000),
        items: [{ productId: prod.productId, discountPercent: 25, qtyLimit: 10 }],
      });
    assert.equal(res.status, 201);
  });

  await t.test('sản phẩm có flashSale với salePrice đúng', async () => {
    const d = await api.get(`/api/products/${prod.productId}`);
    assert.ok(d.body.data.flashSale, 'phải có flashSale');
    assert.equal(d.body.data.flashSale.salePrice, Math.floor((d.body.data.variants[0].price * 75) / 100));
  });

  await t.test('giỏ hàng hiển thị giá sale', async () => {
    await api.delete('/api/cart').set(...buyer);
    await api.post('/api/cart/items').set(...buyer).send({ variantId: prod.variantId, quantity: 2 });
    const cart = await api.get('/api/cart').set(...buyer);
    const item = cart.body.data.shops[0].items[0];
    assert.equal(item.price, expectedSale);
    assert.ok(item.flashSale, 'item phải có cờ flashSale');
  });

  await t.test('checkout áp giá sale + trừ sold', async () => {
    const addrs = await api.get('/api/users/me/addresses').set(...buyer);
    const res = await api
      .post('/api/orders/checkout')
      .set(...buyer)
      .send({ addressId: addrs.body.data[0].id, paymentMethod: 'cod' });
    assert.equal(res.status, 201);
    // tổng = 2*salePrice + 30000 ship
    assert.equal(res.body.data.totalAmount, expectedSale * 2 + 30000);

    const active = await api.get('/api/flash-sales/active');
    const item = active.body.data[0].items.find((i) => i.productId === prod.productId);
    assert.equal(item.sold, 2, 'đã bán 2 trong flash');
  });
});

test('flash sale: kết thúc trước bắt đầu -> 400', async () => {
  const admin = bearer((await loginAs('admin')).token);
  const prod = await aProduct();
  const res = await api
    .post('/api/admin/flash-sales')
    .set(...admin)
    .send({
      name: 'Sai thời gian',
      startsAt: iso(3600 * 1000),
      endsAt: iso(-60000),
      items: [{ productId: prod.productId, discountPercent: 10 }],
    });
  assert.equal(res.status, 400);
});
