import { Router } from 'express';
import { z } from 'zod';
import { authRequired } from '../../middlewares/auth.middleware.js';
import { validate } from '../../middlewares/validate.middleware.js';
import { asyncHandler } from '../../utils/asyncHandler.js';
import { created } from '../../utils/response.js';
import { checkoutSchema } from './order.schema.js';
import * as orderController from './order.controller.js';
import { requestReturn } from '../return/return.service.js';

const router = Router();
router.use(authRequired); // mọi thao tác đơn hàng đều cần đăng nhập

const returnSchema = z.object({
  reason: z.enum(['defective', 'wrong_item', 'not_as_described', 'other']),
  note: z.string().max(1000).optional().nullable(),
});

// Người bán xem đơn của shop (đặt trước /:id)
router.get('/shop', orderController.listShop);

// Người mua
router.post('/checkout', validate(checkoutSchema), orderController.checkout);
router.get('/', orderController.listMine);
router.get('/:id', orderController.detail);
router.post('/:id/cancel', orderController.cancel);
router.post('/:id/received', orderController.received);

// Người mua yêu cầu trả hàng / hoàn tiền (đơn đã hoàn thành).
router.post(
  '/:id/return',
  validate(returnSchema),
  asyncHandler(async (req, res) =>
    created(res, await requestReturn(req.user.id, Number(req.params.id), req.body.reason, req.body.note))
  )
);

// Người bán đổi trạng thái
router.post('/:id/confirm', orderController.confirm);
router.post('/:id/ship', orderController.ship);
router.post('/:id/reject', orderController.reject);

export default router;
