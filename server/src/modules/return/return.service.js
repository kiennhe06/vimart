/** Yêu cầu trả hàng / hoàn tiền. */
import { query, withTransaction } from '../../db/pool.js';
import { AppError } from '../../utils/AppError.js';
import { restoreStock } from '../order/order.service.js';
import { createNotification } from '../notification/notification.service.js';

/** Nhãn lý do (tiếng Việt) cho thông báo. */
const REASON_LABEL = {
  defective: 'Hàng lỗi/hỏng',
  wrong_item: 'Giao sai sản phẩm',
  not_as_described: 'Không giống mô tả',
  other: 'Lý do khác',
};

function toReturn(row) {
  return {
    id: row.id,
    orderId: row.order_id,
    reason: row.reason,
    note: row.note,
    status: row.status,
    adminNote: row.admin_note,
    createdAt: row.created_at,
    resolvedAt: row.resolved_at,
  };
}

/** Yêu cầu trả hàng cho 1 đơn ĐÃ HOÀN THÀNH (chỉ người mua của đơn). */
export async function requestReturn(buyerId, orderId, reason, note) {
  const orderRes = await query('SELECT id, buyer_id, status FROM orders WHERE id = $1', [orderId]);
  const order = orderRes.rows[0];
  if (!order) throw new AppError(404, 'Không tìm thấy đơn hàng');
  if (order.buyer_id !== buyerId) throw new AppError(403, 'Đây không phải đơn của bạn');
  if (order.status !== 'completed')
    throw new AppError(400, 'Chỉ yêu cầu trả hàng với đơn đã hoàn thành');

  const existing = await query('SELECT id FROM return_requests WHERE order_id = $1', [orderId]);
  if (existing.rows.length > 0) throw new AppError(409, 'Đơn này đã có yêu cầu trả hàng');

  const ins = await query(
    `INSERT INTO return_requests (order_id, buyer_id, reason, note)
     VALUES ($1, $2, $3, $4) RETURNING *`,
    [orderId, buyerId, reason, note ?? null]
  );
  return toReturn(ins.rows[0]);
}

/** Yêu cầu trả hàng của 1 đơn (nếu có) — để hiển thị ở chi tiết đơn. */
export async function getReturnForOrder(orderId) {
  const res = await query('SELECT * FROM return_requests WHERE order_id = $1', [orderId]);
  return res.rows[0] ? toReturn(res.rows[0]) : null;
}

/** Danh sách yêu cầu trả hàng (admin). */
export async function listReturns() {
  const res = await query(
    `SELECT r.*, o.code AS order_code, o.total, u.full_name AS buyer_name, s.name AS shop_name
     FROM return_requests r
     JOIN orders o ON o.id = r.order_id
     JOIN users u ON u.id = r.buyer_id
     JOIN shops s ON s.id = o.shop_id
     ORDER BY r.created_at DESC`
  );
  return res.rows.map((r) => ({
    ...toReturn(r),
    orderCode: r.order_code,
    total: Number(r.total),
    buyerName: r.buyer_name,
    shopName: r.shop_name,
  }));
}

/** Admin duyệt/từ chối. approve -> hoàn kho + báo khách; reject -> báo khách. */
export async function resolveReturn(returnId, action, adminNote) {
  return withTransaction(async (client) => {
    const res = await client.query(
      'SELECT * FROM return_requests WHERE id = $1 FOR UPDATE',
      [returnId]
    );
    const r = res.rows[0];
    if (!r) throw new AppError(404, 'Không tìm thấy yêu cầu');
    if (r.status !== 'requested') throw new AppError(400, 'Yêu cầu đã được xử lý');

    const newStatus = action === 'approve' ? 'approved' : 'rejected';
    if (action === 'approve') {
      await restoreStock(client, r.order_id); // hoàn lại tồn kho
    }
    await client.query(
      'UPDATE return_requests SET status = $1, admin_note = $2, resolved_at = now() WHERE id = $3',
      [newStatus, adminNote ?? null, returnId]
    );

    const codeRes = await client.query('SELECT code FROM orders WHERE id = $1', [r.order_id]);
    const code = codeRes.rows[0]?.code ?? '';
    await createNotification(client, {
      userId: r.buyer_id,
      type: 'order_status',
      title:
        action === 'approve' ? 'Yêu cầu trả hàng được chấp nhận' : 'Yêu cầu trả hàng bị từ chối',
      body:
        action === 'approve'
          ? `Đơn ${code} (${REASON_LABEL[r.reason] || r.reason}) đã được chấp nhận hoàn tiền.`
          : `Đơn ${code}: yêu cầu trả hàng bị từ chối.${adminNote ? ' Lý do: ' + adminNote : ''}`,
      orderId: r.order_id,
    });

    return { id: returnId, status: newStatus };
  });
}
