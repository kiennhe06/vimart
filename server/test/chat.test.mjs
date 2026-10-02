/** Test chat: tạo hội thoại, gửi/nhận, unread, và chặn người ngoài. */
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { api, loginAs, bearer } from './helpers/agent.mjs';

/** shopId của 1 shop theo tên (lấy từ thẻ sản phẩm). */
async function shopIdByName(name) {
  const list = await api.get('/api/products');
  const card = list.body.data.items.find((c) => c.shopName === name);
  assert.ok(card, `không tìm thấy shop ${name}`);
  return card.shopId;
}

test('chat: buyer mở hội thoại, gửi tin; seller thấy unread rồi trả lời', async (t) => {
  const buyer = bearer((await loginAs('buyer')).token);
  const seller = bearer((await loginAs('seller1')).token); // chủ "Shop Táo Xanh"
  const shopId = await shopIdByName('Shop Táo Xanh');

  let convId;
  await t.test('buyer tạo hội thoại + gửi tin', async () => {
    const conv = await api.post('/api/chat/conversations').set(...buyer).send({ shopId });
    assert.equal(conv.status, 201);
    convId = conv.body.data.id;

    const msg = await api
      .post(`/api/chat/conversations/${convId}/messages`)
      .set(...buyer)
      .send({ body: 'Shop còn hàng không ạ?' });
    assert.equal(msg.status, 201);
  });

  await t.test('seller thấy hội thoại với unread = 1', async () => {
    const list = await api.get('/api/chat/conversations').set(...seller);
    const conv = list.body.data.find((c) => c.id === convId);
    assert.ok(conv, 'seller phải thấy hội thoại');
    assert.equal(conv.role, 'seller');
    assert.equal(conv.unread, 1);

    const count = await api.get('/api/chat/unread-count').set(...seller);
    assert.ok(count.body.data.count >= 1);
  });

  await t.test('seller đọc (reset unread) rồi trả lời', async () => {
    const msgs = await api.get(`/api/chat/conversations/${convId}/messages`).set(...seller);
    assert.equal(msgs.status, 200);
    assert.ok(msgs.body.data.length >= 1);

    // sau khi đọc, unread của seller về 0
    const list = await api.get('/api/chat/conversations').set(...seller);
    assert.equal(list.body.data.find((c) => c.id === convId).unread, 0);

    const reply = await api
      .post(`/api/chat/conversations/${convId}/messages`)
      .set(...seller)
      .send({ body: 'Dạ còn hàng bạn nhé.' });
    assert.equal(reply.status, 201);

    // giờ tới lượt buyer có unread
    const buyerList = await api.get('/api/chat/conversations').set(...buyer);
    assert.equal(buyerList.body.data.find((c) => c.id === convId).unread, 1);
  });

  await t.test('người ngoài không xem được tin của hội thoại (403)', async () => {
    const outsider = bearer((await loginAs('seller2')).token);
    const res = await api.get(`/api/chat/conversations/${convId}/messages`).set(...outsider);
    assert.equal(res.status, 403);
  });
});

test('chat: không thể nhắn tin với shop của chính mình (400)', async () => {
  const seller = bearer((await loginAs('seller1')).token);
  const shopId = await shopIdByName('Shop Táo Xanh'); // shop của seller1
  const res = await api.post('/api/chat/conversations').set(...seller).send({ shopId });
  assert.equal(res.status, 400);
});
