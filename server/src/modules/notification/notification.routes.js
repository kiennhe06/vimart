/** Thông báo — của người dùng đang đăng nhập. */
import { Router } from 'express';
import { authRequired } from '../../middlewares/auth.middleware.js';
import { asyncHandler } from '../../utils/asyncHandler.js';
import { ok } from '../../utils/response.js';
import { AppError } from '../../utils/AppError.js';
import {
  listNotifications,
  unreadCount,
  markRead,
  markAllRead,
} from './notification.service.js';

const router = Router();
router.use(authRequired);

/** GET /api/notifications — danh sách thông báo. */
router.get(
  '/',
  asyncHandler(async (req, res) => ok(res, await listNotifications(req.user.id)))
);

/** GET /api/notifications/unread-count — số chưa đọc. */
router.get(
  '/unread-count',
  asyncHandler(async (req, res) => ok(res, { count: await unreadCount(req.user.id) }))
);

/** PUT /api/notifications/read-all — đánh dấu tất cả đã đọc. */
router.put(
  '/read-all',
  asyncHandler(async (req, res) => {
    await markAllRead(req.user.id);
    return ok(res, { message: 'Đã đánh dấu tất cả đã đọc' });
  })
);

/** PUT /api/notifications/:id/read — đánh dấu 1 thông báo đã đọc. */
router.put(
  '/:id/read',
  asyncHandler(async (req, res) => {
    const okRead = await markRead(req.user.id, Number(req.params.id));
    if (!okRead) throw new AppError(404, 'Không tìm thấy thông báo');
    return ok(res, { id: Number(req.params.id), isRead: true });
  })
);

export default router;
