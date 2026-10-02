/** Thông báo cho người dùng (đổi trạng thái đơn, phản hồi đánh giá...). */
import { query } from '../../db/pool.js';

/**
 * Tạo 1 thông báo. Nhận `db` để chạy được cả trong transaction (client) lẫn ngoài (pool).
 * @param {{query: Function}} db client transaction hoặc pool
 */
export async function createNotification(db, { userId, type, title, body = null, orderId = null }) {
  await db.query(
    `INSERT INTO notifications (user_id, type, title, body, order_id)
     VALUES ($1, $2, $3, $4, $5)`,
    [userId, type, title, body, orderId]
  );
}

/** Chuyển 1 dòng DB sang object cho app. */
function toNotification(row) {
  return {
    id: row.id,
    type: row.type,
    title: row.title,
    body: row.body,
    orderId: row.order_id,
    isRead: row.is_read,
    createdAt: row.created_at,
  };
}

/** Danh sách thông báo của người dùng (mới nhất trước). */
export async function listNotifications(userId) {
  const result = await query(
    'SELECT * FROM notifications WHERE user_id = $1 ORDER BY created_at DESC LIMIT 50',
    [userId]
  );
  return result.rows.map(toNotification);
}

/** Số thông báo chưa đọc. */
export async function unreadCount(userId) {
  const result = await query(
    'SELECT COUNT(*)::int AS c FROM notifications WHERE user_id = $1 AND is_read = FALSE',
    [userId]
  );
  return result.rows[0].c;
}

/** Đánh dấu 1 thông báo đã đọc (chỉ của chính người dùng). */
export async function markRead(userId, id) {
  const result = await query(
    'UPDATE notifications SET is_read = TRUE WHERE id = $1 AND user_id = $2 RETURNING id',
    [id, userId]
  );
  return result.rows.length > 0;
}

/** Đánh dấu tất cả đã đọc. */
export async function markAllRead(userId) {
  await query('UPDATE notifications SET is_read = TRUE WHERE user_id = $1 AND is_read = FALSE', [
    userId,
  ]);
}
