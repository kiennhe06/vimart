/**
 * Nạp dữ liệu mẫu để chạy thử app: tài khoản, danh mục, shop, sản phẩm.
 * Chạy: npm run db:seed  (sẽ tạo lại toàn bộ bảng rồi nạp dữ liệu)
 *
 * TÀI KHOẢN TEST (mật khẩu đều là 123456):
 *   admin@vimart.vn    -> Admin
 *   seller1@vimart.vn  -> Người bán (Shop Táo Xanh)
 *   seller2@vimart.vn  -> Người bán (Thời Trang GenZ)
 *   buyer@vimart.vn    -> Người mua (đã có địa chỉ)
 */
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import bcrypt from 'bcryptjs';
import { pool } from './pool.js';

const __dirname = dirname(fileURLToPath(import.meta.url));

async function seed() {
  console.log('⏳ Tạo lại bảng...');
  await pool.query(readFileSync(join(__dirname, 'schema.sql'), 'utf8'));

  const password = await bcrypt.hash('123456', 10);

  console.log('⏳ Nạp người dùng...');
  await insertUser('admin@vimart.vn', password, 'Quản Trị Viên', '0900000001', 'admin');
  const seller1 = await insertUser(
    'seller1@vimart.vn',
    password,
    'Trần Văn Bán',
    '0900000002',
    'customer'
  );
  const seller2 = await insertUser(
    'seller2@vimart.vn',
    password,
    'Lê Thị Shop',
    '0900000003',
    'customer'
  );
  const buyer = await insertUser(
    'buyer@vimart.vn',
    password,
    'Nguyễn Văn Mua',
    '0900000004',
    'customer'
  );

  // Địa chỉ cho người mua
  await pool.query(
    `INSERT INTO addresses (user_id, recipient_name, phone, line, ward, district, province, is_default)
     VALUES ($1, 'Nguyễn Văn Mua', '0900000004', '123 Đường Lê Lợi', 'Phường Bến Nghé', 'Quận 1', 'TP. Hồ Chí Minh', TRUE)`,
    [buyer]
  );

  console.log('⏳ Nạp danh mục...');
  const cats = {};
  for (const [name, slug, icon] of [
    ['Điện thoại', 'dien-thoai', 'smartphone'],
    ['Thời trang', 'thoi-trang', 'checkroom'],
    ['Đồ gia dụng', 'gia-dung', 'home'],
    ['Sách', 'sach', 'menu_book'],
    ['Làm đẹp', 'lam-dep', 'spa'],
    ['Đồ ăn', 'do-an', 'restaurant'],
  ]) {
    const r = await pool.query(
      'INSERT INTO categories (name, slug, icon) VALUES ($1,$2,$3) RETURNING id',
      [name, slug, icon]
    );
    cats[slug] = r.rows[0].id;
  }

  console.log('⏳ Nạp shop...');
  const shop1 = await insertShop(
    seller1,
    'Shop Táo Xanh',
    'Chuyên phụ kiện & điện thoại chính hãng',
    null
  );
  const shop2 = await insertShop(
    seller2,
    'Thời Trang GenZ',
    'Quần áo phong cách trẻ trung, giá tốt',
    null
  );

  console.log('⏳ Nạp sản phẩm...');
  const img = (seed) => `https://picsum.photos/seed/${seed}/600/600`;

  await insertProduct(
    shop1,
    cats['dien-thoai'],
    'Ốp lưng iPhone 15 chống sốc',
    'Ốp silicon dẻo, chống bám vân tay',
    img('case15'),
    [
      { name: 'Đen', price: 89000, stock: 120 },
      { name: 'Trong suốt', price: 89000, stock: 80 },
      { name: 'Xanh', price: 99000, stock: 40 },
    ]
  );
  await insertProduct(
    shop1,
    cats['dien-thoai'],
    'Sạc nhanh USB-C 20W',
    'Củ sạc nhanh chuẩn PD, an toàn',
    img('charger'),
    [{ name: 'Trắng', price: 149000, stock: 200 }]
  );
  await insertProduct(
    shop1,
    cats['dien-thoai'],
    'Tai nghe Bluetooth TWS Pro',
    'Chống ồn, pin 6 giờ, kết nối nhanh',
    img('earbuds'),
    [
      { name: 'Trắng', price: 399000, stock: 60 },
      { name: 'Đen', price: 399000, stock: 55 },
    ]
  );
  await insertProduct(
    shop1,
    cats['gia-dung'],
    'Đèn LED để bàn cảm ứng',
    'Ba mức sáng, cổng USB tiện lợi',
    img('lamp'),
    [{ name: 'Mặc định', price: 259000, stock: 30 }]
  );

  await insertProduct(
    shop2,
    cats['thoi-trang'],
    'Áo thun cotton unisex',
    'Vải cotton 100%, form rộng thoải mái',
    img('tshirt'),
    [
      { name: 'Trắng / M', price: 129000, stock: 100 },
      { name: 'Trắng / L', price: 129000, stock: 90 },
      { name: 'Đen / M', price: 129000, stock: 70 },
      { name: 'Đen / L', price: 139000, stock: 50 },
    ]
  );
  await insertProduct(
    shop2,
    cats['thoi-trang'],
    'Quần jeans nam basic',
    'Co giãn nhẹ, dễ phối đồ',
    img('jeans'),
    [
      { name: 'Size 29', price: 289000, stock: 25 },
      { name: 'Size 30', price: 289000, stock: 30 },
      { name: 'Size 31', price: 289000, stock: 20 },
    ]
  );
  await insertProduct(
    shop2,
    cats['lam-dep'],
    'Son kem lì lâu trôi',
    'Chất son mịn, lên màu chuẩn',
    img('lipstick'),
    [
      { name: 'Đỏ cam', price: 159000, stock: 45 },
      { name: 'Hồng đất', price: 159000, stock: 40 },
    ]
  );
  await insertProduct(
    shop2,
    cats['sach'],
    'Sách "Tư duy nhanh và chậm"',
    'Bản dịch tiếng Việt, bìa mềm',
    img('book'),
    [{ name: 'Mặc định', price: 119000, stock: 15 }]
  );

  console.log('✅ Nạp dữ liệu xong.');
  console.log(
    '   Tài khoản test (mật khẩu 123456): admin@vimart.vn, seller1@vimart.vn, seller2@vimart.vn, buyer@vimart.vn'
  );
  await pool.end();
}

