---
name: project-memory
description: >-
  Bộ nhớ dự án ViMart. Dùng khi BẮT ĐẦU một phiên làm việc, khi cần hiểu kiến
  trúc / công nghệ / tính năng đã có / quyết định kỹ thuật / lỗi đã sửa trước khi
  đụng vào code, hoặc khi cần CẬP NHẬT tài liệu sau một thay đổi quan trọng. Đọc
  docs/ trước thay vì suy đoán; ưu tiên đường dẫn file + giải thích ngắn, không
  chép nguyên source vào bộ nhớ.
---

# Project Memory — ViMart

Mục tiêu: nắm nhanh dự án từ **tài liệu đã có** (không đọc mò toàn bộ code, không bịa).

## 1. Đọc trước khi làm (nguồn sự thật)

Tất cả nằm trong `docs/` — đọc đúng file theo nhu cầu, KHÔNG chép lại nội dung:

| Cần biết | Đọc file |
|---|---|
| Tổng quan sản phẩm, luồng mua–bán | `docs/README.md` |
| Kiến trúc 3 phần (mobile / backend / web admin) | `docs/ARCHITECTURE.md` |
| "File này để làm gì" — vai trò thư mục/file | `docs/FILE_GUIDE.md` |
| Design tokens (màu, spacing, radius, type) — NGUỒN DUY NHẤT | `docs/DESIGN_SYSTEM.md` |
| Ngôn ngữ chuyển động / micro-interaction | `docs/MOTION.md` |
| Quyết định kỹ thuật + lý do | `docs/DECISIONS.md` |
| Tiến độ (lịch sử) | `docs/PROGRESS.md` |
| Trạng thái hiện tại (mới nhất) | `docs/PROJECT_STATUS.md` |
| Context + mục lục tài liệu | `docs/PROJECT_CONTEXT.md` |
| Hướng mở rộng chưa làm | `docs/FUTURE.md` |
| Triển khai (Docker/Render) | `docs/DEPLOY.md` |
| Quy trình Git | `docs/GIT_WORKFLOW.md` |

Icon sticker 3D: thư mục `assets/icons/{categories,nav,ui}/`, render qua
`lib/widgets/sticker_icon.dart`.

## 2. Bản đồ code (để tìm nhanh, không cần nhớ chi tiết)

- **Mobile (Flutter):** `lib/app/` (theme/design/motion/router), `lib/core/`
  (api, i18n, format, providers), `lib/models/`, `lib/features/<feature>/`
  (screen + provider + repository + widgets), `lib/widgets/` (dùng chung).
- **Backend (Node/Express ESM):** `server/src/app.js`, `server/src/server.js`,
  `server/src/modules/<feature>/` (`.routes` → `.controller` → `.service` →
  `.schema`), `server/src/middlewares/`, `server/src/utils/`, `server/src/db/`.
- **Web admin (SPA tĩnh):** `server/public/index.html`, `server/public/js/app.js`,
  `server/public/css/styles.css` — phục vụ tĩnh từ backend tại `http://localhost:4100`.

## 3. Cập nhật bộ nhớ sau thay đổi quan trọng

Khi làm xong một thay đổi đáng kể (thêm tính năng, đổi kiến trúc, sửa bug lớn):

1. Thêm/điều chỉnh mục liên quan trong `docs/PROJECT_STATUS.md` (tính năng mới,
   trạng thái).
2. Nếu có quyết định kỹ thuật mới → ghi vào `docs/DECISIONS.md` (hoặc
   `docs/TECHNICAL_DECISIONS.md` cho quyết định phát sinh trong phiên).
3. Nếu đổi design token / motion → cập nhật `docs/DESIGN_SYSTEM.md` /
   `docs/MOTION.md` (đây là nguồn DUY NHẤT, không tạo bản sao).
4. Nếu lỗi có thể tái diễn → ghi nguyên nhân + cách sửa vào mục "lỗi đã sửa"
   của `docs/PROJECT_STATUS.md`.

## 4. Nguyên tắc

- **Phân loại thông tin:** (a) đã xác minh từ source, (b) đã xác minh từ Git
  history, (c) chưa xác minh → ghi rõ "chưa xác minh", không bịa để lấp chỗ trống.
- **Ưu tiên đường dẫn file + 1–2 câu giải thích**, không copy nguyên source vào docs.
- **Không ghi secrets** (API key, mật khẩu, token, nội dung `.env`) vào tài liệu.
- Repo hiện tại là `kiennhe06/vimart` — không trộn dữ liệu với dự án khác.
