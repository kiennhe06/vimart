-- ============================================================
-- ViMart database schema (PostgreSQL)
-- Chạy lại được nhiều lần: xoá bảng cũ rồi tạo lại (dev only).
-- ============================================================

DROP TABLE IF EXISTS reviews          CASCADE;
DROP TABLE IF EXISTS payments         CASCADE;
DROP TABLE IF EXISTS order_items      CASCADE;
DROP TABLE IF EXISTS orders           CASCADE;
DROP TABLE IF EXISTS cart_items       CASCADE;
DROP TABLE IF EXISTS favorites        CASCADE;
DROP TABLE IF EXISTS product_variants CASCADE;
DROP TABLE IF EXISTS products         CASCADE;
DROP TABLE IF EXISTS categories       CASCADE;
DROP TABLE IF EXISTS shops            CASCADE;
DROP TABLE IF EXISTS addresses        CASCADE;
DROP TABLE IF EXISTS users            CASCADE;

-- ---------- Người dùng ----------
CREATE TABLE users (
  id            SERIAL PRIMARY KEY,
  email         VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  full_name     VARCHAR(255) NOT NULL,
  phone         VARCHAR(20),
  role          VARCHAR(20)  NOT NULL DEFAULT 'customer'  -- 'customer' | 'admin'
                CHECK (role IN ('customer', 'admin')),
  is_active     BOOLEAN      NOT NULL DEFAULT TRUE,
  created_at    TIMESTAMPTZ  NOT NULL DEFAULT now()
);

