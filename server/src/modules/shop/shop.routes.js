import { Router } from 'express';
import { authRequired } from '../../middlewares/auth.middleware.js';
import { validate } from '../../middlewares/validate.middleware.js';
import { shopSchema } from './shop.schema.js';
import * as shopController from './shop.controller.js';

const router = Router();

// Shop của tôi (cần đăng nhập)
router.get('/me', authRequired, shopController.getMyShop);
router.post('/', authRequired, validate(shopSchema), shopController.createShop);
router.put('/me', authRequired, validate(shopSchema), shopController.updateShop);

// Xem trang shop công khai (ai cũng xem được) — đặt sau /me để không nuốt "me"
router.get('/:id', shopController.getPublicShop);

export default router;
