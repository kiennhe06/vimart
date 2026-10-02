/**
 * Logic đơn hàng — phần lõi của app.
 *
 * Luồng đặt hàng (checkout):
 *   giỏ hàng -> tách theo shop -> mỗi shop 1 đơn -> trừ kho -> xóa giỏ.
 * Tất cả nằm trong 1 transaction: nếu 1 bước lỗi thì hủy toàn bộ (không trừ kho lung tung).
 *
 * Trạng thái đơn: pending -> confirmed -> shipping -> completed  (hoặc cancelled).
 */
import { query, withTransaction } from '../../db/pool.js';
import { AppError } from '../../utils/AppError.js';
import { validateVoucher } from '../voucher/voucher.service.js';
import { createNotification } from '../notification/notification.service.js';

/** Phí vận chuyển cố định cho mỗi shop (VND). Đơn giản cho bản MVP. */
const SHIPPING_FEE_PER_SHOP = 30000;

/** Tạo mã ngẫu nhiên dạng VM + số. */
function genCode(prefix) {
  const time = Date.now().toString().slice(-8);
  const rand = Math.floor(Math.random() * 900 + 100);
  return `${prefix}${time}${rand}`;
}

/**
 * Đặt hàng từ toàn bộ giỏ hàng.
 * @returns { groupCode, totalAmount, paymentMethod, orders: [{id, code, shopId, total}] }
 */
