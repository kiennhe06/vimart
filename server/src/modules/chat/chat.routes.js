/** Chat — REST (lưu & đọc). Đẩy real-time qua WebSocket khi gửi tin. */
import { Router } from 'express';
import { z } from 'zod';
import { authRequired } from '../../middlewares/auth.middleware.js';
import { validate } from '../../middlewares/validate.middleware.js';
import { asyncHandler } from '../../utils/asyncHandler.js';
import { ok, created } from '../../utils/response.js';
import {
  getOrCreateConversation,
  listConversations,
  getConversation,
  listMessages,
  sendMessage,
  unreadTotal,
} from './chat.service.js';
import { pushToUser, pushToAdmins } from './chat.ws.js';

const router = Router();
router.use(authRequired);

/** GET /api/chat/conversations — danh sách hội thoại của tôi. */
router.get(
  '/conversations',
  asyncHandler(async (req, res) => ok(res, await listConversations(req.user.id)))
);

/** GET /api/chat/unread-count — tổng tin chưa đọc (badge). */
router.get(
  '/unread-count',
  asyncHandler(async (req, res) => ok(res, { count: await unreadTotal(req.user.id) }))
);

/** POST /api/chat/conversations — người mua mở/tạo hội thoại với 1 shop. Body: { shopId } */
router.post(
  '/conversations',
  validate(z.object({ shopId: z.number().int() })),
  asyncHandler(async (req, res) =>
    created(res, await getOrCreateConversation(req.user.id, req.body.shopId))
  )
);

/** GET /api/chat/conversations/:id — chi tiết 1 hội thoại. */
router.get(
  '/conversations/:id',
  asyncHandler(async (req, res) =>
    ok(res, await getConversation(Number(req.params.id), req.user.id))
  )
);

/** GET /api/chat/conversations/:id/messages — tin nhắn (đánh dấu đã đọc). */
router.get(
  '/conversations/:id/messages',
  asyncHandler(async (req, res) =>
    ok(res, await listMessages(Number(req.params.id), req.user.id))
  )
);

/** POST /api/chat/conversations/:id/messages — gửi tin + đẩy WS cho phía nhận. */
router.post(
  '/conversations/:id/messages',
  validate(z.object({ body: z.string().trim().min(1).max(2000) })),
  asyncHandler(async (req, res) => {
    const { message, recipientId } = await sendMessage(
      Number(req.params.id),
      req.user.id,
      req.body.body
    );
    // Đẩy real-time cho phía nhận + mọi admin đang trực chat trên web.
    pushToUser(recipientId, { type: 'message', message });
    pushToAdmins({ type: 'message', message });
    return created(res, message);
  })
);

export default router;
