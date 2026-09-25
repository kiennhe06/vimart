/** Logic cho hồ sơ cá nhân và sổ địa chỉ nhận hàng. */
import { query, withTransaction } from '../../db/pool.js';
import { AppError } from '../../utils/AppError.js';

/** Đổi tên cột snake_case của DB sang camelCase cho app. */
function toAddress(row) {
  return {
    id: row.id,
    recipientName: row.recipient_name,
    phone: row.phone,
    line: row.line,
    ward: row.ward,
    district: row.district,
    province: row.province,
    isDefault: row.is_default,
  };
}

/** Cập nhật họ tên / số điện thoại. */
export async function updateProfile(userId, { fullName, phone }) {
  const result = await query(
    `UPDATE users SET full_name = $1, phone = $2 WHERE id = $3
     RETURNING id, email, full_name, phone, role, created_at`,
    [fullName, phone ?? null, userId]
  );
  const u = result.rows[0];
  return { id: u.id, email: u.email, fullName: u.full_name, phone: u.phone, role: u.role };
}

/** Danh sách địa chỉ, địa chỉ mặc định lên đầu. */
export async function listAddresses(userId) {
  const result = await query(
    'SELECT * FROM addresses WHERE user_id = $1 ORDER BY is_default DESC, id DESC',
    [userId]
  );
  return result.rows.map(toAddress);
}

/** Thêm địa chỉ. Nếu đặt làm mặc định thì bỏ mặc định của các địa chỉ khác. */
export async function addAddress(userId, data) {
  return withTransaction(async (client) => {
    if (data.isDefault) {
      await client.query('UPDATE addresses SET is_default = FALSE WHERE user_id = $1', [userId]);
    }
    // Nếu đây là địa chỉ đầu tiên thì tự đặt làm mặc định
    const countRes = await client.query(
      'SELECT COUNT(*)::int AS c FROM addresses WHERE user_id = $1',
      [userId]
    );
    const isFirst = countRes.rows[0].c === 0;

    const result = await client.query(
      `INSERT INTO addresses (user_id, recipient_name, phone, line, ward, district, province, is_default)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8) RETURNING *`,
      [
        userId,
        data.recipientName,
        data.phone,
        data.line,
        data.ward ?? null,
        data.district ?? null,
        data.province ?? null,
        data.isDefault || isFirst,
      ]
    );
    return toAddress(result.rows[0]);
  });
}

/** Sửa địa chỉ (chỉ được sửa địa chỉ của chính mình). */
export async function updateAddress(userId, addressId, data) {
  return withTransaction(async (client) => {
    const owned = await client.query('SELECT id FROM addresses WHERE id = $1 AND user_id = $2', [
      addressId,
      userId,
    ]);
    if (owned.rows.length === 0) throw new AppError(404, 'Không tìm thấy địa chỉ');

    if (data.isDefault) {
      await client.query('UPDATE addresses SET is_default = FALSE WHERE user_id = $1', [userId]);
    }
    const result = await client.query(
      `UPDATE addresses SET recipient_name=$1, phone=$2, line=$3, ward=$4, district=$5, province=$6, is_default=$7
       WHERE id=$8 RETURNING *`,
      [
        data.recipientName,
        data.phone,
        data.line,
        data.ward ?? null,
        data.district ?? null,
        data.province ?? null,
        data.isDefault ?? false,
        addressId,
      ]
    );
    return toAddress(result.rows[0]);
  });
}

/** Xóa địa chỉ. */
export async function deleteAddress(userId, addressId) {
  const result = await query('DELETE FROM addresses WHERE id = $1 AND user_id = $2 RETURNING id', [
    addressId,
    userId,
  ]);
  if (result.rows.length === 0) throw new AppError(404, 'Không tìm thấy địa chỉ');
}
