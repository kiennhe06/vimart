/**
 * Đọc và kiểm tra biến môi trường từ file .env.
 * Nếu thiếu biến bắt buộc thì báo lỗi ngay khi khởi động (fail fast).
 */
import dotenv from 'dotenv';

dotenv.config();

/** Lấy biến môi trường bắt buộc, thiếu thì ném lỗi. */
function required(name, fallback) {
  const value = process.env[name] ?? fallback;
  if (value === undefined || value === '') {
    throw new Error(`Thiếu biến môi trường bắt buộc: ${name} (xem file .env.example)`);
  }
  return value;
}

export const env = {
  port: Number(process.env.PORT || 4000),
  nodeEnv: process.env.NODE_ENV || 'development',
  apiBaseUrl: process.env.API_BASE_URL || 'http://localhost:4000',

  databaseUrl: required('DATABASE_URL', 'postgres://macsos@localhost:5432/vimart'),

  jwtSecret: required('JWT_SECRET', 'dev-secret-change-me'),
  jwtExpiresIn: process.env.JWT_EXPIRES_IN || '7d',

  vnpay: {
    tmnCode: process.env.VNP_TMN_CODE || '',
    hashSecret: process.env.VNP_HASH_SECRET || '',
    url: process.env.VNP_URL || 'https://sandbox.vnpayment.vn/paymentv2/vpcpay.html',
    returnUrl: process.env.VNP_RETURN_URL || 'http://localhost:4000/api/payments/vnpay/return',
  },
};

/** Đã cấu hình VNPay thật hay chưa (có mã sandbox). */
export const isVnpayConfigured = () =>
  Boolean(env.vnpay.tmnCode && env.vnpay.hashSecret && env.vnpay.tmnCode !== 'YOUR_TMN_CODE');
