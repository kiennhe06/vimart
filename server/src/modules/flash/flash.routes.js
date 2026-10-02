/** Flash sale — phía khách (xem các đợt đang chạy). */
import { Router } from 'express';
import { asyncHandler } from '../../utils/asyncHandler.js';
import { ok } from '../../utils/response.js';
import { listActive } from './flash.service.js';

const router = Router();

/** GET /api/flash-sales/active — các đợt flash sale đang chạy (public). */
router.get(
  '/active',
  asyncHandler(async (req, res) => ok(res, await listActive()))
);

export default router;
