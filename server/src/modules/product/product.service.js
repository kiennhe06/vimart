/**
 * Logic cho sản phẩm.
 * Quy ước quan trọng: GIÁ và TỒN KHO luôn nằm ở bảng product_variants.
 * Mỗi sản phẩm có ít nhất 1 phân loại (variant). Giá hiển thị = giá thấp nhất trong các phân loại.
 */
import { query, withTransaction } from '../../db/pool.js';
import { AppError } from '../../utils/AppError.js';

/** Gọn 1 dòng sản phẩm (dạng danh sách) thành object cho app. */
function toProductCard(row) {
  return {
    id: row.id,
    name: row.name,
    imageUrl: row.image_url,
    shopId: row.shop_id,
    shopName: row.shop_name,
    categoryId: row.category_id,
    status: row.status,
    minPrice: Number(row.min_price),
    maxPrice: Number(row.max_price),
    totalStock: Number(row.total_stock),
    soldCount: row.sold_count,
    ratingAvg: Number(row.rating_avg),
    ratingCount: row.rating_count,
    createdAt: row.created_at,
  };
}

/** Lấy shop của người bán, không có thì báo lỗi. */
async function requireShop(ownerId) {
  const result = await query('SELECT id FROM shops WHERE owner_id = $1', [ownerId]);
  if (result.rows.length === 0) throw new AppError(403, 'Bạn cần mở shop trước khi đăng bán');
  return result.rows[0].id;
}

/**
 * Tìm / lọc sản phẩm (public). Trả về danh sách + thông tin phân trang.
 */
export async function listProducts(filters) {
  const { keyword, categoryId, shopId, minPrice, maxPrice, minRating, sort, page, limit } = filters;

  const conditions = ["p.status = 'active'"];
  const params = [];

  if (keyword) {
    params.push(`%${keyword}%`);
    conditions.push(`p.name ILIKE $${params.length}`);
  }
  if (categoryId) {
    params.push(categoryId);
    conditions.push(`p.category_id = $${params.length}`);
  }
  if (shopId) {
    params.push(shopId);
    conditions.push(`p.shop_id = $${params.length}`);
  }
  if (minRating) {
    params.push(minRating);
    conditions.push(`p.rating_avg >= $${params.length}`);
  }
  if (minPrice !== undefined) {
    params.push(minPrice);
    conditions.push(`v.min_price >= $${params.length}`);
  }
  if (maxPrice !== undefined) {
    params.push(maxPrice);
    conditions.push(`v.min_price <= $${params.length}`);
  }

  const orderBy = {
    newest: 'p.created_at DESC',
    price_asc: 'v.min_price ASC',
    price_desc: 'v.min_price DESC',
    best_selling: 'p.sold_count DESC',
    rating: 'p.rating_avg DESC',
  }[sort];

  const where = conditions.join(' AND ');
  const variantJoin = `JOIN (
      SELECT product_id, MIN(price) AS min_price, MAX(price) AS max_price, SUM(stock) AS total_stock
      FROM product_variants GROUP BY product_id
    ) v ON v.product_id = p.id`;

  // Đếm tổng để phân trang
  const countRes = await query(
    `SELECT COUNT(*)::int AS total FROM products p ${variantJoin} WHERE ${where}`,
    params
  );
  const total = countRes.rows[0].total;

  // Lấy trang hiện tại
  const offset = (page - 1) * limit;
  const listParams = [...params, limit, offset];
  const listRes = await query(
    `SELECT p.*, s.name AS shop_name, v.min_price, v.max_price, v.total_stock
     FROM products p
     JOIN shops s ON s.id = p.shop_id
     ${variantJoin}
     WHERE ${where}
     ORDER BY ${orderBy}
     LIMIT $${listParams.length - 1} OFFSET $${listParams.length}`,
    listParams
  );

  return {
    items: listRes.rows.map(toProductCard),
    pagination: { page, limit, total, totalPages: Math.ceil(total / limit) },
  };
}

