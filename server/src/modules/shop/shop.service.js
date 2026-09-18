/** Logic cho shop: mở shop, xem shop, cập nhật shop. */
import { query } from '../../db/pool.js';
import { AppError } from '../../utils/AppError.js';

function toShop(row) {
  return {
    id: row.id,
    ownerId: row.owner_id,
    name: row.name,
    description: row.description,
    avatarUrl: row.avatar_url,
    status: row.status,
    createdAt: row.created_at,
  };
}

/** Lấy shop theo owner (người dùng hiện tại). Trả null nếu chưa mở shop. */
export async function getShopByOwner(ownerId) {
  const result = await query('SELECT * FROM shops WHERE owner_id = $1', [ownerId]);
  return result.rows[0] ? toShop(result.rows[0]) : null;
}

/** Mở shop mới. Mỗi người dùng chỉ mở 1 shop (MVP). */
export async function createShop(ownerId, data) {
  const existed = await getShopByOwner(ownerId);
  if (existed) throw new AppError(409, 'Bạn đã có shop rồi');

  const result = await query(
    `INSERT INTO shops (owner_id, name, description, avatar_url)
     VALUES ($1, $2, $3, $4) RETURNING *`,
    [ownerId, data.name, data.description ?? null, data.avatarUrl ?? null]
  );
  return toShop(result.rows[0]);
}

/** Cập nhật thông tin shop của chính mình. */
export async function updateShop(ownerId, data) {
  const shop = await getShopByOwner(ownerId);
  if (!shop) throw new AppError(404, 'Bạn chưa có shop');

  const result = await query(
    `UPDATE shops SET name = $1, description = $2, avatar_url = $3 WHERE owner_id = $4 RETURNING *`,
    [data.name, data.description ?? null, data.avatarUrl ?? null, ownerId]
  );
  return toShop(result.rows[0]);
}

/** Xem trang shop công khai kèm vài sản phẩm và số liệu cơ bản. */
export async function getPublicShop(shopId) {
  const shopRes = await query('SELECT * FROM shops WHERE id = $1', [shopId]);
  const shop = shopRes.rows[0];
  if (!shop) throw new AppError(404, 'Không tìm thấy shop');

  const statsRes = await query(
    `SELECT COUNT(*)::int AS product_count,
            COALESCE(SUM(sold_count), 0)::int AS total_sold
     FROM products WHERE shop_id = $1 AND status = 'active'`,
    [shopId]
  );

  return {
    ...toShop(shop),
    stats: statsRes.rows[0],
  };
}
