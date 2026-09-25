/**
 * Chạy MỘT LẦN trước mỗi file test (nạp qua `node --test --import`).
 * Tạo lại schema + seed dữ liệu mẫu trên DB test để mỗi file bắt đầu sạch.
 *
 * AN TOÀN: từ chối chạy nếu DATABASE_URL không trỏ tới DB `vimart_test`
 * (seed.js DROP TABLE — tránh xóa nhầm dữ liệu dev).
 */
import { execFileSync } from 'node:child_process';

const url = process.env.DATABASE_URL || '';
if (!/vimart_test/i.test(url)) {
  throw new Error(
    `[test setup] TỪ CHỐI chạy test: DATABASE_URL phải trỏ tới DB "vimart_test".\n` +
      `Nhận được: "${url || '(trống)'}".\n` +
      `Dùng: make be-test  (hoặc đặt DATABASE_URL=...vimart_test NODE_ENV=test)`
  );
}

// Chạy seed ở process con để pool của nó tự đóng sạch, không ảnh hưởng pool của test.
execFileSync('node', ['src/db/seed.js'], { stdio: 'inherit', env: process.env });
