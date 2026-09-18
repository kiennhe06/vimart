import { asyncHandler } from '../../utils/asyncHandler.js';
import { ok, created } from '../../utils/response.js';
import * as userService from './user.service.js';

export const updateProfile = asyncHandler(async (req, res) => {
  const user = await userService.updateProfile(req.user.id, req.body);
  return ok(res, user);
});

export const listAddresses = asyncHandler(async (req, res) => {
  const list = await userService.listAddresses(req.user.id);
  return ok(res, list);
});

export const addAddress = asyncHandler(async (req, res) => {
  const address = await userService.addAddress(req.user.id, req.body);
  return created(res, address);
});

export const updateAddress = asyncHandler(async (req, res) => {
  const address = await userService.updateAddress(req.user.id, Number(req.params.id), req.body);
  return ok(res, address);
});

export const deleteAddress = asyncHandler(async (req, res) => {
  await userService.deleteAddress(req.user.id, Number(req.params.id));
  return ok(res, { message: 'Đã xóa địa chỉ' });
});
