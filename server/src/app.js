/**
 * Cấu hình Express app: middleware chung + gắn tất cả routes + xử lý lỗi.
 * File này KHÔNG tự chạy server (việc đó ở server.js) để dễ test.
 */
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';

import { env } from './config/env.js';
import { notFound, errorHandler } from './middlewares/error.middleware.js';
import apiRouter from './routes.js';

export function createApp() {
  const app = express();

  // --- Middleware chung ---
  app.use(helmet()); // thêm các header bảo mật cơ bản
  app.use(cors()); // cho phép app Flutter gọi từ domain khác
  app.use(express.json({ limit: '2mb' })); // đọc body dạng JSON
  if (env.nodeEnv !== 'test') app.use(morgan('dev')); // log request ra console

  // --- Kiểm tra sức khỏe server ---
  app.get('/health', (req, res) => {
    res.json({ success: true, data: { status: 'ok', time: new Date().toISOString() } });
  });

  // --- Tất cả API đặt dưới /api ---
  app.use('/api', apiRouter);

  // --- Route không tồn tại + xử lý lỗi (đặt cuối cùng) ---
  app.use(notFound);
  app.use(errorHandler);

  return app;
}
