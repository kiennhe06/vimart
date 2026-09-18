import { asyncHandler } from '../../utils/asyncHandler.js';
import { ok, created } from '../../utils/response.js';
import { AppError } from '../../utils/AppError.js';
import * as productService from './product.service.js';

function productId(req) {
  const id = Number(req.params.id);
  if (!Number.isInteger(id)) throw new AppError(400, 'ID sản phẩm không hợp lệ');
  return id;
}

/** GET /api/products — tìm/lọc (public). */
export const list = asyncHandler(async (req, res) => {
  const result = await productService.listProducts(req.validatedQuery);
  return ok(res, result);
});

/** GET /api/products/mine — sản phẩm của shop tôi (người bán). */
export const listMine = asyncHandler(async (req, res) => {
  const result = await productService.listMyProducts(req.user.id);
  return ok(res, result);
});

/** GET /api/products/:id — chi tiết (public). */
export const detail = asyncHandler(async (req, res) => {
  const result = await productService.getProductDetail(productId(req));
  return ok(res, result);
});

/** POST /api/products — tạo (người bán). */
export const create = asyncHandler(async (req, res) => {
  const result = await productService.createProduct(req.user.id, req.body);
  return created(res, result);
});

/** PUT /api/products/:id — sửa (người bán). */
export const update = asyncHandler(async (req, res) => {
  const result = await productService.updateProduct(req.user.id, productId(req), req.body);
  return ok(res, result);
});

/** DELETE /api/products/:id — xóa (người bán). */
export const remove = asyncHandler(async (req, res) => {
  await productService.deleteProduct(req.user.id, productId(req));
  return ok(res, { message: 'Đã xóa sản phẩm' });
});
