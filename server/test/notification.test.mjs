/** Test lịch sử trạng thái đơn + thông báo cho người mua khi admin đổi trạng thái. */
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
  return v.id;
}

test('admin đổi trạng thái đơn: ghi lịch sử + tạo thông báo cho người mua', async () => {
  const buyer = bearer((await loginAs('buyer')).token);
  const admin = bearer((await loginAs('admin')).token);

  // Buyer đặt 1 đơn COD.
  const variantId = await firstVariant('Shop Táo Xanh');
  await api
    .post('/api/cart/items')
    .set(...buyer)
    .send({ variantId, quantity: 1 });
  const addrs = await api.get('/api/users/me/addresses').set(...buyer);
  const checkout = await api
    .post('/api/orders/checkout')
    .set(...buyer)
    .send({ addressId: addrs.body.data[0].id, paymentMethod: 'cod' });
  assert.equal(checkout.status, 201);
  const orderId = checkout.body.data.orders[0].id;

  const before = (await api.get('/api/notifications/unread-count').set(...buyer)).body.data.count;

  // Admin xác nhận đơn.
  const act = await api
    .post(`/api/admin/orders/${orderId}/action`)
    .set(...admin)
    .send({ action: 'confirm' });
  assert.equal(act.status, 200);

  // Lịch sử có mốc 'confirmed' do admin.
  const detail = await api.get(`/api/admin/orders/${orderId}`).set(...admin);
  assert.ok(
    detail.body.data.history.some((h) => h.toStatus === 'confirmed' && h.actorRole === 'admin'),
    'lịch sử phải có confirmed/admin'
  );

  // Buyer nhận thêm thông báo gắn với đơn.
  const after = (await api.get('/api/notifications/unread-count').set(...buyer)).body.data.count;
  assert.ok(after > before, 'buyer phải nhận thêm thông báo');

  const notifs = await api.get('/api/notifications').set(...buyer);
  assert.ok(
    notifs.body.data.some((n) => n.type === 'order_status' && n.orderId === orderId),
    'phải có thông báo order_status cho đúng đơn'
  );
});

test('đánh dấu tất cả đã đọc -> unread về 0', async () => {
  const buyer = bearer((await loginAs('buyer')).token);
  await api.put('/api/notifications/read-all').set(...buyer);
  const res = await api.get('/api/notifications/unread-count').set(...buyer);
  assert.equal(res.body.data.count, 0);
});
