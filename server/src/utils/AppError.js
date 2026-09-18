/**
 * Lỗi nghiệp vụ có kèm mã HTTP.
 * Dùng để chủ động ném lỗi "có kiểm soát" (vd: 404 Không tìm thấy, 400 Dữ liệu sai)
 * thay vì để lỗi 500 chung chung.
 *
 * Ví dụ: throw new AppError(404, 'Không tìm thấy sản phẩm');
 */
export class AppError extends Error {
  /**
   * @param {number} statusCode - mã HTTP (400, 401, 403, 404, 409...)
   * @param {string} message - thông báo lỗi dễ hiểu cho người dùng
   */
  constructor(statusCode, message) {
    super(message);
    this.statusCode = statusCode;
    this.isOperational = true; // lỗi đã lường trước, không phải bug hệ thống
  }
}
