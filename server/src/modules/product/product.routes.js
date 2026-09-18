import { Router } from 'express';
import { authRequired } from '../../middlewares/auth.middleware.js';
import { validate, validateQuery } from '../../middlewares/validate.middleware.js';
import { createProductSchema, updateProductSchema, listProductQuerySchema } from './product.schema.js';
import * as productController from './product.controller.js';

const router = Router();

// --- Người bán (đặt /mine TRƯỚC /:id để không bị hiểu nhầm là id) ---
router.get('/mine', authRequired, productController.listMine);
router.post('/', authRequired, validate(createProductSchema), productController.create);
router.put('/:id', authRequired, validate(updateProductSchema), productController.update);
router.delete('/:id', authRequired, productController.remove);

// --- Public ---
router.get('/', validateQuery(listProductQuerySchema), productController.list);
router.get('/:id', productController.detail);

export default router;
