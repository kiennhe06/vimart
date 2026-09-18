import { z } from 'zod';

/** Cập nhật hồ sơ cá nhân. */
export const updateProfileSchema = z.object({
  fullName: z.string().min(2, 'Họ tên tối thiểu 2 ký tự'),
  phone: z.string().min(8).max(20).optional().nullable(),
});

/** Thêm / sửa địa chỉ nhận hàng. */
export const addressSchema = z.object({
  recipientName: z.string().min(2, 'Tên người nhận tối thiểu 2 ký tự'),
  phone: z.string().min(8, 'Số điện thoại không hợp lệ').max(20),
  line: z.string().min(3, 'Địa chỉ cụ thể quá ngắn'),
  ward: z.string().optional().nullable(),
  district: z.string().optional().nullable(),
  province: z.string().optional().nullable(),
  isDefault: z.boolean().optional().default(false),
});
