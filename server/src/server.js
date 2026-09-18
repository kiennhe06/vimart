/**
 * Điểm khởi chạy backend.
 * - Tạo HTTP server từ Express app.
 * - Kiểm tra kết nối database trước khi mở cổng.
 * Chạy: npm run dev  (hoặc npm start)
 */
import { createApp } from './app.js';
import { env } from './config/env.js';
import { pool } from './db/pool.js';

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
  app.listen(env.port, () => {
    console.log(`🚀 ViMart server chạy tại http://localhost:${env.port}`);
    console.log(`   Health check: http://localhost:${env.port}/health`);
  });
}

start();
