/** Khu vực quản trị (admin). Mọi route đều cần đăng nhập + quyền admin. */
import { Router } from 'express';
import { z } from 'zod';
import { query, withTransaction } from '../../db/pool.js';
import { authRequired, adminOnly } from '../../middlewares/auth.middleware.js';
import { asyncHandler } from '../../utils/asyncHandler.js';
import { validate } from '../../middlewares/validate.middleware.js';
import { ok, created } from '../../utils/response.js';
import { AppError } from '../../utils/AppError.js';
import { changeStatus } from '../order/order.service.js';
import { getProductDetail } from '../product/product.service.js';

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

/** GET /api/admin/orders/:id — chi tiết đầy đủ 1 đơn (món hàng + người mua). */
router.get(
  '/orders/:id',
  asyncHandler(async (req, res) => {
    const id = Number(req.params.id);
    const orderRes = await query(
      `SELECT o.*, s.name AS shop_name, u.full_name AS buyer_name, u.email AS buyer_email
       FROM orders o JOIN shops s ON s.id = o.shop_id JOIN users u ON u.id = o.buyer_id
       WHERE o.id = $1`,
      [id]
    );
    const o = orderRes.rows[0];
    if (!o) throw new AppError(404, 'Không tìm thấy đơn hàng');

    const itemsRes = await query(
      `SELECT product_name, variant_name, image_url, price, quantity
       FROM order_items WHERE order_id = $1`,
      [id]
    );
    return ok(res, {
      id: o.id,
      code: o.code,
      status: o.status,
      shopName: o.shop_name,
      buyerName: o.buyer_name,
      buyerEmail: o.buyer_email,
      recipientName: o.recipient_name,
      recipientPhone: o.recipient_phone,
      addressText: o.address_text,
      paymentMethod: o.payment_method,
      paymentStatus: o.payment_status,
      subtotal: Number(o.subtotal),
      shippingFee: Number(o.shipping_fee),
      discount: Number(o.discount),
      total: Number(o.total),
      note: o.note,
      createdAt: o.created_at,
      items: itemsRes.rows.map((i) => ({
        productName: i.product_name,
        variantName: i.variant_name,
        imageUrl: i.image_url,
        price: Number(i.price),
        quantity: i.quantity,
      })),
    });
  })
);

/** GET /api/admin/users/:id — chi tiết 1 người dùng (thông tin + shop + đơn đã mua). */
router.get(
  '/users/:id',
  asyncHandler(async (req, res) => {
    const id = Number(req.params.id);
    const userRes = await query(
      `SELECT id, email, full_name, phone, role, is_active, created_at FROM users WHERE id = $1`,
      [id]
    );
    const u = userRes.rows[0];
    if (!u) throw new AppError(404, 'Không tìm thấy người dùng');

    const [shopRes, ordersRes] = await Promise.all([
      query('SELECT id, name, status FROM shops WHERE owner_id = $1', [id]),
      query(
        `SELECT o.id, o.code, o.status, o.total, o.created_at, s.name AS shop_name
         FROM orders o JOIN shops s ON s.id = o.shop_id
         WHERE o.buyer_id = $1 ORDER BY o.created_at DESC LIMIT 20`,
        [id]
      ),
    ]);
    return ok(res, {
      id: u.id,
      email: u.email,
      fullName: u.full_name,
      phone: u.phone,
      role: u.role,
      isActive: u.is_active,
      createdAt: u.created_at,
      shop: shopRes.rows[0]
        ? { id: shopRes.rows[0].id, name: shopRes.rows[0].name, status: shopRes.rows[0].status }
        : null,
      orders: ordersRes.rows.map((o) => ({
        id: o.id,
        code: o.code,
        status: o.status,
        total: Number(o.total),
        shopName: o.shop_name,
        createdAt: o.created_at,
      })),
    });
  })
);

/** POST /api/admin/orders/:id/action — admin đổi trạng thái đơn (theo đúng trình
 *  tự pipeline + side-effect: hoàn kho khi hủy, COD nhận = đã trả). */
const adminOrderActionSchema = z.object({
  action: z.enum(['confirm', 'ship', 'reject', 'cancel', 'received']),
});
router.post(
  '/orders/:id/action',
  validate(adminOrderActionSchema),
  asyncHandler(async (req, res) => {
    const id = Number(req.params.id);
    const updated = await changeStatus(req.user.id, id, req.body.action, { asAdmin: true });
    return ok(res, updated);
  })
);

/** GET /api/admin/reviews — tất cả đánh giá sản phẩm trên sàn (mới nhất trước). */
router.get(
  '/reviews',
  asyncHandler(async (req, res) => {
    const result = await query(
      `SELECT r.id, r.rating, r.comment, r.reply, r.reply_at, r.created_at,
              p.id AS product_id, p.name AS product_name,
              s.name AS shop_name, u.full_name AS user_name
       FROM reviews r
       JOIN products p ON p.id = r.product_id
       JOIN shops s ON s.id = p.shop_id
       JOIN users u ON u.id = r.user_id
       ORDER BY r.created_at DESC LIMIT 200`
    );
    return ok(
      res,
      result.rows.map((r) => ({
        id: r.id,
        rating: r.rating,
        comment: r.comment,
        reply: r.reply,
        replyAt: r.reply_at,
        createdAt: r.created_at,
        productId: r.product_id,
        productName: r.product_name,
        shopName: r.shop_name,
        userName: r.user_name,
      }))
    );
  })
);

/** POST /api/admin/reviews/:id/reply — admin phản hồi 1 đánh giá. Body: { reply } */
const adminReviewReplySchema = z.object({
  reply: z.string().trim().min(1, 'Nội dung phản hồi không được trống').max(1000),
});
router.post(
  '/reviews/:id/reply',
  validate(adminReviewReplySchema),
  asyncHandler(async (req, res) => {
    const id = Number(req.params.id);
    const result = await query(
      'UPDATE reviews SET reply = $1, reply_at = now() WHERE id = $2 RETURNING id, reply, reply_at',
      [req.body.reply, id]
    );
    if (result.rows.length === 0) throw new AppError(404, 'Không tìm thấy đánh giá');
    const r = result.rows[0];
    return ok(res, { id: r.id, reply: r.reply, replyAt: r.reply_at });
  })
);

/** GET /api/admin/products/:id — chi tiết đầy đủ 1 sản phẩm (kể cả hàng ẩn). */
router.get(
  '/products/:id',
  asyncHandler(async (req, res) => {
    const detail = await getProductDetail(Number(req.params.id));
    return ok(res, detail);
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
