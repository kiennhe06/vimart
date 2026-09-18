import { z } from 'zod';

/** Mở shop mới / cập nhật shop. */
export const shopSchema = z.object({
  name: z.string().min(2, 'Tên shop tối thiểu 2 ký tự'),
  description: z.string().max(1000).optional().nullable(),
  avatarUrl: z.string().url('Link ảnh không hợp lệ').optional().nullable(),
});
