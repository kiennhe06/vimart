import { test } from 'node:test';
import assert from 'node:assert/strict';
import { api, loginAs, bearer } from './helpers/agent.mjs';

test('non-admin bị chặn khỏi /admin/stats (403)', async () => {
  const { token } = await loginAs('buyer');
  const res = await api.get('/api/admin/stats').set(...bearer(token));
  assert.equal(res.status, 403);
});

test('admin xem được thống kê', async () => {
  const { token } = await loginAs('admin');
  const res = await api.get('/api/admin/stats').set(...bearer(token));
  assert.equal(res.status, 200);
  const s = res.body.data;
  assert.ok(s.totalUsers >= 4, 'seed có >=4 người dùng');
  assert.ok(s.totalProducts > 0);
  assert.ok(s.totalShops >= 2);
});

test('admin liệt kê người dùng và sản phẩm', async () => {
  const { token } = await loginAs('admin');
  const users = await api.get('/api/admin/users').set(...bearer(token));
  assert.equal(users.status, 200);
  assert.ok(users.body.data.some((u) => u.role === 'admin'));

  const products = await api.get('/api/admin/products').set(...bearer(token));
  assert.equal(products.status, 200);
  assert.ok(products.body.data.length > 0);
});

test('admin tạo rồi xóa sản phẩm', async () => {
  const { token } = await loginAs('admin');
  const shops = await api.get('/api/admin/shops').set(...bearer(token));
  const shopId = shops.body.data[0].id;

  const create = await api
    .post('/api/admin/products')
    .set(...bearer(token))
    .send({
      shopId,
      name: 'Sản phẩm test tự động',
      variants: [{ name: 'Mặc định', price: 12000, stock: 5 }],
    });
  assert.equal(create.status, 201);
  const newId = create.body.data.id;
  assert.ok(newId);

  const del = await api.delete(`/api/admin/products/${newId}`).set(...bearer(token));
  assert.equal(del.status, 200);
});
