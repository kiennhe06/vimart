/**
 * Gom tất cả routes của các module lại dưới tiền tố /api.
 * Ví dụ: /api/auth/login, /api/products, /api/orders...
 */
import { Router } from 'express';

import authRoutes from './modules/auth/auth.routes.js';
import userRoutes from './modules/user/user.routes.js';
import shopRoutes from './modules/shop/shop.routes.js';
import categoryRoutes from './modules/category/category.routes.js';
import productRoutes from './modules/product/product.routes.js';
import cartRoutes from './modules/cart/cart.routes.js';
import orderRoutes from './modules/order/order.routes.js';
import paymentRoutes from './modules/payment/payment.routes.js';
import reviewRoutes from './modules/review/review.routes.js';
import favoriteRoutes from './modules/favorite/favorite.routes.js';
import adminRoutes from './modules/admin/admin.routes.js';

const router = Router();

router.use('/auth', authRoutes);
router.use('/users', userRoutes);
router.use('/shops', shopRoutes);
router.use('/categories', categoryRoutes);
router.use('/products', productRoutes);
router.use('/cart', cartRoutes);
router.use('/orders', orderRoutes);
router.use('/payments', paymentRoutes);
router.use('/reviews', reviewRoutes);
router.use('/favorites', favoriteRoutes);
router.use('/admin', adminRoutes);

export default router;
