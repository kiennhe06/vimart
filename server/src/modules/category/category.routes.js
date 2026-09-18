/** Danh mục sản phẩm. Xem thì public; thêm/xóa cần admin. */
import { Router } from 'express';
import { z } from 'zod';
import { query } from '../../db/pool.js';
import { asyncHandler } from '../../utils/asyncHandler.js';
import { ok, created } from '../../utils/response.js';
import { authRequired, adminOnly } from '../../middlewares/auth.middleware.js';
import { validate } from '../../middlewares/validate.middleware.js';

const router = Router();

const categorySchema = z.object({
  name: z.string().min(1, 'Tên danh mục không được trống'),
  slug: z.string().min(1, 'Slug không được trống'),
  icon: z.string().optional().nullable(),
});

/** GET /api/categories — danh sách danh mục (public). */
router.get(
  '/',
  asyncHandler(async (req, res) => {
    const result = await query('SELECT id, name, slug, icon FROM categories ORDER BY id');
    return ok(res, result.rows);
  })
);

/** POST /api/categories — admin thêm danh mục. */
router.post(
  '/',
  authRequired,
  adminOnly,
  validate(categorySchema),
  asyncHandler(async (req, res) => {
    const { name, slug, icon } = req.body;
    const result = await query(
      'INSERT INTO categories (name, slug, icon) VALUES ($1, $2, $3) RETURNING id, name, slug, icon',
      [name, slug, icon ?? null]
    );
    return created(res, result.rows[0]);
  })
);

export default router;
