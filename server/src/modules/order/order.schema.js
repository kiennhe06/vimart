import { z } from 'zod';

/** Dữ liệu khi đặt hàng (thanh toán giỏ). */
export const checkoutSchema = z.object({
  addressId: z.number().int('Thiếu địa chỉ nhận hàng'),
  paymentMethod: z.enum(['cod', 'vnpay']).default('cod'),
  note: z.string().max(500).optional().nullable(),
});
