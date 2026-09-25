import { test } from 'node:test';
import assert from 'node:assert/strict';
import { api } from './helpers/agent.mjs';

test('GET /categories trả danh mục (public)', async () => {
  const res = await api.get('/api/categories');
  assert.equal(res.status, 200);
  assert.ok(Array.isArray(res.body.data));
  assert.ok(res.body.data.length >= 6, 'seed có ít nhất 6 danh mục');
});

test('GET /products trả danh sách (có phân trang)', async () => {
  const res = await api.get('/api/products');
  assert.equal(res.status, 200);
  const { items, pagination } = res.body.data;
  assert.ok(Array.isArray(items));
  assert.ok(items.length > 0);
  assert.ok('id' in items[0]);
  assert.ok(pagination.total > 0);
});

test('GET /products/:id trả chi tiết + phân loại', async () => {
  const list = await api.get('/api/products');
  const first = list.body.data.items[0];
  const res = await api.get(`/api/products/${first.id}`);
  assert.equal(res.status, 200);
  const p = res.body.data;
  assert.equal(p.id, first.id);
  assert.ok(Array.isArray(p.variants) && p.variants.length > 0);
  assert.ok('id' in p.variants[0] && 'price' in p.variants[0]);
  assert.ok(p.shop && p.shop.id);
});

test('GET /products/:id không tồn tại trả 404', async () => {
  const res = await api.get('/api/products/99999999');
  assert.equal(res.status, 404);
});
