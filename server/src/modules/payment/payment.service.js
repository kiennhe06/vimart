/** Logic thanh toán: tạo link VNPay, xác nhận kết quả, và mock-pay cho môi trường dev. */
import { query } from '../../db/pool.js';
import { AppError } from '../../utils/AppError.js';
import { env, isVnpayConfigured } from '../../config/env.js';
import { buildPaymentUrl, verifyReturn, formatDate } from './vnpay.util.js';

/** Lấy bản ghi thanh toán theo group_code (phải thuộc về người dùng). */
async function getPayment(groupCode, userId) {
  const res = await query(
    `SELECT p.* FROM payments p
     WHERE p.group_code = $1
       AND EXISTS (SELECT 1 FROM orders o WHERE o.group_code = p.group_code AND o.buyer_id = $2)`,
    [groupCode, userId]
  );
  if (res.rows.length === 0) throw new AppError(404, 'Không tìm thấy giao dịch');
  return res.rows[0];
}

/**
 * Tạo URL thanh toán VNPay cho 1 nhóm đơn.
 * @returns {{ paymentUrl: string }}
 */
export async function createVnpayUrl(userId, groupCode, ipAddr) {
  if (!isVnpayConfigured()) {
    throw new AppError(400, 'Chưa cấu hình VNPay (VNP_TMN_CODE / VNP_HASH_SECRET trong .env). Dùng /mock-pay khi test.');
  }
  const payment = await getPayment(groupCode, userId);
  if (payment.status === 'paid') throw new AppError(400, 'Đơn này đã được thanh toán');

  const txnRef = `${groupCode}_${Date.now().toString().slice(-5)}`;
  const params = {
    vnp_Version: '2.1.0',
    vnp_Command: 'pay',
    vnp_TmnCode: env.vnpay.tmnCode,
    vnp_Amount: payment.amount * 100, // VNPay tính theo đơn vị x100
    vnp_CurrCode: 'VND',
    vnp_TxnRef: txnRef,
    vnp_OrderInfo: `Thanh toan don ${groupCode}`,
    vnp_OrderType: 'other',
    vnp_Locale: 'vn',
    vnp_ReturnUrl: env.vnpay.returnUrl,
    vnp_IpAddr: ipAddr || '127.0.0.1',
    vnp_CreateDate: formatDate(),
  };

  await query('UPDATE payments SET vnp_txn_ref = $1 WHERE id = $2', [txnRef, payment.id]);
  const paymentUrl = buildPaymentUrl(params, env.vnpay.hashSecret, env.vnpay.url);
  return { paymentUrl };
}

/**
 * Xử lý khi VNPay báo kết quả về.
 * @returns {{ success: boolean, groupCode: string|null, message: string }}
 */
export async function handleVnpayReturn(vnpQuery) {
  const valid = verifyReturn(vnpQuery, env.vnpay.hashSecret);
  if (!valid) return { success: false, groupCode: null, message: 'Chữ ký không hợp lệ' };

  const txnRef = vnpQuery.vnp_TxnRef || '';
  const groupCode = txnRef.split('_')[0];
  const responseCode = vnpQuery.vnp_ResponseCode;
  const paidOk = responseCode === '00';

  await markGroupPaid(groupCode, paidOk, responseCode);
  return {
    success: paidOk,
    groupCode,
    message: paidOk ? 'Thanh toán thành công' : `Thanh toán thất bại (mã ${responseCode})`,
  };
}

/** Cập nhật trạng thái thanh toán cho nhóm đơn + bản ghi payment. */
async function markGroupPaid(groupCode, paidOk, responseCode) {
  await query(
    'UPDATE payments SET status = $1, vnp_response_code = $2 WHERE group_code = $3',
    [paidOk ? 'paid' : 'failed', responseCode ?? null, groupCode]
  );
  if (paidOk) {
    await query("UPDATE orders SET payment_status = 'paid' WHERE group_code = $1", [groupCode]);
  }
}

/**
 * DEV ONLY: đánh dấu đã thanh toán mà không cần VNPay thật.
 * Dùng để test luồng đặt hàng -> thanh toán khi chưa có tài khoản sandbox.
 */
export async function mockPay(userId, groupCode) {
  if (env.nodeEnv === 'production') throw new AppError(403, 'Không dùng được ở môi trường production');
  const payment = await getPayment(groupCode, userId);
  if (payment.status === 'paid') throw new AppError(400, 'Đơn này đã được thanh toán');
  await markGroupPaid(groupCode, true, 'MOCK');
  return { groupCode, status: 'paid' };
}
