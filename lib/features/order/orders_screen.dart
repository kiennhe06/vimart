import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/nav_provider.dart';
import '../../app/theme.dart';
import '../../core/format.dart';
import '../../core/i18n/app_strings.dart';
import '../../models/order.dart';
import '../../widgets/async_view.dart';
import '../../widgets/login_required_view.dart';
import '../../widgets/pill_tab_bar.dart';
import '../auth/auth_provider.dart';
import 'order_providers.dart';

/// Tab Đơn hàng của người mua — tab dạng "viên thuốc", thẻ đơn bo tròn.
class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  static const _statuses = <String?>[null, 'pending', 'shipping', 'completed'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    if (!ref.watch(authProvider).isLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: Text(s.orders)),
        body: LoginRequiredView(message: s.loginToViewOrders),
      );
    }
    final labels = [s.all, s.tabPending, s.tabShipping, s.tabCompleted];

    return DefaultTabController(
      length: _statuses.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(s.orders),
          bottom: pillTabBar(labels),
        ),
        body: TabBarView(children: _statuses.map((st) => _OrderList(status: st)).toList()),
      ),
    );
  }
}

class _OrderList extends ConsumerWidget {
  const _OrderList({required this.status});
  final String? status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myOrdersProvider(status));
    return RefreshIndicator(
      color: AppColors.brand,
      onRefresh: () => ref.refresh(myOrdersProvider(status).future),
      child: AsyncView(
        value: async,
        onRetry: () => ref.invalidate(myOrdersProvider(status)),
        data: (orders) {
          if (orders.isEmpty) return const _EmptyOrders();
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (_, i) => OrderCard(order: orders[i]),
          );
        },
      ),
    );
  }
}

class _EmptyOrders extends ConsumerWidget {
  const _EmptyOrders();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    return LayoutBuilder(
      builder: (context, c) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: c.maxHeight),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96, height: 96,
                  decoration: const BoxDecoration(color: AppColors.brandSoft, shape: BoxShape.circle),
                  child: const Icon(Icons.receipt_long_rounded, size: 44, color: AppColors.brand),
                ),
                const SizedBox(height: 16),
                Text(s.noOrders, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(s.shopAndReturn, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 18),
                SizedBox(
                  width: 200,
                  child: ElevatedButton(
                    onPressed: () => ref.read(bottomNavIndexProvider.notifier).go(0),
                    child: Text(s.shopNowBtn),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Thẻ tóm tắt 1 đơn hàng — bo tròn, có icon chip + trạng thái + tổng tiền.
class OrderCard extends ConsumerWidget {
  const OrderCard({super.key, required this.order, this.showBuyer = false});
  final OrderSummary order;
  final bool showBuyer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    return GestureDetector(
      onTap: () => context.push('/order/${order.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(color: AppColors.brandSoft, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.inventory_2_rounded, color: AppColors.brand, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.orderCode(order.code), style: const TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(showBuyer ? s.customer(order.buyerName ?? '-') : (order.shopName ?? ''),
                          style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
                OrderStatusChip(status: order.status),
              ],
            ),
            const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
            Row(
              children: [
                Icon(order.paymentMethod == 'cod' ? Icons.payments_outlined : Icons.account_balance_wallet_outlined,
                    size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text(order.paymentMethod == 'cod' ? 'COD' : 'VNPay', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                if (order.isPaid)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(s.paid, style: const TextStyle(color: AppColors.success, fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                const Spacer(),
                Text(formatVnd(order.total),
                    style: const TextStyle(color: AppColors.brand, fontWeight: FontWeight.w800, fontSize: 16)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Nhãn màu theo trạng thái đơn.
class OrderStatusChip extends ConsumerWidget {
  const OrderStatusChip({super.key, required this.status});
  final String status;

  Color get _color => switch (status) {
        'pending' => const Color(0xFFE0A81E),
        'confirmed' => const Color(0xFF2B8AF0),
        'shipping' => const Color(0xFF7C5CFC),
        'completed' => AppColors.success,
        'cancelled' => AppColors.danger,
        _ => Colors.grey,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: _color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(20)),
      child: Text(ref.watch(stringsProvider).orderStatus(status),
          style: TextStyle(color: _color, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}
