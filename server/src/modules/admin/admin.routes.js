/** Khu vực quản trị (admin). Mọi route đều cần đăng nhập + quyền admin. */
import { Router } from 'express';
import { z } from 'zod';
import { query, withTransaction } from '../../db/pool.js';
import { authRequired, adminOnly } from '../../middlewares/auth.middleware.js';
import { asyncHandler } from '../../utils/asyncHandler.js';
import { validate } from '../../middlewares/validate.middleware.js';
import { ok, created } from '../../utils/response.js';
import { AppError } from '../../utils/AppError.js';

const router = Router();
router.use(authRequired, adminOnly);

/** GET /api/admin/users — danh sách người dùng. */
router.get(
  '/users',
  asyncHandler(async (req, res) => {
    const result = await query(
      `SELECT u.id, u.email, u.full_name, u.role, u.is_active, u.created_at,
              s.id AS shop_id, s.name AS shop_name
       FROM users u LEFT JOIN shops s ON s.owner_id = u.id
       ORDER BY u.id`
    );
    return ok(
      res,
      result.rows.map((u) => ({
        id: u.id,
        email: u.email,
        fullName: u.full_name,
        role: u.role,
        isActive: u.is_active,
        createdAt: u.created_at,
        shop: u.shop_id ? { id: u.shop_id, name: u.shop_name } : null,
      }))
    );
  })
);

/** PUT /api/admin/users/:id/status — khóa / mở khóa tài khoản. Body: { isActive } */
router.put(
  '/users/:id/status',
  asyncHandler(async (req, res) => {
    const isActive = Boolean(req.body.isActive);
    const id = Number(req.params.id);
    if (id === req.user.id) throw new AppError(400, 'Không thể tự khóa chính mình');

    const result = await query(
      'UPDATE users SET is_active = $1 WHERE id = $2 RETURNING id, is_active',
      [isActive, id]
    );
    if (result.rows.length === 0) throw new AppError(404, 'Không tìm thấy người dùng');
    return ok(res, { id, isActive: result.rows[0].is_active });
  })
);

/** GET /api/admin/orders — tất cả đơn hàng trên sàn. */
router.get(
  '/orders',
  asyncHandler(async (req, res) => {
    const result = await query(
      `SELECT o.id, o.code, o.status, o.total, o.payment_method, o.payment_status, o.created_at,
              s.name AS shop_name, u.full_name AS buyer_name
       FROM orders o JOIN shops s ON s.id = o.shop_id JOIN users u ON u.id = o.buyer_id
       ORDER BY o.created_at DESC LIMIT 200`
    );
    return ok(res, result.rows);
  })
);

/** GET /api/admin/stats — thống kê tổng quan cho dashboard admin. */
router.get(
  '/stats',
  asyncHandler(async (req, res) => {
    const [users, shops, products, orders, revenue] = await Promise.all([
      query('SELECT COUNT(*)::int AS c FROM users'),
      query('SELECT COUNT(*)::int AS c FROM shops'),
      query('SELECT COUNT(*)::int AS c FROM products'),
      query('SELECT COUNT(*)::int AS c FROM orders'),
      query("SELECT COALESCE(SUM(total),0)::int AS s FROM orders WHERE status = 'completed'"),
    ]);
    return ok(res, {
      totalUsers: users.rows[0].c,
      totalShops: shops.rows[0].c,
      totalProducts: products.rows[0].c,
      totalOrders: orders.rows[0].c,
      totalRevenue: revenue.rows[0].s,
    });
  })
);

/** GET /api/admin/shops — danh sách shop (để gán sản phẩm). */
router.get(
  '/shops',
  asyncHandler(async (req, res) => {
    const result = await query(
      `SELECT s.id, s.name, u.full_name AS owner_name
       FROM shops s JOIN users u ON u.id = s.owner_id ORDER BY s.id`
    );
    return ok(res, result.rows);
  })
);