export async function checkout(userId, { addressId, paymentMethod, note, voucherCode }) {
  return withTransaction(async (client) => {
    // 1) Lấy địa chỉ nhận hàng (phải là của người dùng)
    const addrRes = await client.query('SELECT * FROM addresses WHERE id = $1 AND user_id = $2', [
      addressId,
      userId,
    ]);
    const address = addrRes.rows[0];
    if (!address) throw new AppError(400, 'Địa chỉ nhận hàng không hợp lệ');

    // 2) Lấy giỏ hàng kèm thông tin sản phẩm/shop, khóa dòng kho để tránh tranh chấp
    const cartRes = await client.query(
      `SELECT ci.id AS cart_item_id, ci.quantity,
              v.id AS variant_id, v.name AS variant_name, v.price, v.stock,
              p.id AS product_id, p.name AS product_name, p.image_url, p.shop_id
       FROM cart_items ci
       JOIN product_variants v ON v.id = ci.variant_id
       JOIN products p ON p.id = v.product_id
       WHERE ci.user_id = $1
       ORDER BY p.shop_id`,
      [userId]
    );
    if (cartRes.rows.length === 0) throw new AppError(400, 'Giỏ hàng đang trống');

    // 3) Gom theo shop (kèm subtotal từng shop để phân bổ giảm giá)
    const byShop = new Map();
    for (const row of cartRes.rows) {
      if (!byShop.has(row.shop_id)) byShop.set(row.shop_id, { items: [], subtotal: 0 });
      const group = byShop.get(row.shop_id);
      group.items.push(row);
      group.subtotal += Number(row.price) * row.quantity;
    }
    const shops = [...byShop.entries()]; // [ [shopId, {items, subtotal}], ... ]
    const cartSubtotal = shops.reduce((sum, [, g]) => sum + g.subtotal, 0);

    // 3b) Áp mã giảm giá (nếu có) trên TỔNG tiền hàng, khóa dòng voucher trong transaction.
    let voucher = null;
    let totalDiscount = 0;
    if (voucherCode && String(voucherCode).trim()) {
      const applied = await validateVoucher(voucherCode, cartSubtotal, client);
      voucher = applied.voucher;
      totalDiscount = applied.discount;
    }

    const addressText = [address.line, address.ward, address.district, address.province]
      .filter(Boolean)
      .join(', ');
    const groupCode = genCode('VG');
    const createdOrders = [];
    let totalAmount = 0;
    let allocatedDiscount = 0;

    // 4) Với mỗi shop -> tạo 1 đơn
    for (let i = 0; i < shops.length; i++) {
      const [shopId, group] = shops[i];
      const items = group.items;
      const subtotal = group.subtotal;
      const shippingFee = SHIPPING_FEE_PER_SHOP;
      // Chia giảm giá theo tỉ lệ subtotal; đơn cuối nhận phần dư để tổng khớp tuyệt đối.
      const discountShare =
        totalDiscount === 0
          ? 0
          : i === shops.length - 1
            ? totalDiscount - allocatedDiscount
            : Math.round((totalDiscount * subtotal) / cartSubtotal);
      allocatedDiscount += discountShare;
      const total = subtotal + shippingFee - discountShare;
      totalAmount += total;

      const orderRes = await client.query(
        `INSERT INTO orders
          (code, group_code, buyer_id, shop_id, recipient_name, recipient_phone, address_text,
           payment_method, subtotal, shipping_fee, discount, total, note)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13)
         RETURNING id, code, total`,
        [
          genCode('VM'),
          groupCode,
          userId,
          shopId,
          address.recipient_name,
          address.phone,
          addressText,
          paymentMethod,
          subtotal,
          shippingFee,
          discountShare,
          total,
          note ?? null,
        ]
      );
      const order = orderRes.rows[0];

      // 5) Tạo chi tiết đơn + trừ kho (kiểm tra đủ hàng)
      for (const it of items) {
        const dec = await client.query(
          'UPDATE product_variants SET stock = stock - $1 WHERE id = $2 AND stock >= $1 RETURNING stock',
          [it.quantity, it.variant_id]
        );
        if (dec.rows.length === 0) {
          throw new AppError(400, `Sản phẩm "${it.product_name}" không đủ hàng trong kho`);
        }
        await client.query(
          `INSERT INTO order_items
            (order_id, product_id, variant_id, product_name, variant_name, image_url, price, quantity)
           VALUES ($1,$2,$3,$4,$5,$6,$7,$8)`,
          [
            order.id,
            it.product_id,
            it.variant_id,
            it.product_name,
            it.variant_name,
            it.image_url,
            it.price,
            it.quantity,
          ]
        );
        // Cộng số lượng đã bán cho sản phẩm
        await client.query('UPDATE products SET sold_count = sold_count + $1 WHERE id = $2', [
          it.quantity,
          it.product_id,
        ]);
      }

      createdOrders.push({ id: order.id, code: order.code, shopId, total: Number(order.total) });
    }

    // 6) Ghi nhận đã dùng voucher (đã khóa dòng + kiểm tra hợp lệ ở bước 3b).
    if (voucher) {
      await client.query('UPDATE vouchers SET used_count = used_count + 1 WHERE id = $1', [
        voucher.id,
      ]);
    }

    // 7) Xóa giỏ hàng đã đặt
    await client.query('DELETE FROM cart_items WHERE user_id = $1', [userId]);

    // 8) Tạo bản ghi thanh toán cho cả nhóm đơn
    await client.query(
      `INSERT INTO payments (group_code, amount, method, status)
       VALUES ($1, $2, $3, $4)`,
      [groupCode, totalAmount, paymentMethod, paymentMethod === 'cod' ? 'pending' : 'pending']
    );

    return {
      groupCode,
      totalAmount,
      discount: totalDiscount,
      voucherCode: voucher ? voucher.code : null,
      paymentMethod,
      orders: createdOrders,
    };
  });
}

/** Chuyển 1 dòng đơn (DB) sang object cho app. */
function toOrder(row) {
  return {
    id: row.id,
    code: row.code,
    groupCode: row.group_code,
    shopId: row.shop_id,
    shopName: row.shop_name,
    buyerId: row.buyer_id,
    buyerName: row.buyer_name,
    recipientName: row.recipient_name,
    recipientPhone: row.recipient_phone,
    addressText: row.address_text,
    status: row.status,
    paymentMethod: row.payment_method,
    paymentStatus: row.payment_status,
    subtotal: row.subtotal,
    shippingFee: row.shipping_fee,
    discount: row.discount,
    total: row.total,
    note: row.note,
    createdAt: row.created_at,
  };
}

