import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../widgets/async_view.dart';
import 'catalog_providers.dart';
import 'widgets/product_card_view.dart';

/// Trang shop công khai: hiển thị danh sách sản phẩm của một shop.
class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key, required this.shopId});
  final int shopId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(shopProductsProvider(shopId));
    return Scaffold(
      appBar: AppBar(title: const Text('Sản phẩm của shop')),
      body: AsyncView(
        value: async,
        onRetry: () => ref.invalidate(shopProductsProvider(shopId)),
        data: (products) {
          if (products.isEmpty) {
            return const EmptyView(message: 'Shop chưa có sản phẩm nào', icon: Icons.storefront_outlined);
          }
          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: AppColors.brand.withValues(alpha: 0.08),
                child: Row(
                  children: [
                    const CircleAvatar(backgroundColor: AppColors.brand, child: Icon(Icons.storefront, color: Colors.white)),
                    const SizedBox(width: 12),
                    Text(products.first.shopName ?? 'Shop',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.62,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: products.length,
                  itemBuilder: (_, i) => ProductCardView(product: products[i]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
