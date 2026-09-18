import { Router } from 'express';
import { authRequired } from '../../middlewares/auth.middleware.js';
import { validate } from '../../middlewares/validate.middleware.js';
import { checkoutSchema } from './order.schema.js';
import * as orderController from './order.controller.js';

const router = Router();
router.use(authRequired); // mọi thao tác đơn hàng đều cần đăng nhập

// Người bán xem đơn của shop (đặt trước /:id)
router.get('/shop', orderController.listShop);

// Người mua
router.post('/checkout', validate(checkoutSchema), orderController.checkout);
router.get('/', orderController.listMine);
router.get('/:id', orderController.detail);
router.post('/:id/cancel', orderController.cancel);
router.post('/:id/received', orderController.received);

// Người bán đổi trạng thái
router.post('/:id/confirm', orderController.confirm);
router.post('/:id/ship', orderController.ship);
router.post('/:id/reject', orderController.reject);

export default router;
