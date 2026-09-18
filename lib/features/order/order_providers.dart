import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/order.dart';
import '../auth/auth_provider.dart';
import 'order_repository.dart';

/// Đơn của người mua (lọc theo trạng thái; null = tất cả).
final myOrdersProvider = FutureProvider.family<List<OrderSummary>, String?>((ref, status) {
  final auth = ref.watch(authProvider);
  if (!auth.isLoggedIn) return Future.value(const []);
  return ref.watch(orderRepositoryProvider).listMyOrders(status: status);
});

/// Đơn của shop (người bán).
final shopOrdersProvider = FutureProvider.family<List<OrderSummary>, String?>((ref, status) {
  return ref.watch(orderRepositoryProvider).listShopOrders(status: status);
});

/// Chi tiết 1 đơn.
final orderDetailProvider = FutureProvider.family<OrderDetail, int>((ref, id) {
  return ref.watch(orderRepositoryProvider).getOrder(id);
});
