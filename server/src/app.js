/**
 * Cấu hình Express app: middleware chung + phục vụ web tĩnh + gắn API + xử lý lỗi.
 * File này KHÔNG tự chạy server (việc đó ở server.js) để dễ test.
 */
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

import { env } from './config/env.js';
import { notFound, errorHandler } from './middlewares/error.middleware.js';
import apiRouter from './routes.js';

const __dirname = dirname(fileURLToPath(import.meta.url));
// Thư mục chứa website tĩnh (HTML/CSS/JS): server/public
const publicDir = join(__dirname, '..', 'public');

export function createApp() {
  const app = express();

  // --- Middleware chung ---
  // Tắt CSP để trang web tĩnh tải được ảnh ngoài (picsum) + file JS/CSS nội bộ.
  app.use(helmet({ contentSecurityPolicy: false }));
  app.use(cors()); // cho phép app Flutter gọi từ domain khác
  app.use(express.json({ limit: '2mb' })); // đọc body dạng JSON
  if (env.nodeEnv !== 'test') app.use(morgan('dev')); // log request ra console

  // --- Kiểm tra sức khỏe server ---
  app.get('/health', (req, res) => {
    res.json({ success: true, data: { status: 'ok', time: new Date().toISOString() } });
  });

  // --- API đặt dưới /api (ưu tiên trước file tĩnh) ---
  app.use('/api', apiRouter);

  // --- Website bán hàng (HTML/CSS/JS) phục vụ từ thư mục public ---
  // Mở http://localhost:4100/ sẽ ra trang web (index.html).
  app.use(express.static(publicDir));

  // --- Route không tồn tại + xử lý lỗi (đặt cuối cùng) ---
  app.use(notFound);
  app.use(errorHandler);

  return app;
}
