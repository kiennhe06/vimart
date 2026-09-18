import { Router } from 'express';
import { authRequired } from '../../middlewares/auth.middleware.js';
import { validate } from '../../middlewares/validate.middleware.js';
import { updateProfileSchema, addressSchema } from './user.schema.js';
import * as userController from './user.controller.js';

const router = Router();

// Tất cả route dưới đây đều cần đăng nhập
router.use(authRequired);

// Hồ sơ cá nhân
router.put('/me', validate(updateProfileSchema), userController.updateProfile);

// Sổ địa chỉ nhận hàng
router.get('/me/addresses', userController.listAddresses);
router.post('/me/addresses', validate(addressSchema), userController.addAddress);
router.put('/me/addresses/:id', validate(addressSchema), userController.updateAddress);
router.delete('/me/addresses/:id', userController.deleteAddress);

export default router;
