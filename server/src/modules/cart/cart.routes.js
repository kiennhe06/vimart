import { Router } from 'express';
import { z } from 'zod';
import { authRequired } from '../../middlewares/auth.middleware.js';
import { validate } from '../../middlewares/validate.middleware.js';
import { asyncHandler } from '../../utils/asyncHandler.js';
import { ok } from '../../utils/response.js';
import * as cartService from './cart.service.js';

const router = Router();
router.use(authRequired); // giỏ hàng luôn cần đăng nhập

const addSchema = z.object({
  variantId: z.number().int(),
  quantity: z.number().int().min(1, 'Số lượng tối thiểu là 1'),
});
const qtySchema = z.object({
  quantity: z.number().int().min(1, 'Số lượng tối thiểu là 1'),
});

/** GET /api/cart — xem giỏ (gộp theo shop). */
router.get('/', asyncHandler(async (req, res) => ok(res, await cartService.getCart(req.user.id))));

/** POST /api/cart/items — thêm vào giỏ. */
router.post('/items', validate(addSchema), asyncHandler(async (req, res) =>
  ok(res, await cartService.addToCart(req.user.id, req.body))
));

/** PUT /api/cart/items/:id — đổi số lượng. */
router.put('/items/:id', validate(qtySchema), asyncHandler(async (req, res) =>
  ok(res, await cartService.updateQuantity(req.user.id, Number(req.params.id), req.body.quantity))
));

/** DELETE /api/cart/items/:id — xóa 1 dòng. */
router.delete('/items/:id', asyncHandler(async (req, res) =>
  ok(res, await cartService.removeItem(req.user.id, Number(req.params.id)))
));

/** DELETE /api/cart — xóa sạch giỏ. */
router.delete('/', asyncHandler(async (req, res) => ok(res, await cartService.clearCart(req.user.id))));

export default router;
