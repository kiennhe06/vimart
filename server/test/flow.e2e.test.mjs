/**
 * Luồng end-to-end (thay cho scratchpad/e2e.mjs cũ đã mất):
 * buyer đăng nhập → duyệt → thêm giỏ 2 shop → checkout COD → seller1 confirm/ship
 * → buyer nhận hàng → đánh giá → checkout VNPay + mock-pay → admin xem số liệu.
 */
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { api, loginAs, bearer } from './helpers/agent.mjs';

/** Tìm 1 sản phẩm (kèm variant đầu tiên còn hàng) thuộc shop có tên cho trước. */
async function findProductInShop(shopName) {
  const list = await api.get('/api/products');
  const card = list.body.data.items.find((c) => c.shopName === shopName);
  if (!card) throw new Error(`Không tìm thấy sản phẩm cho shop "${shopName}"`);
  const detail = await api.get(`/api/products/${card.id}`);
  const p = detail.body.data;
  const variant = p.variants.find((v) => v.stock > 0) ?? p.variants[0];
  return { productId: p.id, shopId: card.shopId, variantId: variant.id };
}

test('luồng mua hàng end-to-end', async (t) => {
  const buyer = await loginAs('buyer');
  const buyerAuth = bearer(buyer.token);

  // Sản phẩm từ 2 shop khác nhau (shop1 do seller1 sở hữu để về sau xử lý đơn).
  const shop1Product = await findProductInShop('Shop Táo Xanh');
  const shop2Product = await findProductInShop('Thời Trang GenZ');

  await t.test('thêm 2 sản phẩm từ 2 shop vào giỏ', async () => {
    for (const it of [shop1Product, shop2Product]) {
      const res = await api
        .post('/api/cart/items')
        .set(...buyerAuth)
        .send({ variantId: it.variantId, quantity: 1 });
      assert.equal(res.status, 200);
    }
    const cart = await api.get('/api/cart').set(...buyerAuth);
    assert.equal(cart.status, 200);
    assert.ok(cart.body.data.shops.length >= 2, 'giỏ phải có >=2 shop');
    assert.equal(cart.body.data.itemCount, 2);
  });

  let codOrders;
  await t.test('checkout COD tạo đơn theo từng shop', async () => {
    const addrs = await api.get('/api/users/me/addresses').set(...buyerAuth);
    const addressId = addrs.body.data[0].id;

    const res = await api
      .post('/api/orders/checkout')
      .set(...buyerAuth)
      .send({ addressId, paymentMethod: 'cod' });
    assert.equal(res.status, 201);
    assert.ok(res.body.data.groupCode);
    codOrders = res.body.data.orders;
    assert.ok(codOrders.length >= 2, 'phải tách đơn theo shop');
  });

  let shop1OrderId;
  let reviewItemId;
  await t.test('seller1 xác nhận + giao, buyer nhận hàng', async () => {
    const seller1 = await loginAs('seller1');
    const seller1Auth = bearer(seller1.token);
    const order = codOrders.find((o) => o.shopId === shop1Product.shopId);
    assert.ok(order, 'phải có đơn của shop1');
    shop1OrderId = order.id;

    const confirm = await api.post(`/api/orders/${shop1OrderId}/confirm`).set(...seller1Auth);
    assert.equal(confirm.status, 200);
    const ship = await api.post(`/api/orders/${shop1OrderId}/ship`).set(...seller1Auth);
    assert.equal(ship.status, 200);

    const received = await api.post(`/api/orders/${shop1OrderId}/received`).set(...buyerAuth);
    assert.equal(received.status, 200);

    const detail = await api.get(`/api/orders/${shop1OrderId}`).set(...buyerAuth);
    assert.equal(detail.body.data.status, 'completed');
    reviewItemId = detail.body.data.items[0].id;
  });

  await t.test('buyer đánh giá món trong đơn đã hoàn thành', async () => {
    const res = await api
      .post('/api/reviews')
      .set(...buyerAuth)
      .send({ orderItemId: reviewItemId, rating: 5, comment: 'Hàng tốt, giao nhanh!' });
    assert.equal(res.status, 201);
  });

  await t.test('checkout VNPay rồi mock-pay thành công', async () => {
    // Thêm 1 món rồi đặt đơn VNPay (giỏ đã trống sau lần checkout trước).
    await api
      .post('/api/cart/items')
      .set(...buyerAuth)
      .send({ variantId: shop2Product.variantId, quantity: 1 });
    const addrs = await api.get('/api/users/me/addresses').set(...buyerAuth);
    const checkout = await api
      .post('/api/orders/checkout')
      .set(...buyerAuth)
      .send({ addressId: addrs.body.data[0].id, paymentMethod: 'vnpay' });
    assert.equal(checkout.status, 201);

    const pay = await api
      .post('/api/payments/mock-pay')
      .set(...buyerAuth)
      .send({ groupCode: checkout.body.data.groupCode });
    assert.equal(pay.status, 200);
  });

  await t.test('admin thấy đơn + doanh thu trên sàn', async () => {
    const admin = await loginAs('admin');
    const adminAuth = bearer(admin.token);
    const stats = await api.get('/api/admin/stats').set(...adminAuth);
    assert.ok(stats.body.data.totalOrders >= 3, 'đã có >=3 đơn sau luồng');
    assert.ok(stats.body.data.totalRevenue > 0, 'đơn hoàn thành sinh doanh thu');

    const orders = await api.get('/api/admin/orders').set(...adminAuth);
    assert.ok(orders.body.data.length >= 3);
  });
});
