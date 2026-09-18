import { asyncHandler } from '../../utils/asyncHandler.js';
import { ok, created } from '../../utils/response.js';
import { AppError } from '../../utils/AppError.js';
import * as shopService from './shop.service.js';

/** GET /api/shops/me — shop của tôi (null nếu chưa mở). */
export const getMyShop = asyncHandler(async (req, res) => {
  const shop = await shopService.getShopByOwner(req.user.id);
  return ok(res, shop);
});

/** POST /api/shops — mở shop. */
export const createShop = asyncHandler(async (req, res) => {
  const shop = await shopService.createShop(req.user.id, req.body);
  return created(res, shop);
});

/** PUT /api/shops/me — cập nhật shop. */
export const updateShop = asyncHandler(async (req, res) => {
  const shop = await shopService.updateShop(req.user.id, req.body);
  return ok(res, shop);
});

/** GET /api/shops/:id — xem trang shop công khai. */
export const getPublicShop = asyncHandler(async (req, res) => {
  const id = Number(req.params.id);
  if (!Number.isInteger(id)) throw new AppError(400, 'ID shop không hợp lệ');
  const shop = await shopService.getPublicShop(id);
  return ok(res, shop);
});
