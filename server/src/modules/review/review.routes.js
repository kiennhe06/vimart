/** Đánh giá sản phẩm — chỉ được đánh giá món hàng trong đơn đã hoàn thành. */
import { Router } from 'express';
import { z } from 'zod';
import { query, withTransaction } from '../../db/pool.js';
import { authRequired } from '../../middlewares/auth.middleware.js';
import { validate } from '../../middlewares/validate.middleware.js';
import { asyncHandler } from '../../utils/asyncHandler.js';
import { ok, created } from '../../utils/response.js';
import { AppError } from '../../utils/AppError.js';

const router = Router();

const reviewSchema = z.object({
  orderItemId: z.number().int(),
  rating: z.number().int().min(1).max(5),
  comment: z.string().max(1000).optional().nullable(),
});

/** POST /api/reviews — tạo đánh giá. */
router.post(
  '/',
  authRequired,
  validate(reviewSchema),
  asyncHandler(async (req, res) => {
    const userId = req.user.id;
    const { orderItemId, rating, comment } = req.body;

    const result = await withTransaction(async (client) => {
      // Kiểm tra món hàng thuộc đơn của người dùng và đơn đã hoàn thành
      const itemRes = await client.query(
        `SELECT oi.id, oi.product_id, oi.reviewed, o.status, o.buyer_id
         FROM order_items oi JOIN orders o ON o.id = oi.order_id
         WHERE oi.id = $1`,
        [orderItemId]
      );
      const item = itemRes.rows[0];
      if (!item) throw new AppError(404, 'Không tìm thấy món hàng');
      if (item.buyer_id !== userId) throw new AppError(403, 'Đây không phải đơn của bạn');
      if (item.status !== 'completed') throw new AppError(400, 'Chỉ đánh giá được khi đơn đã hoàn thành');
      if (item.reviewed) throw new AppError(409, 'Món hàng này đã được đánh giá');

      const insert = await client.query(
        `INSERT INTO reviews (order_item_id, product_id, user_id, rating, comment)
         VALUES ($1, $2, $3, $4, $5) RETURNING id`,
        [orderItemId, item.product_id, userId, rating, comment ?? null]
      );
      await client.query('UPDATE order_items SET reviewed = TRUE WHERE id = $1', [orderItemId]);

      // Tính lại điểm trung bình của sản phẩm
      await client.query(
        `UPDATE products SET
           rating_count = (SELECT COUNT(*) FROM reviews WHERE product_id = $1),
           rating_avg   = ROUND((SELECT AVG(rating) FROM reviews WHERE product_id = $1), 1)
         WHERE id = $1`,
        [item.product_id]
      );
      return { id: insert.rows[0].id };
    });

    return created(res, result);
  })
);

/** GET /api/reviews/product/:productId — danh sách đánh giá của 1 sản phẩm (public). */
router.get(
  '/product/:productId',
  asyncHandler(async (req, res) => {
    const productId = Number(req.params.productId);
    const result = await query(
      `SELECT r.id, r.rating, r.comment, r.created_at, u.full_name AS user_name
       FROM reviews r JOIN users u ON u.id = r.user_id
       WHERE r.product_id = $1 ORDER BY r.created_at DESC`,
      [productId]
    );
    return ok(
      res,
      result.rows.map((r) => ({
        id: r.id,
        rating: r.rating,
        comment: r.comment,
        userName: r.user_name,
        createdAt: r.created_at,
      }))
    );
  })
);

export default router;
