/**
 * Mã giảm giá (voucher toàn sàn).
 * Dùng chung cho: xem trước ở màn thanh toán (preview) và áp thật khi checkout.
 */
import { query } from '../../db/pool.js';
import { AppError } from '../../utils/AppError.js';

/**
 * Tính số tiền giảm cho 1 voucher đã hợp lệ trên một subtotal.
 * - percent: subtotal * value% (giới hạn bởi max_discount nếu có)
 * - fixed:   value đồng
 * Không bao giờ vượt quá subtotal.
 */
export function computeDiscount(voucher, subtotal) {
  let discount =
    voucher.type === 'percent' ? Math.floor((subtotal * voucher.value) / 100) : voucher.value;
  if (voucher.type === 'percent' && voucher.max_discount != null) {
    discount = Math.min(discount, voucher.max_discount);
  }
  return Math.max(0, Math.min(discount, subtotal));
}

/**
 * Kiểm tra voucher có dùng được với subtotal không.
 * @param {string} code mã người dùng nhập (không phân biệt hoa/thường)
 * @param {number} subtotal tổng tiền hàng (chưa gồm phí ship)
 * @param {import('pg').PoolClient|null} client truyền vào để khóa dòng trong transaction (checkout)
 * @returns {Promise<{ voucher: object, discount: number }>}
 */
export async function validateVoucher(code, subtotal, client = null) {
  const run = client ? (sql, p) => client.query(sql, p) : (sql, p) => query(sql, p);
  const normalized = String(code || '').trim();
  if (!normalized) throw new AppError(400, 'Vui lòng nhập mã giảm giá');

  const res = await run(
    `SELECT * FROM vouchers WHERE UPPER(code) = UPPER($1)${client ? ' FOR UPDATE' : ''}`,
    [normalized]
  );
  const v = res.rows[0];
  if (!v) throw new AppError(404, 'Mã giảm giá không tồn tại');
  if (!v.is_active) throw new AppError(400, 'Mã giảm giá đã ngừng áp dụng');

  const now = new Date();
  if (v.starts_at && new Date(v.starts_at) > now)
    throw new AppError(400, 'Mã giảm giá chưa tới thời gian áp dụng');
  if (v.expires_at && new Date(v.expires_at) < now)
    throw new AppError(400, 'Mã giảm giá đã hết hạn');
  if (v.usage_limit != null && v.used_count >= v.usage_limit)
    throw new AppError(400, 'Mã giảm giá đã hết lượt sử dụng');
  if (subtotal < v.min_order)
    throw new AppError(
      400,
      `Đơn tối thiểu ${Number(v.min_order).toLocaleString('vi-VN')}đ để dùng mã này`
    );

  return { voucher: v, discount: computeDiscount(v, subtotal) };
}

/** Tổng tiền hàng trong giỏ của người dùng (chưa gồm phí ship). */
export async function cartSubtotal(userId, client = null) {
  const run = client ? (sql, p) => client.query(sql, p) : (sql, p) => query(sql, p);
  const res = await run(
    `SELECT COALESCE(SUM(v.price * ci.quantity), 0)::int AS subtotal
     FROM cart_items ci JOIN product_variants v ON v.id = ci.variant_id
     WHERE ci.user_id = $1`,
    [userId]
  );
  return res.rows[0].subtotal;
}
