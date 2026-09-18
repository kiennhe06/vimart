import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/providers.dart';
import '../../models/order.dart';

/// Kết quả sau khi đặt hàng.
class CheckoutResult {
  CheckoutResult({required this.groupCode, required this.totalAmount, required this.paymentMethod});
  final String groupCode;
  final int totalAmount;
  final String paymentMethod;

  factory CheckoutResult.fromJson(Map<String, dynamic> json) => CheckoutResult(
        groupCode: json['groupCode'] as String? ?? '',
        totalAmount: (json['totalAmount'] as num?)?.toInt() ?? 0,
        paymentMethod: json['paymentMethod'] as String? ?? 'cod',
      );
}

/// Truy cập API đơn hàng, đánh giá và thanh toán.
class OrderRepository {
  OrderRepository(this._api);
  final ApiClient _api;

  /// Đặt hàng từ giỏ.
  Future<CheckoutResult> checkout({
    required int addressId,
    required String paymentMethod,
    String? note,
  }) async {
    final data = await _api.post('/orders/checkout', body: {
      'addressId': addressId,
      'paymentMethod': paymentMethod,
      if (note != null && note.isNotEmpty) 'note': note,
    });
    return CheckoutResult.fromJson(data as Map<String, dynamic>);
  }

  /// Đơn của người mua.
  Future<List<OrderSummary>> listMyOrders({String? status}) async {
    final data = await _api.get('/orders', query: {'status': ?status});
    return (data as List<dynamic>).map((e) => OrderSummary.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Đơn của shop (người bán).
  Future<List<OrderSummary>> listShopOrders({String? status}) async {
    final data = await _api.get('/orders/shop', query: {'status': ?status});
    return (data as List<dynamic>).map((e) => OrderSummary.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Chi tiết đơn.
  Future<OrderDetail> getOrder(int id) async {
    final data = await _api.get('/orders/$id');
    return OrderDetail.fromJson(data as Map<String, dynamic>);
  }

  /// Đổi trạng thái đơn: cancel | received | confirm | ship | reject.
  Future<void> action(int orderId, String action) => _api.post('/orders/$orderId/$action');

  /// Đánh giá 1 món hàng đã hoàn thành.
  Future<void> review(int orderItemId, int rating, String? comment) => _api.post('/reviews', body: {
        'orderItemId': orderItemId,
        'rating': rating,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
      });

  /// DEV: giả lập thanh toán VNPay thành công.
  Future<void> mockPay(String groupCode) => _api.post('/payments/mock-pay', body: {'groupCode': groupCode});

  /// Tạo link thanh toán VNPay (khi đã cấu hình sandbox).
  Future<String> createVnpayUrl(String groupCode) async {
    final data = await _api.post('/payments/vnpay/create', body: {'groupCode': groupCode});
    return (data as Map<String, dynamic>)['paymentUrl'] as String;
  }
}

final orderRepositoryProvider =
    Provider<OrderRepository>((ref) => OrderRepository(ref.watch(apiClientProvider)));
