/**
 * Upload ảnh: nhận 1 file ảnh, lưu vào thư mục public/uploads,
 * trả về đường dẫn công khai để dùng làm ảnh sản phẩm.
 *
 * POST /api/uploads   (cần đăng nhập)
 *   - form-data, field tên "image"
 *   - trả về { url: "http://<host>/uploads/<tên-file>" }
 *
 * Ảnh lưu trong public/ nên được phục vụ tĩnh sẵn (xem app.js).
 */
import multer from 'multer';
import { randomBytes } from 'node:crypto';
import { extname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import { Router } from 'express';

import { authRequired } from '../../middlewares/auth.middleware.js';
import { AppError } from '../../utils/AppError.js';
import { ok } from '../../utils/response.js';

const __dirname = dirname(fileURLToPath(import.meta.url));
const uploadDir = join(__dirname, '..', '..', '..', 'public', 'uploads');

// Chỉ nhận ảnh, tối đa 5MB.
const ALLOWED = ['image/jpeg', 'image/png', 'image/webp', 'image/gif'];

const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, uploadDir),
  filename: (req, file, cb) => {
    const name = `${Date.now()}-${randomBytes(6).toString('hex')}${extname(file.originalname).toLowerCase()}`;
    cb(null, name);
  },
});

const upload = multer({
  storage,
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB
  fileFilter: (req, file, cb) => {
    if (ALLOWED.includes(file.mimetype)) cb(null, true);
    else cb(new AppError(400, 'Chỉ chấp nhận ảnh JPG, PNG, WEBP hoặc GIF'));
  },
});

const router = Router();

router.post('/', authRequired, (req, res, next) => {
  upload.single('image')(req, res, (err) => {
    if (err) {
      // Lỗi dung lượng của multer
      if (err.code === 'LIMIT_FILE_SIZE') return next(new AppError(400, 'Ảnh quá lớn (tối đa 5MB)'));
      return next(err);
    }
    if (!req.file) return next(new AppError(400, 'Chưa chọn file ảnh'));

    // Tạo URL công khai theo host của request (localhost, 10.0.2.2, IP LAN...).
    const url = `${req.protocol}://${req.get('host')}/uploads/${req.file.filename}`;
    return ok(res, { url });
  });
});

export default router;
