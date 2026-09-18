import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/format.dart';
import '../../models/order.dart';
import '../../widgets/async_view.dart';
import '../../widgets/login_required_view.dart';
import '../auth/auth_provider.dart';
import 'order_providers.dart';

/// Tab Đơn hàng của người mua, chia theo trạng thái.
class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  static const _tabs = <(String, String?)>[
    ('Tất cả', null),
    ('Chờ xác nhận', 'pending'),
    ('Đang giao', 'shipping'),
    ('Hoàn thành', 'completed'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(authProvider).isLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('Đơn hàng')),
        body: const LoginRequiredView(message: 'Đăng nhập để xem đơn hàng của bạn'),
      );
    }

    return DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Đơn hàng'),
          bottom: TabBar(
            isScrollable: true,
            tabs: _tabs.map((t) => Tab(text: t.$1)).toList(),
          ),
        ),
        body: TabBarView(
          children: _tabs.map((t) => _OrderList(status: t.$2)).toList(),
        ),
      ),
    );
  }
}

/// Danh sách đơn theo 1 trạng thái.
class _OrderList extends ConsumerWidget {
  const _OrderList({required this.status});
  final String? status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myOrdersProvider(status));
    return RefreshIndicator(
      onRefresh: () => ref.refresh(myOrdersProvider(status).future),
      child: AsyncView(
        value: async,
        onRetry: () => ref.invalidate(myOrdersProvider(status)),
        data: (orders) {
          if (orders.isEmpty) {
            return ListView(
              children: const [
                SizedBox(height: 120),
                EmptyView(message: 'Chưa có đơn hàng nào', icon: Icons.receipt_long_outlined),
              ],
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: orders.length,
            itemBuilder: (_, i) => OrderCard(order: orders[i]),
          );
        },
      ),
    );
  }
}

/// Thẻ tóm tắt 1 đơn hàng.
class OrderCard extends StatelessWidget {
  const OrderCard({super.key, required this.order, this.showBuyer = false});
  final OrderSummary order;
  final bool showBuyer;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: () => context.push('/order/${order.id}'),
        title: Text('Đơn ${order.code}', style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(showBuyer ? 'Khách: ${order.buyerName ?? '-'}' : (order.shopName ?? '')),
            const SizedBox(height: 4),
            Row(
              children: [
                OrderStatusChip(status: order.status),
                const SizedBox(width: 6),
                Text(order.paymentMethod == 'cod' ? 'COD' : 'VNPay',
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                if (order.isPaid)
                  const Padding(
                    padding: EdgeInsets.only(left: 6),
                    child: Text('• Đã trả', style: TextStyle(fontSize: 12, color: AppColors.success)),
                  ),
              ],
            ),
          ],
        ),
        trailing: Text(formatVnd(order.total),
            style: const TextStyle(color: AppColors.brand, fontWeight: FontWeight.bold)),
        isThreeLine: true,
      ),
    );
  }
}

/// Nhãn màu theo trạng thái đơn.
class OrderStatusChip extends StatelessWidget {
  const OrderStatusChip({super.key, required this.status});
  final String status;

  Color get _color => switch (status) {
        'pending' => Colors.orange,
        'confirmed' => Colors.blue,
        'shipping' => Colors.purple,
        'completed' => AppColors.success,
        'cancelled' => AppColors.danger,
        _ => Colors.grey,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(orderStatusLabel(status),
          style: TextStyle(color: _color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
