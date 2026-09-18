/** Sản phẩm yêu thích (wishlist). */
import { Router } from 'express';
import { query } from '../../db/pool.js';
import { authRequired } from '../../middlewares/auth.middleware.js';
import { asyncHandler } from '../../utils/asyncHandler.js';
import { ok } from '../../utils/response.js';

const router = Router();
router.use(authRequired);

/** GET /api/favorites — danh sách sản phẩm đã thích. */
router.get(
  '/',
  asyncHandler(async (req, res) => {
    const result = await query(
      `SELECT p.id, p.name, p.image_url, p.sold_count, p.rating_avg,
              (SELECT MIN(price) FROM product_variants WHERE product_id = p.id) AS min_price
       FROM favorites f JOIN products p ON p.id = f.product_id
       WHERE f.user_id = $1 ORDER BY f.created_at DESC`,
      [req.user.id]
    );
    return ok(
      res,
      result.rows.map((p) => ({
        id: p.id,
        name: p.name,
        imageUrl: p.image_url,
        soldCount: p.sold_count,
        ratingAvg: Number(p.rating_avg),
        minPrice: Number(p.min_price),
      }))
    );
  })
);

/** POST /api/favorites/:productId — thêm vào yêu thích. */
router.post(
  '/:productId',
  asyncHandler(async (req, res) => {
    await query(
      'INSERT INTO favorites (user_id, product_id) VALUES ($1, $2) ON CONFLICT DO NOTHING',
      [req.user.id, Number(req.params.productId)]
    );
    return ok(res, { message: 'Đã thêm vào yêu thích' });
  })
);

/** DELETE /api/favorites/:productId — bỏ yêu thích. */
router.delete(
  '/:productId',
  asyncHandler(async (req, res) => {
    await query('DELETE FROM favorites WHERE user_id = $1 AND product_id = $2', [
      req.user.id,
      Number(req.params.productId),
    ]);
    return ok(res, { message: 'Đã bỏ yêu thích' });
  })
);

export default router;
