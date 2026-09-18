import 'package:flutter/material.dart' show RefreshIndicator;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/product.dart';
import '../catalog/catalog_providers.dart';
import 'home_ui.dart';
import 'widgets/category_selector.dart';
import 'widgets/product_tile.dart';
import 'widgets/sort_control.dart';
import 'widgets/vimart_header.dart';
import 'widgets/vimart_search_box.dart';

/// Màn hình Trang chủ được dựng lại hoàn toàn từ widget nền tảng.
/// Phần DATA (provider/repository) giữ nguyên; chỉ UI là mới.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _keyword = '';
  int? _categoryId;
  String _sort = 'newest';
  bool _sortMenuOpen = false;

  // Vị trí menu sort = tổng chiều cao các khối phía trên (tính từ mép SafeArea).
  double get _menuTop =>
      VimartHeader.height + VimartSearchBox.areaHeight + CategorySelector.height + SortControl.height - 6;

  void _closeMenu() => setState(() => _sortMenuOpen = false);

  @override
  Widget build(BuildContext context) {
    final query = (keyword: _keyword, categoryId: _categoryId, sort: _sort);
    final productsAsync = ref.watch(productListProvider(query));
    final categoriesAsync = ref.watch(categoriesProvider);

    return Container(
      color: HomeColors.background,
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // ---- Nội dung chính ----
            Column(
              children: [
                const VimartHeader(),
                VimartSearchBox(onSubmitted: (v) => setState(() => _keyword = v.trim())),
                categoriesAsync.maybeWhen(
                  data: (cats) => CategorySelector(
                    categories: cats,
                    selectedId: _categoryId,
                    onSelect: (id) => setState(() {
                      _categoryId = id;
                      _sortMenuOpen = false;
                    }),
                  ),
                  orElse: () => const SizedBox(height: CategorySelector.height),
                ),
                SortControl(
                  currentSort: _sort,
                  menuOpen: _sortMenuOpen,
                  onTap: () => setState(() => _sortMenuOpen = !_sortMenuOpen),
                ),
                Expanded(child: _buildGrid(productsAsync, query)),
              ],
            ),

            // ---- Lớp mờ đóng menu khi bấm ra ngoài ----
            if (_sortMenuOpen)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _closeMenu,
                  child: const ColoredBox(color: HomeColors.barrier),
                ),
              ),

            // ---- Menu sort (overlay) ----
            if (_sortMenuOpen)
              Positioned(
                top: _menuTop,
                left: HomeDims.pagePadding,
                child: SortMenu(
                  currentSort: _sort,
                  onSelect: (key) => setState(() {
                    _sort = key;
                    _sortMenuOpen = false;
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(AsyncValue<List<ProductCard>> async, ProductQuery query) {
    return async.when(
      loading: () => const _CenterMessage(text: 'Đang tải sản phẩm...'),
      error: (err, _) => _ErrorMessage(
        message: err.toString(),
        onRetry: () => ref.invalidate(productListProvider(query)),
      ),
      data: (products) {
        if (products.isEmpty) {
          return const _CenterMessage(text: 'Không tìm thấy sản phẩm nào');
        }
        return RefreshIndicator(
          color: HomeColors.primaryOrange,
          onRefresh: () => ref.refresh(productListProvider(query).future),
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(
                HomeDims.pagePadding, 4, HomeDims.pagePadding, HomeDims.pagePadding),
            physics: const AlwaysScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: HomeDims.gridGap,
              crossAxisSpacing: HomeDims.gridGap,
              childAspectRatio: 0.64,
            ),
            itemCount: products.length,
            itemBuilder: (_, i) => ProductTile(product: products[i]),
          ),
        );
      },
    );
  }
}

/// Thông báo giữa màn (loading / rỗng).
class _CenterMessage extends StatelessWidget {
  const _CenterMessage({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(text, textAlign: TextAlign.center, style: HomeText.meta),
      ),
    );
  }
}

/// Thông báo lỗi + nút thử lại tự dựng.
class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center, style: HomeText.meta),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: HomeColors.primaryOrange,
                  borderRadius: BorderRadius.circular(HomeDims.radiusPill),
                ),
                child: const Text('Thử lại',
                    style: TextStyle(color: Color(0xFFFFFFFF), fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
