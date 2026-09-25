/**
 * Tiện ích dùng chung cho test: 1 supertest agent chạy trên createApp()
 * và hàm loginAs() lấy token cho các tài khoản seed sẵn (mật khẩu 123456).
 */
import supertest from 'supertest';
import { createApp } from '../../src/app.js';

export const app = createApp();
export const api = supertest(app);

const ACCOUNTS = {
  admin: 'admin@vimart.vn',
  seller1: 'seller1@vimart.vn',
  seller2: 'seller2@vimart.vn',
  buyer: 'buyer@vimart.vn',
};

/** Đăng nhập, trả { token, user }. `role` là 'admin'|'seller1'|'seller2'|'buyer' hoặc email. */
export async function loginAs(role) {
  const email = ACCOUNTS[role] ?? role;
  const res = await api.post('/api/auth/login').send({ email, password: '123456' });
  if (res.status !== 200) {
    throw new Error(`login ${email} thất bại: ${res.status} ${JSON.stringify(res.body)}`);
  }
  return { token: res.body.data.token, user: res.body.data.user };
}

/** Header Authorization tiện dụng. */
export const bearer = (token) => ['Authorization', `Bearer ${token}`];
