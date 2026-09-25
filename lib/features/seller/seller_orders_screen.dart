import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../widgets/async_view.dart';
import '../../widgets/pill_tab_bar.dart';
import '../order/order_providers.dart';
import '../order/orders_screen.dart' show OrderCard;

/// Màn hình đơn hàng của shop (người bán) — chia theo trạng thái cần xử lý.
class SellerOrdersScreen extends ConsumerWidget {
  const SellerOrdersScreen({super.key});

  static const _tabs = <(String, String?)>[
    ('Chờ xác nhận', 'pending'),
    ('Đã xác nhận', 'confirmed'),
    ('Đang giao', 'shipping'),
    ('Hoàn thành', 'completed'),
    ('Tất cả', null),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Đơn hàng của shop'),
          bottom: pillTabBar(_tabs.map((t) => t.$1).toList()),
        ),
        body: TabBarView(children: _tabs.map((t) => _ShopOrderList(status: t.$2)).toList()),
      ),
    );
  }
}

class _ShopOrderList extends ConsumerWidget {
  const _ShopOrderList({required this.status});
  final String? status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(shopOrdersProvider(status));
    return RefreshIndicator(
      color: AppColors.brand,
      onRefresh: () => ref.refresh(shopOrdersProvider(status).future),
      child: AsyncView(
        value: async,
        onRetry: () => ref.invalidate(shopOrdersProvider(status)),
        data: (orders) {
          if (orders.isEmpty) {
            return ListView(children: const [
              SizedBox(height: 120),
              EmptyView(message: 'Không có đơn nào', icon: Icons.receipt_long_outlined),
            ]);
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (_, i) => OrderCard(order: orders[i], showBuyer: true),
          );
        },
      ),
    );
  }
}