-- ---------- Địa chỉ nhận hàng ----------
CREATE TABLE addresses (
  id             SERIAL PRIMARY KEY,
  user_id        INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  recipient_name VARCHAR(255) NOT NULL,
  phone          VARCHAR(20)  NOT NULL,
  line           VARCHAR(255) NOT NULL,   -- số nhà, tên đường
  ward           VARCHAR(120),
  district       VARCHAR(120),
  province       VARCHAR(120),
  is_default     BOOLEAN NOT NULL DEFAULT FALSE,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ---------- Shop (một người dùng mở tối đa 1 shop trong bản MVP) ----------
CREATE TABLE shops (
  id          SERIAL PRIMARY KEY,
  owner_id    INTEGER UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name        VARCHAR(255) NOT NULL,
  description TEXT,
  avatar_url  VARCHAR(500),
  status      VARCHAR(20) NOT NULL DEFAULT 'active'  -- 'active' | 'locked'
              CHECK (status IN ('active', 'locked')),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ---------- Danh mục ----------
CREATE TABLE categories (
  id        SERIAL PRIMARY KEY,
  name      VARCHAR(120) NOT NULL,
  slug      VARCHAR(140) UNIQUE NOT NULL,
  icon      VARCHAR(80)
);

-- ---------- Sản phẩm ----------
CREATE TABLE products (
  id           SERIAL PRIMARY KEY,
  shop_id      INTEGER NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
  category_id  INTEGER REFERENCES categories(id) ON DELETE SET NULL,
  name         VARCHAR(255) NOT NULL,
  description  TEXT,
  image_url    VARCHAR(500),
  status       VARCHAR(20) NOT NULL DEFAULT 'active'  -- 'active' | 'hidden'
               CHECK (status IN ('active', 'hidden')),
  sold_count   INTEGER NOT NULL DEFAULT 0,
  rating_avg   NUMERIC(2,1) NOT NULL DEFAULT 0,   -- 0.0 .. 5.0
  rating_count INTEGER NOT NULL DEFAULT 0,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_products_shop     ON products(shop_id);
CREATE INDEX idx_products_category ON products(category_id);

-- ---------- Phân loại sản phẩm (size/màu). Mỗi sản phẩm có >= 1 dòng. ----------
-- Giá và tồn kho luôn nằm ở đây để dữ liệu nhất quán.
CREATE TABLE product_variants (
  id         SERIAL PRIMARY KEY,
  product_id INTEGER NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  name       VARCHAR(120) NOT NULL DEFAULT 'Mặc định',  -- vd: "Đỏ / L"
  price      INTEGER NOT NULL CHECK (price >= 0),        -- đơn vị: VND
  stock      INTEGER NOT NULL DEFAULT 0 CHECK (stock >= 0)
);
CREATE INDEX idx_variants_product ON product_variants(product_id);

-- ---------- Yêu thích (wishlist) ----------
CREATE TABLE favorites (
  user_id    INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  product_id INTEGER NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, product_id)
);

-- ---------- Giỏ hàng (mỗi dòng là 1 phân loại + số lượng) ----------
CREATE TABLE cart_items (
  id         SERIAL PRIMARY KEY,
  user_id    INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  variant_id INTEGER NOT NULL REFERENCES product_variants(id) ON DELETE CASCADE,
  quantity   INTEGER NOT NULL CHECK (quantity > 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (user_id, variant_id)
);

-- ---------- Đơn hàng ----------
-- Một lần đặt có thể tách thành nhiều đơn (mỗi shop 1 đơn), nối bằng group_code.
CREATE TABLE orders (
  id             SERIAL PRIMARY KEY,
  code           VARCHAR(30) UNIQUE NOT NULL,   -- mã đơn hiển thị
  group_code     VARCHAR(30) NOT NULL,          -- nối các đơn cùng 1 lần thanh toán
  buyer_id       INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  shop_id        INTEGER NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
  -- Ảnh chụp địa chỉ tại thời điểm đặt (để sau này đổi địa chỉ không ảnh hưởng đơn cũ)
  recipient_name VARCHAR(255) NOT NULL,
  recipient_phone VARCHAR(20) NOT NULL,
  address_text   VARCHAR(600) NOT NULL,
  status         VARCHAR(20) NOT NULL DEFAULT 'pending'
                 CHECK (status IN ('pending','confirmed','shipping','completed','cancelled')),
  payment_method VARCHAR(20) NOT NULL DEFAULT 'cod'
                 CHECK (payment_method IN ('cod','vnpay')),
  payment_status VARCHAR(20) NOT NULL DEFAULT 'unpaid'
                 CHECK (payment_status IN ('unpaid','paid')),
  subtotal       INTEGER NOT NULL DEFAULT 0,
  shipping_fee   INTEGER NOT NULL DEFAULT 0,
  discount       INTEGER NOT NULL DEFAULT 0,
  total          INTEGER NOT NULL DEFAULT 0,
  note           VARCHAR(500),
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_orders_buyer ON orders(buyer_id);
CREATE INDEX idx_orders_shop  ON orders(shop_id);
CREATE INDEX idx_orders_group ON orders(group_code);

-- ---------- Chi tiết đơn (ảnh chụp thông tin lúc mua) ----------
CREATE TABLE order_items (
  id           SERIAL PRIMARY KEY,
  order_id     INTEGER NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  product_id   INTEGER REFERENCES products(id) ON DELETE SET NULL,
  variant_id   INTEGER REFERENCES product_variants(id) ON DELETE SET NULL,
  product_name VARCHAR(255) NOT NULL,
  variant_name VARCHAR(120) NOT NULL,
  image_url    VARCHAR(500),
  price        INTEGER NOT NULL,   -- giá tại thời điểm mua
  quantity     INTEGER NOT NULL,
  reviewed     BOOLEAN NOT NULL DEFAULT FALSE
);
CREATE INDEX idx_order_items_order ON order_items(order_id);

-- ---------- Thanh toán (theo dõi giao dịch VNPay) ----------
CREATE TABLE payments (
  id                  SERIAL PRIMARY KEY,
  group_code          VARCHAR(30) NOT NULL,
  amount              INTEGER NOT NULL,
  method              VARCHAR(20) NOT NULL,   -- 'vnpay' | 'cod'
  status              VARCHAR(20) NOT NULL DEFAULT 'pending'  -- 'pending'|'paid'|'failed'
                      CHECK (status IN ('pending','paid','failed')),
  vnp_txn_ref         VARCHAR(60),
  vnp_response_code   VARCHAR(10),
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_payments_group ON payments(group_code);

-- ---------- Đánh giá sản phẩm (chỉ sau khi đơn hoàn thành) ----------
CREATE TABLE reviews (
  id            SERIAL PRIMARY KEY,
  order_item_id INTEGER UNIQUE NOT NULL REFERENCES order_items(id) ON DELETE CASCADE,
  product_id    INTEGER NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  user_id       INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  rating        INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),
  comment       TEXT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_reviews_product ON reviews(product_id);
