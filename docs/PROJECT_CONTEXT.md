# Project Context — ViMart

Điểm vào nhanh cho AI/người mới. KHÔNG lặp lại nội dung — trỏ tới tài liệu gốc.

## Mục đích

Sàn TMĐT nhiều shop (kiểu Shopee): người mua tìm hàng → giỏ → đặt → thanh toán →
shop xử lý đơn → nhận hàng → đánh giá. Chi tiết luồng: `docs/README.md`.

## Kiến trúc 3 phần

1. **Mobile app** — Flutter (người mua + người bán).
2. **Backend API** — Node.js + Express (ESM) + PostgreSQL, cổng **4100**.
3. **Web admin** — SPA tĩnh (HTML/CSS/JS) phục vụ từ backend tại `http://localhost:4100`.

Sơ đồ & giải thích: `docs/ARCHITECTURE.md`. Vai trò từng file/thư mục: `docs/FILE_GUIDE.md`.

## Công nghệ (xác minh từ `pubspec.yaml`, `server/package.json`)

- **Flutter:** flutter_riverpod, go_router, dio, shared_preferences, intl,
  flutter_svg, web_socket_channel, url_launcher, image_picker, cupertino_icons.
- **Backend:** express 5, pg, zod, jsonwebtoken, bcryptjs, ws, multer, helmet,
  cors, morgan, dotenv (dev: `node --watch`).
- **Test:** flutter_test (mobile); node:test + Postgres `vimart_test` (backend).

## Cấu trúc thư mục (rút gọn)

```
lib/        app/ (theme,design,motion,router) · core/ (api,i18n,format,providers)
            models/ · features/<feature>/ · widgets/ (dùng chung)
server/     src/app.js · src/server.js · src/modules/<feature>/(routes,controller,service,schema)
            src/{middlewares,utils,db,config} · public/ (web admin: index.html, js/app.js, css/styles.css)
assets/     icons/{categories,nav,ui}/ (sticker SVG)
docs/       tài liệu (xem bên dưới) · test/ (flutter) · server/test/ (backend)
```

## Bản đồ tài liệu (nguồn sự thật)

| Chủ đề | File |
|---|---|
| Tổng quan sản phẩm | `docs/README.md` |
| Kiến trúc | `docs/ARCHITECTURE.md` |
| Vai trò file/thư mục | `docs/FILE_GUIDE.md` |
| Design tokens (DUY NHẤT) | `docs/DESIGN_SYSTEM.md` |
| Motion / interaction | `docs/MOTION.md` |
| Quyết định kỹ thuật | `docs/DECISIONS.md` (+ `docs/TECHNICAL_DECISIONS.md`) |
| Trạng thái hiện tại | `docs/PROJECT_STATUS.md` |
| Tiến độ (lịch sử) | `docs/PROGRESS.md` |
| Hướng mở rộng | `docs/FUTURE.md` |
| Triển khai | `docs/DEPLOY.md` |
| Quy trình Git | `docs/GIT_WORKFLOW.md` |

## Skills dùng lại (`.claude/skills/`)

`project-memory` · `project-development` · `git-workflow` · `testing-and-review` ·
`ui-ux-pro-max` (design intelligence sẵn có).

## Quy ước cốt lõi

Giao tiếp tiếng Việt, code/commit tiếng Anh · i18n vi/en · config qua env, không
hardcode secret · 4 trạng thái cho mọi màn async · tái dùng component/token.
