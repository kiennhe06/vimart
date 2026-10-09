# Git Workflow — ViMart

Quy trình Git an toàn cho repo này. Skill tương ứng: `.claude/skills/git-workflow/`.

- **Remote:** `origin` → https://github.com/kiennhe06/vimart.git
- **Nhánh chính:** `main`
- **Hook:** `.githooks/pre-commit`, `.githooks/pre-push` (đã bật trong repo)

## 1. Kiểm tra trước khi commit

```bash
git branch --show-current
git remote -v
git status --short
git diff
```

- Chỉ `git add` đúng file thuộc thay đổi hiện tại — KHÔNG `git add .` mù.
- Phân biệt thay đổi của người dùng vs do AI tạo; không gộp lẫn.
- File hay bị công cụ tự sửa → revert nếu không chủ ý:
  - `analysis_options.yaml` (bị `flutter analyze` thêm exclude mỗi lần chạy)
  - `ios/Runner.xcodeproj/project.pbxproj` (bị `flutter build` chỉnh)

## 2. Không được commit

Đã ignore trong `.gitignore`: `server/node_modules/`, `/build/`, `.dart_tool/`,
`/coverage/`, `.DS_Store`, `.idea/`, `*.iml`, `*.log`.

**Tuyệt đối không commit:** `.env` thật, API key, mật khẩu, token, chứng chỉ.
Chỉ các file mẫu được track: `server/.env.example`, `server/.env.test.example`.

## 3. Commit message — Conventional Commits (tiếng Anh)

```
<type>(<scope>): <mô tả ngắn>

[nội dung chi tiết tùy chọn]
```

`type`: `feat | fix | docs | style | refactor | perf | test | chore | ci`.
Mỗi commit một thay đổi logic.

Ví dụ thật trong repo:
- `feat(cart): per-item selection for checkout (Shopee-style)`
- `fix(admin-web): stop caching static assets (stale app.js)`
- `feat(admin-chat): real-time unread badge + toast across all tabs`

## 4. Nhánh, push, PR

```bash
# tạo nhánh mới cho thay đổi (không commit thẳng main)
git checkout -b feat/<mô-tả-ngắn>
git push -u origin feat/<mô-tả-ngắn>
gh pr create --base main --head feat/<mô-tả-ngắn> --title "..." --body "..."
```

**Gộp vào main (lưu ý repo này):** `gh pr merge` bị chặn bởi classifier auto-mode
("Merge Without Review"). Gộp bằng local:

```bash
git checkout main
git merge --no-ff feat/<nhánh>
git push
git branch -d feat/<nhánh>          # xóa nhánh đã merge
git push origin --delete feat/<nhánh>
```

## 5. Tuyệt đối không (khi chưa được đồng ý rõ ràng)

- `git push --force` lên `main`/`master`
- `git reset --hard` trên nhánh chung
- Xóa branch / ghi đè lịch sử / revert thay đổi của người khác

## 6. Xác minh sau commit/push

```bash
git log --oneline -3
git status
```

Không tuyên bố "đã push thành công" nếu chưa xác minh bằng lệnh.
