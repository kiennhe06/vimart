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

test('lọc theo từ khóa (keyword)', async () => {
  const res = await api.get('/api/products?keyword=jean');
  assert.equal(res.status, 200);
  const items = res.body.data.items;
  assert.ok(items.length > 0, 'seed có sản phẩm "Quần jeans nam basic"');
  assert.ok(items.every((p) => p.name.toLowerCase().includes('jean')));
});

test('sắp xếp price_asc trả giá tăng dần', async () => {
  const res = await api.get('/api/products?sort=price_asc');
  const prices = res.body.data.items.map((p) => p.minPrice);
  const sorted = [...prices].sort((a, b) => a - b);
  assert.deepEqual(prices, sorted, 'minPrice phải không giảm');
});

test('lọc theo minPrice chỉ trả sản phẩm đủ giá', async () => {
  const res = await api.get('/api/products?minPrice=200000');
  const items = res.body.data.items;
  assert.ok(items.length > 0);
  assert.ok(items.every((p) => p.minPrice >= 200000));
});

test('lọc theo khoảng giá (minPrice + maxPrice)', async () => {
  const res = await api.get('/api/products?minPrice=100000&maxPrice=200000');
  assert.equal(res.status, 200);
  assert.ok(res.body.data.items.every((p) => p.minPrice >= 100000 && p.minPrice <= 200000));
});