/** GET /api/admin/products — tất cả sản phẩm (gồm cả hàng ẩn). */
router.get(
  '/products',
  asyncHandler(async (req, res) => {
    const result = await query(
      `SELECT p.id, p.name, p.image_url, p.status, p.category_id, p.sold_count,
              s.id AS shop_id, s.name AS shop_name,
              v.min_price, v.total_stock
       FROM products p
       JOIN shops s ON s.id = p.shop_id
       LEFT JOIN (SELECT product_id, MIN(price) min_price, SUM(stock) total_stock
                  FROM product_variants GROUP BY product_id) v ON v.product_id = p.id
       ORDER BY p.created_at DESC`
    );
    return ok(
      res,
      result.rows.map((p) => ({
        id: p.id,
        name: p.name,
        imageUrl: p.image_url,
        status: p.status,
        categoryId: p.category_id,
        soldCount: p.sold_count,
        shopId: p.shop_id,
        shopName: p.shop_name,
        minPrice: Number(p.min_price || 0),
        totalStock: Number(p.total_stock || 0),
      }))
    );
  })
);

// Schema cho admin tạo/sửa sản phẩm.
const adminProductSchema = z.object({
  shopId: z.number().int('Chọn shop'),
  categoryId: z.number().int().optional().nullable(),
  name: z.string().min(2, 'Tên sản phẩm tối thiểu 2 ký tự'),
  description: z.string().max(5000).optional().nullable(),
  imageUrl: z.string().url('Link ảnh không hợp lệ').optional().nullable(),
  status: z.enum(['active', 'hidden']).optional(),
  variants: z
    .array(
      z.object({
        name: z.string().min(1).default('Mặc định'),
        price: z.number().int().nonnegative('Giá không được âm'),
        stock: z.number().int().nonnegative('Tồn kho không được âm').default(0),
      })
    )
    .min(1, 'Cần ít nhất 1 phân loại'),
});

/** Ghi các phân loại cho 1 sản phẩm (dùng chung cho tạo & sửa). */
async function writeVariants(client, productId, variants) {
  await client.query('DELETE FROM product_variants WHERE product_id = $1', [productId]);
  for (const v of variants) {
    await client.query(
      'INSERT INTO product_variants (product_id, name, price, stock) VALUES ($1,$2,$3,$4)',
      [productId, v.name, v.price, v.stock]
    );
  }
}

/** POST /api/admin/products — admin tạo sản phẩm cho 1 shop bất kỳ. */
router.post(
  '/products',
  validate(adminProductSchema),
  asyncHandler(async (req, res) => {
    const d = req.body;
    const shop = await query('SELECT id FROM shops WHERE id = $1', [d.shopId]);
    if (shop.rows.length === 0) throw new AppError(404, 'Không tìm thấy shop');

    const result = await withTransaction(async (client) => {
      const p = await client.query(
        `INSERT INTO products (shop_id, category_id, name, description, image_url, status)
         VALUES ($1,$2,$3,$4,$5,$6) RETURNING id`,
        [
          d.shopId,
          d.categoryId ?? null,
          d.name,
          d.description ?? null,
          d.imageUrl ?? null,
          d.status ?? 'active',
        ]
      );
      await writeVariants(client, p.rows[0].id, d.variants);
      return { id: p.rows[0].id };
    });
    return created(res, result);
  })
);

/** PUT /api/admin/products/:id — admin sửa sản phẩm. */
router.put(
  '/products/:id',
  validate(adminProductSchema),
  asyncHandler(async (req, res) => {
    const id = Number(req.params.id);
    const d = req.body;
    await withTransaction(async (client) => {
      const exists = await client.query('SELECT id FROM products WHERE id = $1', [id]);
      if (exists.rows.length === 0) throw new AppError(404, 'Không tìm thấy sản phẩm');
      await client.query(
        `UPDATE products SET shop_id=$1, category_id=$2, name=$3, description=$4, image_url=$5, status=$6 WHERE id=$7`,
        [
          d.shopId,
          d.categoryId ?? null,
          d.name,
          d.description ?? null,
          d.imageUrl ?? null,
          d.status ?? 'active',
          id,
        ]
      );
      await writeVariants(client, id, d.variants);
    });
    return ok(res, { id });
  })
);

/** DELETE /api/admin/products/:id — admin xóa sản phẩm. */
router.delete(
  '/products/:id',
  asyncHandler(async (req, res) => {
    const result = await query('DELETE FROM products WHERE id = $1 RETURNING id', [
      Number(req.params.id),
    ]);
    if (result.rows.length === 0) throw new AppError(404, 'Không tìm thấy sản phẩm');
    return ok(res, { message: 'Đã xóa sản phẩm' });
  })
);

export default router;
