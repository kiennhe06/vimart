import 'package:flutter/material.dart' show Icons, RefreshIndicator, Colors;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/app_strings.dart';
import '../../models/product.dart';
import '../../widgets/app_skeleton.dart';
import '../../widgets/async_view.dart';
import '../../widgets/entrance.dart';
import '../catalog/catalog_providers.dart';
import 'home_ui.dart';
import 'widgets/category_circles.dart';
import 'widgets/product_tile.dart';
import 'widgets/vimart_header.dart';
import 'widgets/vimart_search_box.dart';

/// Trang chủ phong cách grocery: header, banner khuyến mãi, tìm kiếm,
/// vòng tròn danh mục, và lưới sản phẩm gợi ý.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _keyword = '';
  int? _categoryId;

  @override
  Widget build(BuildContext context) {
    final query = (keyword: _keyword, categoryId: _categoryId, sort: 'best_selling');
    final productsAsync = ref.watch(productListProvider(query));
    final categoriesAsync = ref.watch(categoriesProvider);
    final s = ref.watch(stringsProvider);

    return Container(
      color: HomeColors.background,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const VimartHeader(),
            Expanded(
              child: RefreshIndicator(
                color: HomeColors.brand,
                onRefresh: () => ref.refresh(productListProvider(query).future),
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    const FadeSlideIn(index: 0, child: _PromoBanner()),
                    FadeSlideIn(
                      index: 1,
                      child: VimartSearchBox(
                        hint: s.searchHint,
                        onSubmitted: (v) => setState(() => _keyword = v.trim()),
                      ),
                    ),
                    FadeSlideIn(
                      index: 2,
                      child: categoriesAsync.maybeWhen(
                        data: (cats) => CategoryCircles(
                          categories: cats,
                          selectedId: _categoryId,
                          onSelect: (id) => setState(() => _categoryId = id),
                          allLabel: s.all,
                        ),
                        orElse: () => const SizedBox(height: 96),
                      ),
                    ),
                    FadeSlideIn(index: 3, child: _SectionHeader(title: s.forYou, seeAll: s.seeAll)),
                    _buildProducts(productsAsync, query, s),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProducts(AsyncValue<List<ProductCard>> async, ProductQuery query, AppStrings s) {
    return async.when(
      loading: () => const SkeletonGrid(
        count: 6,
        padding: EdgeInsets.fromLTRB(HomeDims.pagePadding, 4, HomeDims.pagePadding, 8),
      ),
      error: (err, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: ErrorView(
          message: err.toString(),
          onRetry: () => ref.invalidate(productListProvider(query)),
        ),
      ),
      data: (products) {
        if (products.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: EmptyView(message: s.noProducts, icon: Icons.search_off_rounded),
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(HomeDims.pagePadding, 4, HomeDims.pagePadding, 8),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: HomeDims.gridGap,
            crossAxisSpacing: HomeDims.gridGap,
            childAspectRatio: 0.66,
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
    );
  }
}

/// Banner khuyến mãi gradient xanh ở đầu trang.
class _PromoBanner extends ConsumerWidget {
  const _PromoBanner();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(HomeDims.pagePadding, 4, HomeDims.pagePadding, 6),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [HomeColors.brand, HomeColors.brandDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [BoxShadow(color: Color(0x3316A34A), blurRadius: 18, offset: Offset(0, 8))],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.promoTitle,
                      style: const TextStyle(color: Color(0xFFFFFFFF), fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(s.promoSub,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                    child: Text(s.shopNow,
                        style: const TextStyle(color: HomeColors.brand, fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                ],
              ),
            ),
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), shape: BoxShape.circle),
              child: const Icon(Icons.shopping_basket_rounded, color: Color(0xFFFFFFFF), size: 34),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tiêu đề mục + "Xem tất cả".
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.seeAll});
  final String title;
  final String seeAll;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(HomeDims.pagePadding, 8, HomeDims.pagePadding, 4),
      child: Row(
        children: [
          Text(title, style: HomeText.sectionTitle),
          const Spacer(),
          Text(seeAll, style: const TextStyle(color: HomeColors.brand, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
