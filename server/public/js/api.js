/* ============================================================
   api.js — Lớp gọi API dùng chung cho web store.
   - Tự gắn token đăng nhập (lưu trong localStorage).
   - Bóc lớp vỏ { success, data }, chỉ trả về phần data.
   - Lỗi -> ném Error với message tiếng Việt từ server.
   ============================================================ */

const TOKEN_KEY = 'vimart_token';

const Api = {
  base: '/api',

  getToken() {
    return localStorage.getItem(TOKEN_KEY);
  },
  setToken(token) {
    if (token) localStorage.setItem(TOKEN_KEY, token);
    else localStorage.removeItem(TOKEN_KEY);
  },

  /** Gọi request chung. */
  async request(method, path, body) {
    const headers = { 'Content-Type': 'application/json' };
    const token = this.getToken();
    if (token) headers['Authorization'] = `Bearer ${token}`;

    let res;
    try {
      res = await fetch(this.base + path, {
        method,
        headers,
        body: body ? JSON.stringify(body) : undefined,
      });
    } catch (e) {
      throw new Error('Không kết nối được máy chủ. Kiểm tra backend đã chạy chưa.');
    }

    let json = {};
    try {
      json = await res.json();
    } catch (_) {
      /* body rỗng */
    }

    if (!res.ok || json.success === false) {
      throw new Error(json.message || `Lỗi ${res.status}`);
    }
    return json.data;
  },

  /** Upload 1 file ảnh (multipart), trả về URL công khai. */
  async uploadImage(file) {
    const fd = new FormData();
    fd.append('image', file);
    const headers = {};
    const token = this.getToken();
    if (token) headers['Authorization'] = `Bearer ${token}`;

    const res = await fetch(this.base + '/uploads', { method: 'POST', headers, body: fd });
    let json = {};
    try {
      json = await res.json();
    } catch (_) {}
    if (!res.ok || json.success === false) throw new Error(json.message || 'Tải ảnh thất bại');
    return json.data.url;
  },

  get(path) {
    return this.request('GET', path);
  },
  post(path, body) {
    return this.request('POST', path, body);
  },
  put(path, body) {
    return this.request('PUT', path, body);
  },
  del(path, body) {
    return this.request('DELETE', path, body);
  },
};
