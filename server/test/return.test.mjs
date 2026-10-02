/** Test trả hàng/hoàn tiền: tạo đơn hoàn thành -> yêu cầu -> admin duyệt. */
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { api, loginAs, bearer } from './helpers/agent.mjs';

async function firstVariant(shopName) {
  const list = await api.get('/api/products');
  const card =
    list.body.data.items.find((c) => c.shopName === shopName) ?? list.body.data.items[0];
  const detail = await api.get(`/api/products/${card.id}`);
  const p = detail.body.data;
  const v = p.variants.find((x) => x.stock > 0) ?? p.variants[0];
  return { shopId: card.shopId, variantId: v.id };
}

/** Đưa 1 đơn tới trạng thái completed (buyer mua ở Shop Táo Xanh = seller1). */
async function completedOrder(buyer, seller) {
  const { variantId } = await firstVariant('Shop Táo Xanh');
  await api.post('/api/cart/items').set(...buyer).send({ variantId, quantity: 1 });
  const addrs = await api.get('/api/users/me/addresses').set(...buyer);
  const checkout = await api
    .post('/api/orders/checkout')
    .set(...buyer)
    .send({ addressId: addrs.body.data[0].id, paymentMethod: 'cod' });
  const orderId = checkout.body.data.orders[0].id;
  await api.post(`/api/orders/${orderId}/confirm`).set(...seller);
  await api.post(`/api/orders/${orderId}/ship`).set(...seller);
  await api.post(`/api/orders/${orderId}/received`).set(...buyer);
  return orderId;
}

test('return: yêu cầu trên đơn hoàn thành -> admin duyệt -> báo khách', async (t) => {
  const buyer = bearer((await loginAs('buyer')).token);
  const seller = bearer((await loginAs('seller1')).token);
  const admin = bearer((await loginAs('admin')).token);
  const orderId = await completedOrder(buyer, seller);

  await t.test('buyer gửi yêu cầu, lần 2 bị 409', async () => {
    const r1 = await api
      .post(`/api/orders/${orderId}/return`)
      .set(...buyer)
      .send({ reason: 'defective', note: 'Hàng lỗi' });
    assert.equal(r1.status, 201);
    assert.equal(r1.body.data.status, 'requested');

    const r2 = await api
      .post(`/api/orders/${orderId}/return`)
      .set(...buyer)
      .send({ reason: 'other' });
    assert.equal(r2.status, 409);
  });

  await t.test('đơn detail có returnRequest', async () => {
    const d = await api.get(`/api/orders/${orderId}`).set(...buyer);
    assert.equal(d.body.data.returnRequest.status, 'requested');
  });

  await t.test('admin duyệt -> approved + khách nhận thông báo', async () => {
    const list = await api.get('/api/admin/returns').set(...admin);
    const req = list.body.data.find((r) => r.orderId === orderId);
    assert.ok(req);

    const before = (await api.get('/api/notifications/unread-count').set(...buyer)).body.data.count;
    const res = await api
      .post(`/api/admin/returns/${req.id}/resolve`)
      .set(...admin)
      .send({ action: 'approve', adminNote: 'OK hoàn tiền' });
    assert.equal(res.status, 200);
    assert.equal(res.body.data.status, 'approved');

    const after = (await api.get('/api/notifications/unread-count').set(...buyer)).body.data.count;
    assert.ok(after > before, 'khách nhận thông báo');
  });
});

test('return: không yêu cầu được với đơn chưa hoàn thành (400)', async () => {
  const buyer = bearer((await loginAs('buyer')).token);
  const { variantId } = await firstVariant('Shop Táo Xanh');
  await api.post('/api/cart/items').set(...buyer).send({ variantId, quantity: 1 });
  const addrs = await api.get('/api/users/me/addresses').set(...buyer);
  const checkout = await api
    .post('/api/orders/checkout')
    .set(...buyer)
    .send({ addressId: addrs.body.data[0].id, paymentMethod: 'cod' });
  const orderId = checkout.body.data.orders[0].id; // đang 'pending'
  const res = await api
    .post(`/api/orders/${orderId}/return`)
    .set(...buyer)
    .send({ reason: 'other' });
  assert.equal(res.status, 400);
});
