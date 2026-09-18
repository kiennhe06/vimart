import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/async_view.dart';
import '../catalog/widgets/product_card_view.dart';
import 'favorite_provider.dart';

/// Màn hình danh sách sản phẩm yêu thích.
class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(favoritesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Sản phẩm yêu thích')),
      body: AsyncView(
        value: async,
        onRetry: () => ref.invalidate(favoritesProvider),
        data: (products) {
          if (products.isEmpty) {
            return const EmptyView(message: 'Bạn chưa thích sản phẩm nào', icon: Icons.favorite_border);
          }
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.62,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: products.length,
            itemBuilder: (_, i) => ProductCardView(product: products[i]),
          );
        },
      ),
    );
  }
}
