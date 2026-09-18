import { asyncHandler } from '../../utils/asyncHandler.js';
import { ok, created } from '../../utils/response.js';
import * as orderService from './order.service.js';

/** POST /api/orders/checkout — đặt hàng từ giỏ. */
export const checkout = asyncHandler(async (req, res) => {
  const result = await orderService.checkout(req.user.id, req.body);
  return created(res, result);
});

/** GET /api/orders — đơn của tôi (người mua). ?status=pending|... */
export const listMine = asyncHandler(async (req, res) => {
  const result = await orderService.listMyOrders(req.user.id, req.query.status);
  return ok(res, result);
});

/** GET /api/orders/shop — đơn của shop tôi (người bán). */
export const listShop = asyncHandler(async (req, res) => {
  const result = await orderService.listShopOrders(req.user.id, req.query.status);
  return ok(res, result);
});

/** GET /api/orders/:id — chi tiết đơn. */
export const detail = asyncHandler(async (req, res) => {
  const result = await orderService.getOrderDetail(req.user.id, Number(req.params.id));
  return ok(res, result);
});

/** Các hành động đổi trạng thái. */
const action = (name) =>
  asyncHandler(async (req, res) => {
    const result = await orderService.changeStatus(req.user.id, Number(req.params.id), name);
    return ok(res, result);
  });

export const confirm = action('confirm');
export const ship = action('ship');
export const reject = action('reject');
export const cancel = action('cancel');
export const received = action('received');
