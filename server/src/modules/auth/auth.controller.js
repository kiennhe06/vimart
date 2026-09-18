/** Nhận request, gọi service, trả response. Không chứa logic nghiệp vụ phức tạp. */
import { asyncHandler } from '../../utils/asyncHandler.js';
import { ok, created } from '../../utils/response.js';
import * as authService from './auth.service.js';

export const register = asyncHandler(async (req, res) => {
  const result = await authService.register(req.body);
  return created(res, result);
});

export const login = asyncHandler(async (req, res) => {
  const result = await authService.login(req.body);
  return ok(res, result);
});

export const me = asyncHandler(async (req, res) => {
  const result = await authService.getMe(req.user.id);
  return ok(res, result);
});

export const changePassword = asyncHandler(async (req, res) => {
  await authService.changePassword(req.user.id, req.body);
  return ok(res, { message: 'Đổi mật khẩu thành công' });
});
