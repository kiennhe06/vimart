# ViMart — nguồn lệnh DUY NHẤT cho local lẫn CI (local == CI).
# CI (.github/workflows/ci.yml) và git hook (.githooks/*) đều gọi các target dưới đây.
#
# DB test dùng `vimart_test` (tách khỏi DB dev). DATABASE_URL có thể ghi đè qua biến môi
# trường (CI đặt trỏ tới Postgres service); mặc định dùng Postgres Homebrew của máy.

SHELL := /bin/bash
DATABASE_URL ?= postgres://$(shell whoami)@localhost:5432/vimart_test
JWT_SECRET ?= test-secret
export DATABASE_URL JWT_SECRET

.PHONY: setup install hooks \
        be-lint be-format be-format-check be-test \
        app-analyze app-format app-format-check app-test \
        lint format format-check test check \
        db-up db-down db-reset db-reset-test help

help: ## Liệt kê các lệnh
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
	  awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}'

## ---------- Thiết lập ----------
setup: install hooks ## Cài deps 2 phía + bật git hook

install: ## Cài dependencies backend + Flutter
	cd server && npm ci
	flutter pub get

hooks: ## Bật git hook (chạy 1 lần / máy)
	git config core.hooksPath .githooks
	@echo "✅ Git hooks đã bật (core.hooksPath=.githooks)"

## ---------- Backend (server/) ----------
be-lint: ## ESLint backend + web admin
	cd server && npm run lint

be-format: ## Prettier ghi đè backend + web admin
	cd server && npm run format

be-format-check: ## Kiểm tra format backend
	cd server && npm run format:check

be-test: ## Test backend (node:test + Postgres, DB vimart_test)
	@createdb vimart_test 2>/dev/null || true
	cd server && NODE_ENV=test npm test

## ---------- Flutter (lib/, test/) ----------
app-analyze: ## flutter analyze
	flutter analyze

app-format: ## dart format thư mục test/
	dart format test/

app-format-check: ## Kiểm tra dart format thư mục test/
	dart format --output=none --set-exit-if-changed test/

app-test: ## flutter test
	flutter test

## ---------- Tổng hợp (dùng ở local) ----------
lint: be-lint app-analyze ## Lint cả 2 phía
format: be-format app-format ## Format cả 2 phía
format-check: be-format-check app-format-check ## Kiểm tra format cả 2 phía
test: be-test app-test ## Test cả 2 phía
check: format-check lint test ## Cổng chất lượng đầy đủ (giống CI)

## ---------- Database ----------
db-up: ## Postgres qua Docker (tùy chọn, cần Docker)
	docker compose up -d db

db-down: ## Tắt Postgres Docker
	docker compose down

db-reset: ## Tạo lại + seed DB dev
	cd server && npm run db:reset

db-reset-test: ## Tạo + seed DB test (vimart_test)
	@createdb vimart_test 2>/dev/null || true
	cd server && NODE_ENV=test npm run db:reset
