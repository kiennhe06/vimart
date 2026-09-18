/**
 * Middleware bắt mọi lỗi trong app và trả về response chuẩn.
 * Đặt CUỐI CÙNG trong app.js (sau tất cả routes).
 */
import { ZodError } from 'zod';
import { AppError } from '../utils/AppError.js';
import { fail } from '../utils/response.js';
import { env } from '../config/env.js';

/** Route không tồn tại -> 404. */
export function notFound(req, res) {
  return fail(res, 404, `Không tìm thấy đường dẫn: ${req.method} ${req.originalUrl}`);
}

/* eslint-disable no-unused-vars */
export function errorHandler(err, req, res, next) {
  // 1) Lỗi validate dữ liệu từ Zod -> gộp thành 1 câu dễ đọc
  if (err instanceof ZodError) {
    const message = err.issues.map((i) => `${i.path.join('.')}: ${i.message}`).join('; ');
    return fail(res, 400, message || 'Dữ liệu không hợp lệ');
  }

  // 2) Lỗi nghiệp vụ đã lường trước (AppError)
  if (err instanceof AppError) {
    return fail(res, err.statusCode, err.message);
  }

  // 3) Lỗi trùng dữ liệu từ PostgreSQL (vd: email đã tồn tại)
  if (err.code === '23505') {
    return fail(res, 409, 'Dữ liệu đã tồn tại (trùng lặp)');
  }

  // 4) Lỗi không lường trước -> log ra để dev xem, trả 500
  console.error('❌ Unexpected error:', err);
  const message =
    env.nodeEnv === 'development' ? err.message : 'Có lỗi xảy ra ở máy chủ, vui lòng thử lại';
  return fail(res, 500, message);
}
