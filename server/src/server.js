/**
 * Điểm khởi chạy backend.
 * - Tạo HTTP server từ Express app.
 * - Kiểm tra kết nối database trước khi mở cổng.
 * Chạy: npm run dev  (hoặc npm start)
 */
import { createServer } from 'node:http';
import { createApp } from './app.js';
import { env } from './config/env.js';
import { pool } from './db/pool.js';
import { attachChatWebSocket } from './modules/chat/chat.ws.js';

async function start() {
  // Kiểm tra database có kết nối được không (fail sớm nếu sai cấu hình)
  try {
    await pool.query('SELECT 1');
    console.log('✅ Kết nối PostgreSQL thành công');
  } catch (error) {
    console.error('❌ Không kết nối được database:', error.message);
    console.error('   → Kiểm tra DATABASE_URL trong file .env và PostgreSQL đã chạy chưa.');
    process.exit(1);
  }

  const app = createApp();
  const server = createServer(app);
  // WebSocket cho chat real-time (path /ws).
  attachChatWebSocket(server);
  server.listen(env.port, () => {
    console.log(`🚀 ViMart server chạy tại http://localhost:${env.port}`);
    console.log(`   Health check: http://localhost:${env.port}/health`);
    console.log(`   WebSocket chat: ws://localhost:${env.port}/ws`);
  });
}

start();
