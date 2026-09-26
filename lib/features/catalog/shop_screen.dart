import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/design.dart';
import '../../app/theme.dart';
import '../../core/i18n/app_strings.dart';
import '../../widgets/app_refresh.dart';
import '../../widgets/app_skeleton.dart';
import '../../widgets/async_view.dart';
import '../../widgets/entrance.dart';
import '../home/home_ui.dart';
import '../home/widgets/product_tile.dart';
import 'catalog_providers.dart';

/// Trang shop công khai: hiển thị danh sách sản phẩm của một shop.
class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key, required this.shopId});
  final int shopId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(shopProductsProvider(shopId));
    final s = ref.watch(stringsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(s.shopProducts)),
      body: AppRefresh(
        onRefresh: () => ref.refresh(shopProductsProvider(shopId).future),
        child: AsyncView(
        value: async,
        loading: const SkeletonGrid(),
        onRetry: () => ref.invalidate(shopProductsProvider(shopId)),
        data: (products) {
          if (products.isEmpty) {
            return EmptyView(message: s.shopNoProducts, icon: Icons.storefront_outlined);
          }
          return Column(
            children: [
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.brandSoft, borderRadius: BorderRadius.circular(20)),
                child: Row(
                  children: [
                    const CircleAvatar(radius: 26, backgroundColor: AppColors.brand,
                        child: Icon(Icons.storefront_rounded, color: Colors.white, size: 26)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(products.first.shopName ?? 'Shop',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                          Text(s.productsCount(products.length), style: TextStyle(color: context.c.textSecondary, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  physics: const AlwaysScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.66,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                  ),
                  itemCount: products.length,
                  itemBuilder: (_, i) => FadeSlideIn(
                    index: i,
                    child: ProductTile(
                      product: products[i],
                      tint: kCategoryTints[i % kCategoryTints.length],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        ),
      ),
    );
  }
}
