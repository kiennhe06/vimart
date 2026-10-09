---
name: git-workflow
description: >-
  Quy trình Git an toàn cho ViMart. Dùng khi chuẩn bị commit/push, kiểm tra
  branch/diff/status, viết commit message, hoặc khi người dùng nhờ "commit",
  "push", "tạo PR". Kiểm tra kỹ trước khi commit; phân biệt thay đổi của người
  dùng với của AI; KHÔNG commit secrets/build/.env; commit message theo
  Conventional Commits; chỉ push đúng branch/remote khi được phép; KHÔNG force
  push / reset --hard / xóa branch khi chưa được đồng ý; xác minh sau khi push.
---

# Git Workflow — ViMart

Chi tiết đầy đủ: `docs/GIT_WORKFLOW.md`. Tóm tắt thao tác:

## 1. Trước khi commit (kiểm tra)

```bash
git branch --show-current      # đang ở branch nào?
git remote -v                  # đúng remote? (origin = kiennhe06/vimart)
git status --short             # file nào đổi / chưa track?
git diff                       # xem thay đổi đã staged/chưa
```

- **Phân biệt** thay đổi của người dùng vs do AI tạo. KHÔNG `git add .` mù;
  chỉ `git add` đúng các file liên quan tới thay đổi hiện tại.
- Repo auto-sửa `analysis_options.yaml` mỗi lần `flutter analyze` → `git checkout --
  analysis_options.yaml` nếu không chủ ý đổi. `ios/Runner.xcodeproj/project.pbxproj`
  bị `flutter build` đổi → revert nếu không liên quan.

## 2. KHÔNG commit (đã có trong `.gitignore`)

Secrets/`.env`, `server/node_modules/`, `/build/`, `.dart_tool/`, `/coverage/`,
`.DS_Store`, file IDE (`.idea/`, `*.iml`). **Chỉ** `*.env.example` được track —
KHÔNG bao giờ commit `.env` thật, API key, mật khẩu, token.

## 3. Commit message — Conventional Commits (tiếng Anh)

`<type>(<scope>): <mô tả ngắn>` — type: `feat|fix|docs|style|refactor|perf|test|chore|ci`.
Mỗi commit một thay đổi logic. Ví dụ: `feat(cart): per-item selection for checkout`.

## 4. Branch & push

- KHÔNG commit thẳng `main`/`master`. Làm trên nhánh `feat/...`, `fix/...`.
- Push: `git push -u origin <branch>` — xác nhận đúng branch + remote trước.
- Tạo PR bằng `gh pr create --base main --head <branch>`.
- **Lưu ý repo này:** `gh pr merge` bị chặn bởi classifier auto-mode
  ("Merge Without Review"). Gộp bằng local: `git checkout main && git merge --no-ff
  <branch> && git push`, rồi xóa branch đã merge.

## 5. TUYỆT ĐỐI KHÔNG (khi chưa có đồng ý rõ ràng)

- `git push --force` lên `main`/`master`; `git reset --hard` trên nhánh chung.
- Xóa/ghi đè/revert thay đổi chưa được phép; xóa branch; ghi đè lịch sử.

## 6. Có `.githooks` (pre-commit, pre-push)

Repo dùng hook ở `.githooks/`. Nếu hook chặn commit/push → đọc output, sửa
nguyên nhân (lint/format/test), KHÔNG dùng `--no-verify` để né nếu không được phép.

## 7. Sau commit/push — xác minh

```bash
git log --oneline -3     # commit đã vào chưa?
git status               # sạch chưa?
```

KHÔNG tuyên bố "đã push thành công" khi chưa xác minh được bằng lệnh.
