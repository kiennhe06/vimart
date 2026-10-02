/**
 * Flash sale: deal theo khung giờ, giảm % cho sản phẩm được chọn.
 * - Admin tạo đợt sale (khoảng thời gian) + danh sách sản phẩm (mỗi sản phẩm 1 mức %).
 * - Khi đang trong khung giờ: giá sale được áp ở GIỎ HÀNG và CHECKOUT (có giới hạn số lượng).
 */
import { query, withTransaction } from '../../db/pool.js';
import { AppError } from '../../utils/AppError.js';

/** Giá sau giảm (làm tròn xuống). */
export function salePrice(price, percent) {
  return Math.floor((Number(price) * (100 - percent)) / 100);
}

/**
 * Map productId -> { itemId, discountPercent, qtyLimit, sold, remaining, endsAt }
 * cho các sản phẩm đang trong flash sale còn hiệu lực. Nếu 1 sản phẩm thuộc nhiều
 * đợt, lấy mức giảm cao nhất.
 */
export async function getActiveFlashMap(client = null) {
  const run = client ? (sql, p) => client.query(sql, p) : (sql, p) => query(sql, p);
  const res = await run(
    `SELECT fi.id, fi.product_id, fi.discount_percent, fi.qty_limit, fi.sold, fs.ends_at
     FROM flash_sale_items fi
     JOIN flash_sales fs ON fs.id = fi.flash_sale_id
     WHERE fs.is_active = TRUE AND fs.starts_at <= now() AND fs.ends_at > now()
       AND (fi.qty_limit IS NULL OR fi.sold < fi.qty_limit)`
  );
  const map = new Map();
  for (const r of res.rows) {
    const prev = map.get(r.product_id);
    if (!prev || r.discount_percent > prev.discountPercent) {
      map.set(r.product_id, {
        itemId: r.id,
        discountPercent: r.discount_percent,
        qtyLimit: r.qty_limit,
        sold: r.sold,
        remaining: r.qty_limit == null ? null : r.qty_limit - r.sold,
        endsAt: r.ends_at,
      });
    }
  }
  return map;
}

/** Các đợt flash sale đang chạy + sản phẩm (cho trang chủ). */
export async function listActive() {
  const sales = await query(
    `SELECT id, name, starts_at, ends_at FROM flash_sales
     WHERE is_active = TRUE AND starts_at <= now() AND ends_at > now()
     ORDER BY ends_at ASC`
  );
  const result = [];
  for (const s of sales.rows) {
    const items = await query(
      `SELECT fi.product_id, fi.discount_percent, fi.qty_limit, fi.sold,
              p.name, p.image_url, v.min_price
       FROM flash_sale_items fi
       JOIN products p ON p.id = fi.product_id
       LEFT JOIN (SELECT product_id, MIN(price) min_price FROM product_variants GROUP BY product_id) v
              ON v.product_id = fi.product_id
       WHERE fi.flash_sale_id = $1 AND (fi.qty_limit IS NULL OR fi.sold < fi.qty_limit)
       ORDER BY fi.discount_percent DESC`,
      [s.id]
    );
    if (items.rows.length === 0) continue;
    result.push({
      id: s.id,
      name: s.name,
      startsAt: s.starts_at,
      endsAt: s.ends_at,
      items: items.rows.map((i) => ({
        productId: i.product_id,
        name: i.name,
        imageUrl: i.image_url,
        discountPercent: i.discount_percent,
        price: Number(i.min_price || 0),
        salePrice: salePrice(i.min_price || 0, i.discount_percent),
        qtyLimit: i.qty_limit,
        sold: i.sold,
      })),
    });
  }
  return result;
}

// ---------- Admin ----------

/** Danh sách tất cả đợt flash sale (admin). */
export async function listAll() {
  const res = await query(
    `SELECT fs.*, COUNT(fi.id)::int AS item_count
     FROM flash_sales fs LEFT JOIN flash_sale_items fi ON fi.flash_sale_id = fs.id
     GROUP BY fs.id ORDER BY fs.created_at DESC`
  );
  const now = Date.now();
  return res.rows.map((s) => {
    const starts = new Date(s.starts_at).getTime();
    const ends = new Date(s.ends_at).getTime();
    const state = !s.is_active
      ? 'off'
      : now < starts
        ? 'scheduled'
        : now >= ends
          ? 'ended'
          : 'live';
    return {
      id: s.id,
      name: s.name,
      startsAt: s.starts_at,
      endsAt: s.ends_at,
      isActive: s.is_active,
      itemCount: s.item_count,
      state,
    };
  });
}

/** Tạo đợt flash sale kèm danh sách sản phẩm. */
export async function create({ name, startsAt, endsAt, items }) {
  if (new Date(endsAt) <= new Date(startsAt))
    throw new AppError(400, 'Thời gian kết thúc phải sau thời gian bắt đầu');
  if (!items || items.length === 0) throw new AppError(400, 'Cần ít nhất 1 sản phẩm');

  return withTransaction(async (client) => {
    const fs = await client.query(
      'INSERT INTO flash_sales (name, starts_at, ends_at) VALUES ($1,$2,$3) RETURNING id',
      [name, startsAt, endsAt]
    );
    const id = fs.rows[0].id;
    for (const it of items) {
      await client.query(
        `INSERT INTO flash_sale_items (flash_sale_id, product_id, discount_percent, qty_limit)
         VALUES ($1,$2,$3,$4)`,
        [id, it.productId, it.discountPercent, it.qtyLimit ?? null]
      );
    }
    return { id };
  });
}

export async function setActive(id, isActive) {
  const res = await query('UPDATE flash_sales SET is_active = $1 WHERE id = $2 RETURNING id', [
    Boolean(isActive),
    id,
  ]);
  if (res.rows.length === 0) throw new AppError(404, 'Không tìm thấy đợt flash sale');
  return { id, isActive: Boolean(isActive) };
}

export async function remove(id) {
  const res = await query('DELETE FROM flash_sales WHERE id = $1 RETURNING id', [id]);
  if (res.rows.length === 0) throw new AppError(404, 'Không tìm thấy đợt flash sale');
  return { message: 'Đã xóa đợt flash sale' };
}
