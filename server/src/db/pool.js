/**
 * Kết nối tới PostgreSQL bằng thư viện `pg`.
 * Dùng connection pool để tái sử dụng kết nối, không mở mới mỗi query.
 */
import pkg from 'pg';
import { env } from '../config/env.js';

const { Pool } = pkg;

export const pool = new Pool({ connectionString: env.databaseUrl });

/**
 * Chạy 1 câu SQL. Ví dụ: query('SELECT * FROM users WHERE id = $1', [id]).
 * @param {string} text - câu SQL, dùng $1, $2... cho tham số (chống SQL injection)
 * @param {any[]} [params] - danh sách giá trị thay cho $1, $2...
 */
export function query(text, params) {
  return pool.query(text, params);
}

/**
 * Chạy nhiều câu SQL trong 1 transaction.
 * Nếu 1 câu lỗi thì rollback toàn bộ (all-or-nothing).
 * Ví dụ dùng khi tạo đơn hàng: trừ kho + tạo đơn phải cùng thành công.
 * @param {(client: import('pg').PoolClient) => Promise<T>} callback
 * @returns {Promise<T>}
 * @template T
 */
export async function withTransaction(callback) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const result = await callback(client);
    await client.query('COMMIT');
    return result;
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}
