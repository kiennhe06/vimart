/**
 * Middleware validate dữ liệu đầu vào bằng Zod schema.
 * Nếu dữ liệu sai, Zod ném lỗi -> error middleware trả 400 kèm mô tả.
 *
 * Dùng: router.post('/', validate(createProductSchema), controller)
 * Sau khi qua middleware này, dùng req.body đã được "làm sạch" (đúng kiểu).
 */
export const validate = (schema) => (req, res, next) => {
  try {
    req.body = schema.parse(req.body);
    next();
  } catch (err) {
    next(err); // ZodError sẽ được error middleware xử lý
  }
};

/** Validate query string (?page=1&keyword=...). */
export const validateQuery = (schema) => (req, res, next) => {
  try {
    req.validatedQuery = schema.parse(req.query);
    next();
  } catch (err) {
    next(err);
  }
};
