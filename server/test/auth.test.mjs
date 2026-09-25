import { test } from 'node:test';
import assert from 'node:assert/strict';
import { api, loginAs, bearer } from './helpers/agent.mjs';

test('login đúng trả token + user', async () => {
  const { token, user } = await loginAs('buyer');
  assert.ok(token, 'phải có token');
  assert.equal(user.email, 'buyer@vimart.vn');
});

test('login sai mật khẩu bị từ chối', async () => {
  const res = await api
    .post('/api/auth/login')
    .send({ email: 'buyer@vimart.vn', password: 'sai-roi' });
  assert.ok(res.status >= 400, `mong đợi lỗi, nhận ${res.status}`);
  assert.equal(res.body.success, false);
});

test('GET /auth/me thiếu token trả 401', async () => {
  const res = await api.get('/api/auth/me');
  assert.equal(res.status, 401);
});

test('GET /auth/me với token admin trả đúng vai trò', async () => {
  const { token } = await loginAs('admin');
  const res = await api.get('/api/auth/me').set(...bearer(token));
  assert.equal(res.status, 200);
  assert.equal(res.body.data.role, 'admin');
});