/** Chi tiết 1 sản phẩm: thông tin + các phân loại + shop + đánh giá gần đây. */
export async function getProductDetail(productId) {
  const productRes = await query(
    `SELECT p.*, s.name AS shop_name, s.avatar_url AS shop_avatar
     FROM products p JOIN shops s ON s.id = p.shop_id
     WHERE p.id = $1`,
    [productId]
  );
  const p = productRes.rows[0];
  if (!p) throw new AppError(404, 'Không tìm thấy sản phẩm');

  const variantsRes = await query(
    'SELECT id, name, price, stock FROM product_variants WHERE product_id = $1 ORDER BY id',
    [productId]
  );
  const reviewsRes = await query(
    `SELECT r.id, r.rating, r.comment, r.created_at, u.full_name AS user_name
     FROM reviews r JOIN users u ON u.id = r.user_id
     WHERE r.product_id = $1 ORDER BY r.created_at DESC LIMIT 10`,
    [productId]
  );

  return {
    id: p.id,
    name: p.name,
    description: p.description,
    imageUrl: p.image_url,
    status: p.status,
    categoryId: p.category_id,
    soldCount: p.sold_count,
    ratingAvg: Number(p.rating_avg),
    ratingCount: p.rating_count,
    createdAt: p.created_at,
    shop: { id: p.shop_id, name: p.shop_name, avatarUrl: p.shop_avatar },
    variants: variantsRes.rows.map((v) => ({
      id: v.id,
      name: v.name,
      price: Number(v.price),
      stock: v.stock,
    })),
    reviews: reviewsRes.rows.map((r) => ({
      id: r.id,
      rating: r.rating,
      comment: r.comment,
      userName: r.user_name,
      createdAt: r.created_at,
    })),
  };
}

/** Người bán tạo sản phẩm mới (kèm các phân loại). */
export async function createProduct(ownerId, data) {
  const shopId = await requireShop(ownerId);
  return withTransaction(async (client) => {
    const productRes = await client.query(
      `INSERT INTO products (shop_id, category_id, name, description, image_url)
       VALUES ($1, $2, $3, $4, $5) RETURNING id`,
      [shopId, data.categoryId ?? null, data.name, data.description ?? null, data.imageUrl ?? null]
    );
    const productId = productRes.rows[0].id;

    for (const v of data.variants) {
      await client.query(
        'INSERT INTO product_variants (product_id, name, price, stock) VALUES ($1, $2, $3, $4)',
        [productId, v.name, v.price, v.stock]
      );
    }
    return { id: productId };
  });
}

/** Người bán sửa sản phẩm của shop mình. Thay toàn bộ danh sách phân loại. */
export async function updateProduct(ownerId, productId, data) {
  const shopId = await requireShop(ownerId);
  return withTransaction(async (client) => {
    const owned = await client.query('SELECT id FROM products WHERE id = $1 AND shop_id = $2', [
      productId,
      shopId,
    ]);
    if (owned.rows.length === 0) throw new AppError(404, 'Không tìm thấy sản phẩm của shop bạn');

    await client.query(
      `UPDATE products SET name=$1, description=$2, category_id=$3, image_url=$4, status=COALESCE($5, status)
       WHERE id=$6`,
      [
        data.name,
        data.description ?? null,
        data.categoryId ?? null,
        data.imageUrl ?? null,
        data.status ?? null,
        productId,
      ]
    );

    // Thay toàn bộ phân loại (xóa cũ, thêm mới)
    await client.query('DELETE FROM product_variants WHERE product_id = $1', [productId]);
    for (const v of data.variants) {
      await client.query(
        'INSERT INTO product_variants (product_id, name, price, stock) VALUES ($1, $2, $3, $4)',
        [productId, v.name, v.price, v.stock]
      );
    }
    return { id: productId };
  });
}

/** Người bán xóa sản phẩm. */
export async function deleteProduct(ownerId, productId) {
  const shopId = await requireShop(ownerId);
  const result = await query('DELETE FROM products WHERE id = $1 AND shop_id = $2 RETURNING id', [
    productId,
    shopId,
  ]);
  if (result.rows.length === 0) throw new AppError(404, 'Không tìm thấy sản phẩm của shop bạn');
}

/** Danh sách sản phẩm của shop mình (gồm cả hàng đang ẩn). */
export async function listMyProducts(ownerId) {
  const shopId = await requireShop(ownerId);
  const result = await query(
    `SELECT p.*, s.name AS shop_name, v.min_price, v.max_price, v.total_stock
     FROM products p
     JOIN shops s ON s.id = p.shop_id
     JOIN (SELECT product_id, MIN(price) min_price, MAX(price) max_price, SUM(stock) total_stock
           FROM product_variants GROUP BY product_id) v ON v.product_id = p.id
     WHERE p.shop_id = $1 ORDER BY p.created_at DESC`,
    [shopId]
  );
  return result.rows.map(toProductCard);
}
