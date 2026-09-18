/**
 * Tạo (hoặc tạo lại) toàn bộ bảng trong database bằng cách chạy file schema.sql.
 * Chạy: npm run db:migrate
 */
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import { pool } from './pool.js';

const __dirname = dirname(fileURLToPath(import.meta.url));

async function migrate() {
  const sql = readFileSync(join(__dirname, 'schema.sql'), 'utf8');
  console.log('⏳ Đang tạo bảng từ schema.sql...');
  await pool.query(sql);
  console.log('✅ Tạo bảng xong.');
  await pool.end();
}

migrate().catch((error) => {
  console.error('❌ Lỗi migrate:', error.message);
  process.exit(1);
});