/** Danh sách đơn của người mua (lọc theo trạng thái nếu có). */
export async function listMyOrders(userId, status) {
  const params = [userId];
  let where = 'o.buyer_id = $1';
  if (status) {
    params.push(status);
    where += ` AND o.status = $${params.length}`;
  }
  const result = await query(
    `SELECT o.*, s.name AS shop_name
     FROM orders o JOIN shops s ON s.id = o.shop_id
     WHERE ${where} ORDER BY o.created_at DESC`,
    params
  );
  return result.rows.map(toOrder);
}

/** Danh sách đơn của shop (người bán). */
export async function listShopOrders(ownerId, status) {
  const shopRes = await query('SELECT id FROM shops WHERE owner_id = $1', [ownerId]);
  if (shopRes.rows.length === 0) throw new AppError(403, 'Bạn chưa có shop');
  const shopId = shopRes.rows[0].id;

  const params = [shopId];
  let where = 'o.shop_id = $1';
  if (status) {
    params.push(status);
    where += ` AND o.status = $${params.length}`;
  }
  const result = await query(
    `SELECT o.*, s.name AS shop_name, u.full_name AS buyer_name
     FROM orders o
     JOIN shops s ON s.id = o.shop_id
     JOIN users u ON u.id = o.buyer_id
     WHERE ${where} ORDER BY o.created_at DESC`,
    params
  );
  return result.rows.map(toOrder);
}

/** Chi tiết 1 đơn (chỉ người mua của đơn hoặc chủ shop được xem). */
export async function getOrderDetail(userId, orderId) {
  const result = await query(
    `SELECT o.*, s.name AS shop_name, s.owner_id, u.full_name AS buyer_name
     FROM orders o
     JOIN shops s ON s.id = o.shop_id
     JOIN users u ON u.id = o.buyer_id
     WHERE o.id = $1`,
    [orderId]
  );
  const order = result.rows[0];
  if (!order) throw new AppError(404, 'Không tìm thấy đơn hàng');
  if (order.buyer_id !== userId && order.owner_id !== userId) {
    throw new AppError(403, 'Bạn không có quyền xem đơn này');
  }

  const itemsRes = await query(
    `SELECT id, product_id, variant_id, product_name, variant_name, image_url, price, quantity, reviewed
     FROM order_items WHERE order_id = $1`,
    [orderId]
  );
  const historyRes = await query(
    `SELECT to_status, actor_role, created_at
     FROM order_status_history WHERE order_id = $1 ORDER BY created_at ASC`,
    [orderId]
  );

  return {
    ...toOrder(order),
    items: itemsRes.rows.map((i) => ({
      id: i.id,
      productId: i.product_id,
      variantId: i.variant_id,
      productName: i.product_name,
      variantName: i.variant_name,
      imageUrl: i.image_url,
      price: i.price,
      quantity: i.quantity,
      reviewed: i.reviewed,
    })),
    history: historyRes.rows.map((h) => ({
      toStatus: h.to_status,
      actorRole: h.actor_role,
      createdAt: h.created_at,
    })),
  };
}

/** Hoàn kho khi hủy đơn (cộng lại tồn kho, trừ số đã bán). */
async function restoreStock(client, orderId) {
  const items = await client.query(
    'SELECT variant_id, product_id, quantity FROM order_items WHERE order_id = $1',
    [orderId]
  );
  for (const it of items.rows) {
    if (it.variant_id) {
      await client.query('UPDATE product_variants SET stock = stock + $1 WHERE id = $2', [
        it.quantity,
        it.variant_id,
      ]);
    }
    if (it.product_id) {
      await client.query(
        'UPDATE products SET sold_count = GREATEST(sold_count - $1, 0) WHERE id = $2',
        [it.quantity, it.product_id]
      );
    }
  }
}

/**
 * Đổi trạng thái đơn với kiểm tra quyền + đúng luồng.
 * @param {'confirm'|'ship'|'reject'|'cancel'|'received'} action
 */
