/**
 * Logic nghiệp vụ cho đăng ký / đăng nhập.
 * - Mật khẩu luôn được mã hóa (hash) bằng bcrypt trước khi lưu.
 * - Không bao giờ trả password_hash ra ngoài.
 */
import bcrypt from 'bcryptjs';
import { query } from '../../db/pool.js';
import { AppError } from '../../utils/AppError.js';
import { signToken } from '../../utils/token.js';

/** Bỏ trường nhạy cảm, chuẩn hóa dữ liệu user gửi về client. */
function toPublicUser(row) {
  return {
    id: row.id,
    email: row.email,
    fullName: row.full_name,
    phone: row.phone,
    role: row.role,
    createdAt: row.created_at,
  };
}

/** Đăng ký tài khoản mới. */
export async function register({ email, password, fullName, phone }) {
  const existed = await query('SELECT id FROM users WHERE email = $1', [email]);
  if (existed.rows.length > 0) {
    throw new AppError(409, 'Email này đã được đăng ký');
  }

  const passwordHash = await bcrypt.hash(password, 10);
  const result = await query(
    `INSERT INTO users (email, password_hash, full_name, phone)
     VALUES ($1, $2, $3, $4)
     RETURNING id, email, full_name, phone, role, created_at`,
    [email, passwordHash, fullName, phone ?? null]
  );

  const user = result.rows[0];
  const token = signToken(user);
  return { user: toPublicUser(user), token };
}

/** Đăng nhập, trả về token nếu đúng. */
export async function login({ email, password }) {
  const result = await query('SELECT * FROM users WHERE email = $1', [email]);
  const user = result.rows[0];
  if (!user) throw new AppError(401, 'Email hoặc mật khẩu không đúng');
  if (!user.is_active) throw new AppError(403, 'Tài khoản đã bị khóa');

  const match = await bcrypt.compare(password, user.password_hash);
  if (!match) throw new AppError(401, 'Email hoặc mật khẩu không đúng');

  const token = signToken(user);
  return { user: toPublicUser(user), token };
}

/** Lấy thông tin người dùng hiện tại kèm shop (nếu có). */
export async function getMe(userId) {
  const result = await query(
    'SELECT id, email, full_name, phone, role, created_at FROM users WHERE id = $1',
    [userId]
  );
  const user = result.rows[0];
  if (!user) throw new AppError(404, 'Không tìm thấy người dùng');

  const shopResult = await query('SELECT id, name, status FROM shops WHERE owner_id = $1', [userId]);
  return {
    ...toPublicUser(user),
    shop: shopResult.rows[0] ?? null, // null nghĩa là chưa mở shop
  };
}

/** Đổi mật khẩu. */
export async function changePassword(userId, { oldPassword, newPassword }) {
  const result = await query('SELECT password_hash FROM users WHERE id = $1', [userId]);
  const user = result.rows[0];
  if (!user) throw new AppError(404, 'Không tìm thấy người dùng');

  const match = await bcrypt.compare(oldPassword, user.password_hash);
  if (!match) throw new AppError(400, 'Mật khẩu cũ không đúng');

  const newHash = await bcrypt.hash(newPassword, 10);
  await query('UPDATE users SET password_hash = $1 WHERE id = $2', [newHash, userId]);
}