/** Thêm 1 người dùng, trả về id. */
async function insertUser(email, passwordHash, fullName, phone, role) {
  const r = await pool.query(
    'INSERT INTO users (email, password_hash, full_name, phone, role) VALUES ($1,$2,$3,$4,$5) RETURNING id',
    [email, passwordHash, fullName, phone, role]
  );
  return r.rows[0].id;
}

/** Thêm 1 shop, trả về id. */
async function insertShop(ownerId, name, description, avatarUrl) {
  const r = await pool.query(
    'INSERT INTO shops (owner_id, name, description, avatar_url) VALUES ($1,$2,$3,$4) RETURNING id',
    [ownerId, name, description, avatarUrl]
  );
  return r.rows[0].id;
}

/** Thêm 1 sản phẩm kèm các phân loại. */
async function insertProduct(shopId, categoryId, name, description, imageUrl, variants) {
  const r = await pool.query(
    'INSERT INTO products (shop_id, category_id, name, description, image_url) VALUES ($1,$2,$3,$4,$5) RETURNING id',
    [shopId, categoryId, name, description, imageUrl]
  );
  const productId = r.rows[0].id;
  for (const v of variants) {
    await pool.query(
      'INSERT INTO product_variants (product_id, name, price, stock) VALUES ($1,$2,$3,$4)',
      [productId, v.name, v.price, v.stock]
    );
  }
  return productId;
}

seed().catch((error) => {
  console.error('❌ Lỗi seed:', error);
  process.exit(1);
});
