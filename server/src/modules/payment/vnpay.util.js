/**
 * Tiện ích ký & kiểm tra chữ ký VNPay (theo tài liệu sandbox VNPay 2.1.0).
 *
 * Ý tưởng: VNPay yêu cầu sắp xếp tham số theo tên (a-z), nối thành chuỗi,
 * rồi ký bằng HMAC-SHA512 với "hash secret". Khi VNPay báo kết quả về,
 * ta ký lại y hệt và so sánh -> chống việc giả mạo kết quả thanh toán.
 */
import crypto from 'node:crypto';

/** Sắp xếp key a-z và mã hóa value (dấu cách -> '+') giống mẫu chính thức của VNPay. */
function sortObject(obj) {
  const sorted = {};
  const keys = Object.keys(obj)
    .map((k) => encodeURIComponent(k))
    .sort();
  for (const key of keys) {
    sorted[key] = encodeURIComponent(obj[key]).replace(/%20/g, '+');
  }
  return sorted;
}

/** Nối object thành query string dạng k=v&k=v (value đã được mã hóa sẵn). */
function buildQuery(sorted) {
  return Object.entries(sorted)
    .map(([k, v]) => `${k}=${v}`)
    .join('&');
}

/** Ký dữ liệu bằng HMAC-SHA512. */
function sign(data, secret) {
  return crypto.createHmac('sha512', secret).update(Buffer.from(data, 'utf-8')).digest('hex');
}

/**
 * Tạo URL thanh toán VNPay.
 * @param {object} params - các tham số vnp_* (chưa có chữ ký)
 * @param {string} secret - hash secret
 * @param {string} vnpUrl - endpoint VNPay
 */
export function buildPaymentUrl(params, secret, vnpUrl) {
  const sorted = sortObject(params);
  const signData = buildQuery(sorted);
  sorted.vnp_SecureHash = sign(signData, secret);
  return `${vnpUrl}?${buildQuery(sorted)}`;
}

/**
 * Kiểm tra chữ ký khi VNPay báo kết quả về.
 * @param {object} query - toàn bộ query VNPay gửi về (gồm vnp_SecureHash)
 * @param {string} secret
 * @returns {boolean} true nếu chữ ký hợp lệ
 */
export function verifyReturn(query, secret) {
  const received = query.vnp_SecureHash;
  const clone = { ...query };
  delete clone.vnp_SecureHash;
  delete clone.vnp_SecureHashType;

  const sorted = sortObject(clone);
  const signData = buildQuery(sorted);
  const expected = sign(signData, secret);
  return expected === received;
}

/** Định dạng thời gian yyyyMMddHHmmss theo giờ VN (VNPay yêu cầu). */
export function formatDate(date = new Date()) {
  const parts = new Intl.DateTimeFormat('en-CA', {
    timeZone: 'Asia/Ho_Chi_Minh',
    year: 'numeric', month: '2-digit', day: '2-digit',
    hour: '2-digit', minute: '2-digit', second: '2-digit', hour12: false,
  }).formatToParts(date);
  const get = (t) => parts.find((p) => p.type === t).value;
  return `${get('year')}${get('month')}${get('day')}${get('hour')}${get('minute')}${get('second')}`;
}
