/** Khu vực quản trị (admin). Mọi route đều cần đăng nhập + quyền admin. */
import { Router } from 'express';
import { query } from '../../db/pool.js';
import { authRequired, adminOnly } from '../../middlewares/auth.middleware.js';
import { asyncHandler } from '../../utils/asyncHandler.js';
import { ok } from '../../utils/response.js';
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

export default router;
