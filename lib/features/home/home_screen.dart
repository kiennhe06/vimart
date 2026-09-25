import 'package:flutter/material.dart' show Icons, RefreshIndicator, Colors;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/product.dart';
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
                    const _PromoBanner(),
                    VimartSearchBox(onSubmitted: (v) => setState(() => _keyword = v.trim())),
                    categoriesAsync.maybeWhen(
                      data: (cats) => CategoryCircles(
                        categories: cats,
                        selectedId: _categoryId,
                        onSelect: (id) => setState(() => _categoryId = id),
                      ),
                      orElse: () => const SizedBox(height: 96),
                    ),
                    const _SectionHeader(title: 'Gợi ý cho bạn'),
                    _buildProducts(productsAsync, query),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProducts(AsyncValue<List<ProductCard>> async, ProductQuery query) {
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: Text('Đang tải sản phẩm...', style: HomeText.meta)),
      ),
      error: (err, _) => Padding(
        padding: const EdgeInsets.all(40),
        child: Center(child: Text(err.toString(), textAlign: TextAlign.center, style: HomeText.meta)),
      ),
      data: (products) {
        if (products.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: Text('Không tìm thấy sản phẩm nào', style: HomeText.meta)),
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
          itemBuilder: (_, i) => ProductTile(
            product: products[i],
            tint: kCategoryTints[i % kCategoryTints.length],
          ),
        );
      },
    );
  }
}

/// Banner khuyến mãi gradient xanh ở đầu trang.
class _PromoBanner extends StatelessWidget {
  const _PromoBanner();
  @override
  Widget build(BuildContext context) {
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
                  const Text('Giảm 10% đơn đầu tiên 🎉',
                      style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text('Mua sắm tươi ngon, giao tận nơi',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                    child: const Text('Mua ngay',
                        style: TextStyle(color: HomeColors.brand, fontWeight: FontWeight.w700, fontSize: 13)),
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
  const _SectionHeader({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(HomeDims.pagePadding, 8, HomeDims.pagePadding, 4),
      child: Row(
        children: [
          Text(title, style: HomeText.sectionTitle),
          const Spacer(),
          Text('Xem tất cả', style: TextStyle(color: HomeColors.brand, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
