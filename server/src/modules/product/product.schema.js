import { z } from 'zod';

/** Một phân loại (variant) của sản phẩm. */
const variantSchema = z.object({
  name: z.string().min(1).default('Mặc định'),
  price: z.number().int('Giá phải là số nguyên').nonnegative('Giá không được âm'),
  stock: z.number().int().nonnegative('Tồn kho không được âm').default(0),
});

/** Tạo sản phẩm mới (kèm ít nhất 1 phân loại). */
export const createProductSchema = z.object({
  name: z.string().min(2, 'Tên sản phẩm tối thiểu 2 ký tự'),
  description: z.string().max(5000).optional().nullable(),
  categoryId: z.number().int().optional().nullable(),
  imageUrl: z.string().url('Link ảnh không hợp lệ').optional().nullable(),
  variants: z.array(variantSchema).min(1, 'Cần ít nhất 1 phân loại (giá + tồn kho)'),
});

/** Cập nhật sản phẩm. Cho phép đổi trạng thái ẩn/hiện. */
export const updateProductSchema = createProductSchema.extend({
  status: z.enum(['active', 'hidden']).optional(),
});

/** Bộ lọc khi tìm sản phẩm (query string). */
export const listProductQuerySchema = z.object({
  keyword: z.string().optional(),
  categoryId: z.coerce.number().int().optional(),
  shopId: z.coerce.number().int().optional(),
  minPrice: z.coerce.number().int().optional(),
  maxPrice: z.coerce.number().int().optional(),
  minRating: z.coerce.number().min(0).max(5).optional(),
  sort: z.enum(['newest', 'price_asc', 'price_desc', 'best_selling', 'rating']).default('newest'),
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(50).default(20),
});
