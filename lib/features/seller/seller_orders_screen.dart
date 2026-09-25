import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/i18n/app_strings.dart';
import '../../widgets/app_skeleton.dart';
import '../../widgets/async_view.dart';
import '../../widgets/entrance.dart';
import '../../widgets/pill_tab_bar.dart';
import '../order/order_providers.dart';
import '../order/orders_screen.dart' show OrderCard;

/// Màn hình đơn hàng của shop (người bán) — chia theo trạng thái cần xử lý.
class SellerOrdersScreen extends ConsumerWidget {
  const SellerOrdersScreen({super.key});

  static const _statuses = <String?>['pending', 'confirmed', 'shipping', 'completed', null];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final labels = [s.tabPending, s.tabConfirmed, s.tabShipping, s.tabCompleted, s.all];
    return DefaultTabController(
      length: _statuses.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(s.myShopOrders),
          bottom: pillTabBar(labels),
        ),
        body: TabBarView(children: _statuses.map((st) => _ShopOrderList(status: st)).toList()),
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
    final s = ref.watch(stringsProvider);
    return RefreshIndicator(
      color: AppColors.brand,
      onRefresh: () => ref.refresh(shopOrdersProvider(status).future),
      child: AsyncView(
        value: async,
        loading: const SkeletonList(count: 4),
        onRetry: () => ref.invalidate(shopOrdersProvider(status)),
        data: (orders) {
          if (orders.isEmpty) {
            return ListView(children: [
              const SizedBox(height: 120),
              EmptyView(message: s.noOrdersShort, icon: Icons.receipt_long_outlined),
            ]);
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (_, i) =>
                FadeSlideIn(index: i, child: OrderCard(order: orders[i], showBuyer: true)),
          );
        },
      ),
    );
  }
}
