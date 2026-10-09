---
name: project-development
description: >-
  Quy tắc tiếp tục phát triển ViMart. Dùng khi thêm/sửa tính năng, tạo màn hình
  hoặc API mới, sửa bug, hoặc chỉnh UI. Đọc tài liệu + code liên quan trước khi
  sửa; tuân thủ kiến trúc, coding convention, design system và motion hiện có;
  TÁI SỬ DỤNG component/token thay vì viết trùng; phân tích nguyên nhân trước khi
  vá bug; giữ thay đổi tập trung, không refactor thừa.
---

# Project Development — ViMart

## 0. Trước khi sửa code (bắt buộc)

1. Đọc tài liệu liên quan trong `docs/` (xem skill `project-memory`).
2. Mở code đang có cùng khu vực để theo đúng pattern — KHÔNG đoán.
3. Kiểm tra component/widget/endpoint đã tồn tại chưa (tránh viết lại).

## 1. Coding convention (theo CLAUDE.md của người dùng)

- Giao tiếp/giải thích **tiếng Việt**; code, tên biến, comment, commit **tiếng Anh**.
- Code sạch, rõ ràng > thông minh; đặt tên có nghĩa; DRY; hàm ngắn, 1 việc.
- Xử lý lỗi rõ ràng, KHÔNG nuốt lỗi; không `any` TS vô cớ.
- Config qua biến môi trường, KHÔNG hardcode secrets.
- Có i18n vi/en cho chuỗi UI (`lib/core/i18n/app_strings.dart`).

## 2. Mobile (Flutter) — xem `docs/ARCHITECTURE.md`, `docs/FILE_GUIDE.md`

- Tổ chức **theo tính năng**: `lib/features/<feature>/` gồm
  `<feature>_screen.dart` + `<feature>_provider.dart` + `<feature>_repository.dart`
  (+ `widgets/`). Tách UI ↔ logic ↔ truy cập dữ liệu.
- State: **Riverpod** (`AsyncNotifier` cho dữ liệu server, `Notifier` cho state
  cục bộ). Điều hướng: **go_router** named routes (`lib/app/router.dart`). API:
  **Dio** qua `lib/core/api/api_client.dart`.
- `const` ở mọi nơi có thể; `dispose()` controller/stream; tách widget con khi phức tạp.
- **4 trạng thái** mọi màn async: loading (skeleton) / error (nút thử lại) /
  empty / data — dùng `lib/widgets/async_view.dart`.
- **Tái dùng widget chung** (`lib/widgets/`): `StickerIcon`, `Pressable`,
  `AsyncView/Empty/Error`, `showAppSnack`, `app_dialog`, `FadeSlideIn`,
  `NetworkImageBox`, `RollingNumber`, skeleton. ĐỪNG tạo bản trùng.
- **Visual/motion:** chỉ dùng token trong `lib/app/theme.dart` + `design.dart`
  (`context.c.*`) và `lib/app/motion.dart` (`AppMotion.dur(context, ...)` —
  tôn trọng reduced-motion). Nguồn gốc: `docs/DESIGN_SYSTEM.md`, `docs/MOTION.md`.
- **Icon:** thêm sticker SVG vào `assets/icons/...` + render bằng `StickerIcon`.
  Hiệu ứng chỉ dùng gradient + stroke + opacity (KHÔNG filter blur — flutter_svg
  không render được). Khai báo thư mục assets trong `pubspec.yaml`.

## 3. Backend (Node/Express ESM) — xem `docs/ARCHITECTURE.md`

- Phân lớp: `modules/<feature>/<feature>.routes.js` → `.controller.js` →
  `.service.js` (logic + SQL) → `.schema.js` (zod). Thêm tính năng = thêm 1 module.
- Validate input bằng **zod** ở `validate.middleware.js`; auth bằng
  `authRequired` / `adminOnly`; lỗi bằng `AppError(status, msg)`.
- Response **đồng nhất** qua `utils/response.js` (`ok` / `created`); KHÔNG lộ stack.
- Ghi nhiều bảng → bọc `withTransaction` (`db/pool.js`) + khóa dòng khi cần.
- Real-time: WebSocket `/ws?token=<JWT>` (`modules/chat/chat.ws.js`,
  `pushToUser` / `pushToAdmins`).
- JWT payload = `{ id, role }`. DB: SQL thuần (`pg`), KHÔNG ORM. Cổng **4100**.

## 4. Web admin (SPA tĩnh) — `server/public/`

- Vanilla HTML/CSS/JS, hash routing, render qua `app.innerHTML`. Nav gom nhóm
  (dropdown `<details name>`). Sửa `app.js` / `styles.css` rồi **bump `?v=` trong
  `index.html`**. Tĩnh phục vụ với `Cache-Control: no-store` (dev).

## 5. Sửa bug

1. Tái hiện + xác định nguyên nhân gốc TRƯỚC khi vá (xem skill `testing-and-review`).
2. Vá đúng chỗ, tập trung; không refactor kèm nếu không cần.
3. Nếu lỗi dễ tái diễn → ghi lại ở `docs/PROJECT_STATUS.md` (mục lỗi đã sửa).

## 6. Sau khi sửa

- Cập nhật tài liệu nếu kiến trúc/hành vi đổi (skill `project-memory`).
- Chạy kiểm tra phù hợp (skill `testing-and-review`) trước khi nói "đã xong".
