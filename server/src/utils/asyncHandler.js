/**
 * Bọc một hàm controller async để tự động bắt lỗi và chuyển sang error middleware.
 * Nhờ vậy không phải viết try/catch lặp lại trong từng controller.
 *
 * Dùng: router.get('/', asyncHandler(async (req, res) => { ... }))
 */
export const asyncHandler = (fn) => (req, res, next) => {
  Promise.resolve(fn(req, res, next)).catch(next);
};
