/** Mã giảm giá — phía khách hàng (xem trước mức giảm ở màn thanh toán). */
import { Router } from 'express';
import { z } from 'zod';
import { authRequired } from '../../middlewares/auth.middleware.js';
import { validate } from '../../middlewares/validate.middleware.js';
import { asyncHandler } from '../../utils/asyncHandler.js';
import { ok } from '../../utils/response.js';
import { AppError } from '../../utils/AppError.js';
import { validateVoucher, cartSubtotal } from './voucher.service.js';

const router = Router();

const applySchema = z.object({ code: z.string().min(1, 'Vui lòng nhập mã giảm giá') });

/** POST /api/vouchers/apply — kiểm tra mã với giỏ hàng hiện tại, trả về mức giảm. */
router.post(
  '/apply',
  authRequired,
  validate(applySchema),
  asyncHandler(async (req, res) => {
    const subtotal = await cartSubtotal(req.user.id);
    if (subtotal <= 0) throw new AppError(400, 'Giỏ hàng đang trống');
    const { voucher, discount } = await validateVoucher(req.body.code, subtotal);
    return ok(res, {
      code: voucher.code,
      description: voucher.description,
      type: voucher.type,
      value: voucher.value,
      discount,
      subtotal,
    });
  })
);

export default router;
