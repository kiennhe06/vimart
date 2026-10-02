/**
 * Chat giữa người mua và shop.
 * - Mỗi cặp (buyer, shop) có đúng 1 hội thoại.
 * - Lưu tin bằng REST; đẩy real-time bằng WebSocket (xem chat.ws.js).
 */
import { query, withTransaction } from '../../db/pool.js';
import { AppError } from '../../utils/AppError.js';

/** Thông tin 2 phía của 1 hội thoại (buyer_id + shop.owner_id) để kiểm tra quyền + đẩy WS. */
async function getParties(conversationId) {
  const res = await query(
    `SELECT c.id, c.buyer_id, s.owner_id AS seller_id
     FROM conversations c JOIN shops s ON s.id = c.shop_id
     WHERE c.id = $1`,
    [conversationId]
  );
  if (res.rows.length === 0) throw new AppError(404, 'Không tìm thấy hội thoại');
  return res.rows[0];
}

/** Kiểm tra user là 1 trong 2 phía; trả về vai trò 'buyer' | 'seller'. */
function roleOf(parties, userId) {
  if (parties.buyer_id === userId) return 'buyer';
  if (parties.seller_id === userId) return 'seller';
  throw new AppError(403, 'Bạn không thuộc hội thoại này');
}

/** Người mua mở (hoặc tạo) hội thoại với 1 shop. */
export async function getOrCreateConversation(buyerId, shopId) {
  const shop = await query('SELECT id, owner_id FROM shops WHERE id = $1', [shopId]);
  if (shop.rows.length === 0) throw new AppError(404, 'Không tìm thấy shop');
  if (shop.rows[0].owner_id === buyerId)
    throw new AppError(400, 'Không thể tự nhắn tin với shop của mình');

  const existing = await query(
    'SELECT id FROM conversations WHERE buyer_id = $1 AND shop_id = $2',
    [buyerId, shopId]
  );
  let id = existing.rows[0]?.id;
  if (!id) {
    const ins = await query(
      'INSERT INTO conversations (buyer_id, shop_id) VALUES ($1, $2) RETURNING id',
      [buyerId, shopId]
    );
    id = ins.rows[0].id;
  }
  return getConversation(id, buyerId);
}

/** Chuyển 1 dòng hội thoại sang object theo góc nhìn của `userId`. */
function toConversation(row, userId) {
  const isBuyer = row.buyer_id === userId;
  return {
    id: row.id,
    role: isBuyer ? 'buyer' : 'seller',
    // "Phía bên kia" để hiển thị: người mua thấy tên shop, shop thấy tên khách.
    title: isBuyer ? row.shop_name : row.buyer_name,
    avatarUrl: isBuyer ? row.shop_avatar : null,
    shopId: row.shop_id,
    lastMessage: row.last_message,
    lastMessageAt: row.last_message_at,
    unread: isBuyer ? row.buyer_unread : row.seller_unread,
  };
}

const CONV_SELECT = `
  SELECT c.*, s.name AS shop_name, s.avatar_url AS shop_avatar, s.owner_id,
         bu.full_name AS buyer_name
  FROM conversations c
  JOIN shops s ON s.id = c.shop_id
  JOIN users bu ON bu.id = c.buyer_id`;

/** Danh sách hội thoại của user (ở cả vai người mua lẫn chủ shop). */
export async function listConversations(userId) {
  const res = await query(
    `${CONV_SELECT}
     WHERE c.buyer_id = $1 OR s.owner_id = $1
     ORDER BY c.last_message_at DESC NULLS LAST, c.created_at DESC`,
    [userId]
  );
  return res.rows.map((r) => toConversation(r, userId));
}

/** Chi tiết 1 hội thoại (user phải là 1 phía). */
export async function getConversation(conversationId, userId) {
  const res = await query(`${CONV_SELECT} WHERE c.id = $1`, [conversationId]);
  if (res.rows.length === 0) throw new AppError(404, 'Không tìm thấy hội thoại');
  const row = res.rows[0];
  if (row.buyer_id !== userId && row.owner_id !== userId)
    throw new AppError(403, 'Bạn không thuộc hội thoại này');
  return toConversation(row, userId);
}

/** Lấy tin nhắn (cũ -> mới) và đánh dấu đã đọc cho phía đang xem. */
export async function listMessages(conversationId, userId) {
  const parties = await getParties(conversationId);
  const role = roleOf(parties, userId);

  const res = await query(
    'SELECT id, sender_id, body, created_at FROM messages WHERE conversation_id = $1 ORDER BY created_at ASC',
    [conversationId]
  );
  // Reset số chưa đọc của phía đang mở.
  const col = role === 'buyer' ? 'buyer_unread' : 'seller_unread';
  await query(`UPDATE conversations SET ${col} = 0 WHERE id = $1`, [conversationId]);

  return res.rows.map((m) => ({
    id: m.id,
    senderId: m.sender_id,
    body: m.body,
    mine: m.sender_id === userId,
    createdAt: m.created_at,
  }));
}

/**
 * Gửi tin nhắn. Trả về { message, recipientId } để route đẩy WS cho phía kia.
 */
export async function sendMessage(conversationId, senderId, body) {
  const text = String(body || '').trim();
  if (!text) throw new AppError(400, 'Nội dung tin nhắn trống');
  const parties = await getParties(conversationId);
  const role = roleOf(parties, senderId);
  const recipientId = role === 'buyer' ? parties.seller_id : parties.buyer_id;

  const message = await withTransaction(async (client) => {
    const ins = await client.query(
      'INSERT INTO messages (conversation_id, sender_id, body) VALUES ($1,$2,$3) RETURNING id, created_at',
      [conversationId, senderId, text]
    );
    // Cập nhật hội thoại + tăng số chưa đọc của phía NHẬN.
    const recipientCol = role === 'buyer' ? 'seller_unread' : 'buyer_unread';
    await client.query(
      `UPDATE conversations
       SET last_message = $1, last_message_at = now(), ${recipientCol} = ${recipientCol} + 1
       WHERE id = $2`,
      [text.slice(0, 500), conversationId]
    );
    return ins.rows[0];
  });

  return {
    recipientId,
    message: {
      id: message.id,
      conversationId: Number(conversationId),
      senderId,
      body: text,
      createdAt: message.created_at,
    },
  };
}

/** Tổng số tin chưa đọc của user (cho badge). */
export async function unreadTotal(userId) {
  const res = await query(
    `SELECT COALESCE(SUM(
       CASE WHEN c.buyer_id = $1 THEN c.buyer_unread
            WHEN s.owner_id = $1 THEN c.seller_unread ELSE 0 END), 0)::int AS c
     FROM conversations c JOIN shops s ON s.id = c.shop_id
     WHERE c.buyer_id = $1 OR s.owner_id = $1`,
    [userId]
  );
  return res.rows[0].c;
}
