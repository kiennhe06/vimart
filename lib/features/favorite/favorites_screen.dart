import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/app_strings.dart';
import '../../widgets/app_skeleton.dart';
import '../../widgets/async_view.dart';
import '../../widgets/entrance.dart';
import '../home/home_ui.dart';
import '../home/widgets/product_tile.dart';
import 'favorite_provider.dart';

/// Màn hình danh sách sản phẩm yêu thích.
class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(favoritesProvider);
    final s = ref.watch(stringsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(s.favoriteProducts)),
      body: AsyncView(
        value: async,
        loading: const SkeletonGrid(),
        onRetry: () => ref.invalidate(favoritesProvider),
        data: (products) {
          if (products.isEmpty) {
            return EmptyView(message: s.noFavorites, icon: Icons.favorite_border);
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
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
          );
        },
      ),
    );
  }
}
