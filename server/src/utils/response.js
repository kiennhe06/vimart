/**
 * Hàm helper trả response theo một định dạng thống nhất cho toàn bộ API.
 * Nhờ vậy phía Flutter luôn biết trước cấu trúc dữ liệu nhận về.
 *
 * Thành công: { success: true, data: ... }
 * Thất bại:   { success: false, message: '...' }
 */

/** Trả về dữ liệu thành công. */
export function ok(res, data, statusCode = 200) {
  return res.status(statusCode).json({ success: true, data });
}

/** Trả về khi tạo mới thành công (201). */
export function created(res, data) {
  return ok(res, data, 201);
}

/** Trả về lỗi. */
export function fail(res, statusCode, message) {
  return res.status(statusCode).json({ success: false, message });
}
