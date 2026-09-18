/** Logic giỏ hàng. Giỏ được gộp theo từng shop khi hiển thị (giống Shopee). */
import { query } from '../../db/pool.js';
import { AppError } from '../../utils/AppError.js';

/**
 * Lấy toàn bộ giỏ hàng của người dùng, gom nhóm theo shop.
 * Trả về: { shops: [{ shopId, shopName, items: [...] }], subtotal, itemCount }
 */
export async function getCart(userId) {
  const result = await query(
    `SELECT ci.id AS cart_item_id, ci.quantity,
            v.id AS variant_id, v.name AS variant_name, v.price, v.stock,
            p.id AS product_id, p.name AS product_name, p.image_url,
            s.id AS shop_id, s.name AS shop_name
     FROM cart_items ci
     JOIN product_variants v ON v.id = ci.variant_id
     JOIN products p ON p.id = v.product_id
     JOIN shops s ON s.id = p.shop_id
     WHERE ci.user_id = $1
     ORDER BY s.id, ci.id`,
    [userId]
  );

  const shopMap = new Map();
  let subtotal = 0;
  let itemCount = 0;

  for (const row of result.rows) {
    const lineTotal = Number(row.price) * row.quantity;
    subtotal += lineTotal;
    itemCount += row.quantity;

    if (!shopMap.has(row.shop_id)) {
      shopMap.set(row.shop_id, { shopId: row.shop_id, shopName: row.shop_name, items: [] });
    }
    shopMap.get(row.shop_id).items.push({
      cartItemId: row.cart_item_id,
      variantId: row.variant_id,
      variantName: row.variant_name,
      productId: row.product_id,
      productName: row.product_name,
      imageUrl: row.image_url,
      price: Number(row.price),
      stock: row.stock,
      quantity: row.quantity,
      lineTotal,
    });
  }

  return { shops: [...shopMap.values()], subtotal, itemCount };
}

/** Thêm sản phẩm vào giỏ. Nếu đã có thì cộng dồn số lượng. */
export async function addToCart(userId, { variantId, quantity }) {
  const variantRes = await query('SELECT id, stock FROM product_variants WHERE id = $1', [variantId]);
  const variant = variantRes.rows[0];
  if (!variant) throw new AppError(404, 'Phân loại sản phẩm không tồn tại');

  const existing = await query('SELECT id, quantity FROM cart_items WHERE user_id = $1 AND variant_id = $2', [userId, variantId]);
  const newQty = (existing.rows[0]?.quantity ?? 0) + quantity;
  if (newQty > variant.stock) throw new AppError(400, `Chỉ còn ${variant.stock} sản phẩm trong kho`);

  if (existing.rows[0]) {
    await query('UPDATE cart_items SET quantity = $1 WHERE id = $2', [newQty, existing.rows[0].id]);
  } else {
    await query('INSERT INTO cart_items (user_id, variant_id, quantity) VALUES ($1, $2, $3)', [userId, variantId, quantity]);
  }
  return getCart(userId);
}

/** Đổi số lượng của 1 dòng trong giỏ. */
export async function updateQuantity(userId, cartItemId, quantity) {
  const res = await query(
    `SELECT ci.id, v.stock FROM cart_items ci
     JOIN product_variants v ON v.id = ci.variant_id
     WHERE ci.id = $1 AND ci.user_id = $2`,
    [cartItemId, userId]
  );
  const item = res.rows[0];
  if (!item) throw new AppError(404, 'Không tìm thấy sản phẩm trong giỏ');
  if (quantity > item.stock) throw new AppError(400, `Chỉ còn ${item.stock} sản phẩm trong kho`);

  await query('UPDATE cart_items SET quantity = $1 WHERE id = $2', [quantity, cartItemId]);
  return getCart(userId);
}

/** Xóa 1 dòng khỏi giỏ. */
export async function removeItem(userId, cartItemId) {
  const res = await query('DELETE FROM cart_items WHERE id = $1 AND user_id = $2 RETURNING id', [cartItemId, userId]);
  if (res.rows.length === 0) throw new AppError(404, 'Không tìm thấy sản phẩm trong giỏ');
  return getCart(userId);
}

/** Xóa sạch giỏ hàng. */
export async function clearCart(userId) {
  await query('DELETE FROM cart_items WHERE user_id = $1', [userId]);
  return getCart(userId);
}
