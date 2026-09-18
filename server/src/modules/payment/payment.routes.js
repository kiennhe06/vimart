import { Router } from 'express';
import { z } from 'zod';
import { authRequired } from '../../middlewares/auth.middleware.js';
import { validate } from '../../middlewares/validate.middleware.js';
import { asyncHandler } from '../../utils/asyncHandler.js';
import { ok } from '../../utils/response.js';
import * as paymentService from './payment.service.js';

const router = Router();

const groupSchema = z.object({ groupCode: z.string().min(1) });

/** POST /api/payments/vnpay/create — tạo link thanh toán VNPay. */
router.post(
  '/vnpay/create',
  authRequired,
  validate(groupSchema),
  asyncHandler(async (req, res) => {
    const ip = req.headers['x-forwarded-for'] || req.socket.remoteAddress;
    const result = await paymentService.createVnpayUrl(req.user.id, req.body.groupCode, ip);
    return ok(res, result);
  })
);

/**
 * GET /api/payments/vnpay/return — VNPay chuyển hướng người dùng về đây.
 * Trả về 1 trang HTML đơn giản báo kết quả (vì đây là điểm redirect của trình duyệt).
 */
router.get(
  '/vnpay/return',
  asyncHandler(async (req, res) => {
    const result = await paymentService.handleVnpayReturn(req.query);
    const color = result.success ? '#16a34a' : '#dc2626';
    res.set('Content-Type', 'text/html; charset=utf-8');
    return res.send(`<!doctype html><html lang="vi"><head><meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1">
      <title>Kết quả thanh toán</title></head>
      <body style="font-family:sans-serif;text-align:center;padding:48px">
        <h1 style="color:${color}">${result.success ? '✅ Thanh toán thành công' : '❌ Thanh toán thất bại'}</h1>
        <p>${result.message}</p>
        ${result.groupCode ? `<p>Mã đơn: <b>${result.groupCode}</b></p>` : ''}
        <p style="color:#64748b">Bạn có thể quay lại ứng dụng ViMart.</p>
      </body></html>`);
  })
);

/** POST /api/payments/mock-pay — DEV: giả lập thanh toán thành công (test luồng). */
router.post(
  '/mock-pay',
  authRequired,
  validate(groupSchema),
  asyncHandler(async (req, res) => {
    const result = await paymentService.mockPay(req.user.id, req.body.groupCode);
    return ok(res, result);
  })
);

export default router;