export async function changeStatus(userId, orderId, action, { asAdmin = false } = {}) {
  return withTransaction(async (client) => {
    const res = await client.query(
      `SELECT o.*, s.owner_id FROM orders o JOIN shops s ON s.id = o.shop_id WHERE o.id = $1`,
      [orderId]
    );
    const order = res.rows[0];
    if (!order) throw new AppError(404, 'Không tìm thấy đơn hàng');

    // Admin có quyền thao tác thay cả shop lẫn người mua, nhưng VẪN theo đúng
    // trình tự trạng thái + side-effect (hoàn kho khi hủy, COD nhận = đã trả).
    const isBuyer = asAdmin || order.buyer_id === userId;
    const isSeller = asAdmin || order.owner_id === userId;

    let newStatus;
    let paymentStatus = order.payment_status;

    switch (action) {
      case 'confirm': // shop xác nhận
        if (!isSeller) throw new AppError(403, 'Chỉ shop được xác nhận đơn');
        if (order.status !== 'pending') throw new AppError(400, 'Chỉ xác nhận được đơn đang chờ');
        newStatus = 'confirmed';
        break;
      case 'ship': // shop giao hàng
        if (!isSeller) throw new AppError(403, 'Chỉ shop được cập nhật giao hàng');
        if (order.status !== 'confirmed')
          throw new AppError(400, 'Đơn phải được xác nhận trước khi giao');
        newStatus = 'shipping';
        break;
      case 'reject': // shop từ chối đơn (hoàn kho)
        if (!isSeller) throw new AppError(403, 'Chỉ shop được từ chối đơn');
        if (order.status !== 'pending') throw new AppError(400, 'Chỉ từ chối được đơn đang chờ');
        await restoreStock(client, orderId);
        newStatus = 'cancelled';
        break;
      case 'cancel': // người mua hủy khi shop chưa xác nhận
        if (!isBuyer) throw new AppError(403, 'Chỉ người mua được hủy đơn');
        if (order.status !== 'pending')
          throw new AppError(400, 'Chỉ hủy được khi shop chưa xác nhận');
        await restoreStock(client, orderId);
        newStatus = 'cancelled';
        break;
      case 'received': // người mua xác nhận đã nhận
        if (!isBuyer) throw new AppError(403, 'Chỉ người mua được xác nhận đã nhận');
        if (order.status !== 'shipping') throw new AppError(400, 'Đơn chưa ở trạng thái đang giao');
        newStatus = 'completed';
        if (order.payment_method === 'cod') paymentStatus = 'paid'; // COD: nhận hàng = đã trả tiền
        break;
      default:
        throw new AppError(400, 'Hành động không hợp lệ');
    }

    const updated = await client.query(
      'UPDATE orders SET status = $1, payment_status = $2 WHERE id = $3 RETURNING *',
      [newStatus, paymentStatus, orderId]
    );

    // Ghi lịch sử đổi trạng thái (ai đổi, từ -> đến).
    const actorRole = asAdmin
      ? 'admin'
      : order.buyer_id === userId
        ? 'buyer'
        : 'seller';
    await client.query(
      `INSERT INTO order_status_history (order_id, from_status, to_status, changed_by, actor_role)
       VALUES ($1, $2, $3, $4, $5)`,
      [orderId, order.status, newStatus, userId, actorRole]
    );

    // Thông báo cho NGƯỜI MUA khi shop/admin đổi trạng thái (không tự thông báo cho chính mình).
    const actorIsBuyer = !asAdmin && order.buyer_id === userId;
    if (!actorIsBuyer) {
      const msg = {
        confirmed: ['Đơn đã được xác nhận', `Đơn ${order.code} đã được xác nhận và đang chuẩn bị.`],
        shipping: ['Đơn đang được giao', `Đơn ${order.code} đang trên đường giao tới bạn.`],
        completed: ['Đơn đã hoàn thành', `Đơn ${order.code} đã hoàn thành. Cảm ơn bạn!`],
        cancelled: ['Đơn đã bị huỷ', `Đơn ${order.code} đã bị huỷ/từ chối.`],
      }[newStatus];
      if (msg) {
        await createNotification(client, {
          userId: order.buyer_id,
          type: 'order_status',
          title: msg[0],
          body: msg[1],
          orderId,
        });
      }
    }

    return toOrder({ ...updated.rows[0], shop_name: null, buyer_name: null });
  });
}
