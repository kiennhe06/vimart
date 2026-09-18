import { Router } from 'express';
import { validate } from '../../middlewares/validate.middleware.js';
import { authRequired } from '../../middlewares/auth.middleware.js';
import { registerSchema, loginSchema, changePasswordSchema } from './auth.schema.js';
import * as authController from './auth.controller.js';

const router = Router();

router.post('/register', validate(registerSchema), authController.register);
router.post('/login', validate(loginSchema), authController.login);
router.get('/me', authRequired, authController.me);
router.post(
  '/change-password',
  authRequired,
  validate(changePasswordSchema),
  authController.changePassword
);

export default router;
