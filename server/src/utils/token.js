/**
 * Tạo và kiểm tra "vé đăng nhập" (JWT).
 * Khi đăng nhập thành công, server tạo token gửi cho app.
 * Mỗi request sau đó app gửi kèm token này để chứng minh danh tính.
 */
import jwt from 'jsonwebtoken';
import { env } from '../config/env.js';

/**
 * Tạo token chứa thông tin cơ bản của người dùng.
 * @param {{ id: number, role: string }} user
 * @returns {string} JWT
 */
export function signToken(user) {
  return jwt.sign({ id: user.id, role: user.role }, env.jwtSecret, {
    expiresIn: env.jwtExpiresIn,
  });
}

/**
 * Giải mã và kiểm tra token. Trả về payload nếu hợp lệ, ném lỗi nếu sai/hết hạn.
 * @param {string} token
 * @returns {{ id: number, role: string, iat: number, exp: number }}
 */
export function verifyToken(token) {
  return jwt.verify(token, env.jwtSecret);
}
