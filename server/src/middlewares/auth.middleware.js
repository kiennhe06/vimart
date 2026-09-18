/**
 * Middleware kiểm tra đăng nhập & phân quyền.
 *
 * - authRequired: bắt buộc phải có token hợp lệ, nếu không -> 401.
 * - authOptional: có token thì đọc thông tin user, không có cũng cho qua (dùng cho trang public).
 * - adminOnly:    chỉ cho admin đi tiếp.
 */
import { verifyToken } from '../utils/token.js';
import { AppError } from '../utils/AppError.js';
import { query } from '../db/pool.js';

/** Lấy token từ header "Authorization: Bearer <token>". */
function extractToken(req) {
  const header = req.headers.authorization || '';
  if (header.startsWith('Bearer ')) return header.slice(7);
  return null;
}

/** Gắn thông tin user vào req.user (nếu token hợp lệ). */
async function loadUser(token) {
  const payload = verifyToken(token); // ném lỗi nếu sai/hết hạn
  const result = await query(
    'SELECT id, email, full_name, role, is_active FROM users WHERE id = $1',
    [payload.id]
  );
  const user = result.rows[0];
  if (!user) throw new AppError(401, 'Tài khoản không tồn tại');
  if (!user.is_active) throw new AppError(403, 'Tài khoản đã bị khóa');
  return user;
}

/** Bắt buộc đăng nhập. */
export async function authRequired(req, res, next) {
  try {
    const token = extractToken(req);
    if (!token) throw new AppError(401, 'Bạn cần đăng nhập để tiếp tục');
    req.user = await loadUser(token);
    next();
  } catch (err) {
    if (err.name === 'JsonWebTokenError' || err.name === 'TokenExpiredError') {
      return next(new AppError(401, 'Phiên đăng nhập không hợp lệ hoặc đã hết hạn'));
    }
    next(err);
  }
}

/** Đăng nhập là tùy chọn (trang khách vãng lai xem được). */
export async function authOptional(req, res, next) {
  try {
    const token = extractToken(req);
    if (token) req.user = await loadUser(token);
    next();
  } catch {
    // Token hỏng thì coi như khách vãng lai, vẫn cho xem
    next();
  }
}

/** Chỉ cho admin. Dùng SAU authRequired. */
export function adminOnly(req, res, next) {
  if (!req.user || req.user.role !== 'admin') {
    return next(new AppError(403, 'Chỉ admin mới được phép thao tác này'));
  }
  next();
}
