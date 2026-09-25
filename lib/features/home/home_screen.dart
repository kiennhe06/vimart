import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/motion.dart';
import '../../app/theme.dart';
import '../../core/i18n/app_strings.dart';
import '../../models/product.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_skeleton.dart';
import '../../widgets/async_view.dart';
import '../../widgets/entrance.dart';
import '../../widgets/pressable.dart';
import '../catalog/catalog_providers.dart';
import '../catalog/search_history.dart';
import 'home_ui.dart';
import 'widgets/category_circles.dart';
import 'widgets/product_tile.dart';
import 'widgets/vimart_header.dart';
import 'widgets/vimart_search_box.dart';

/// Trang chủ phong cách grocery: header, banner khuyến mãi, tìm kiếm nâng cao
/// (gõ có debounce + lịch sử + sắp xếp + bộ lọc giá/đánh giá), lưới sản phẩm.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  String _keyword = '';
  int? _categoryId;
  String _sort = 'best_selling';
  int? _minPrice;
  int? _maxPrice;
  double? _minRating;
  bool _searchFocused = false;

  bool get _hasFilters => _minPrice != null || _maxPrice != null || _minRating != null;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _keyword = value.trim());
    });
  }

  void _onSearchSubmitted(String value) {
    _debounce?.cancel();
    final v = value.trim();
    setState(() {
      _keyword = v;
      _searchFocused = false;
    });
    if (v.isNotEmpty) ref.read(searchHistoryProvider.notifier).add(v);
    FocusScope.of(context).unfocus();
  }

  void _applyHistory(String term) {
    _searchController.text = term;
    _onSearchSubmitted(term);
  }

  Future<void> _openFilters() async {
    final result = await showAppSheet<_Filters>(
      context,
      builder: (_) => _FilterSheet(
        initial: (minPrice: _minPrice, maxPrice: _maxPrice, minRating: _minRating),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _minPrice = result.minPrice;
        _maxPrice = result.maxPrice;
        _minRating = result.minRating;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = (
      keyword: _keyword,
      categoryId: _categoryId,
      sort: _sort,
      minPrice: _minPrice,
      maxPrice: _maxPrice,
      minRating: _minRating,
    );
    final productsAsync = ref.watch(productListProvider(query));
    final categoriesAsync = ref.watch(categoriesProvider);
    final history = ref.watch(searchHistoryProvider);
    final s = ref.watch(stringsProvider);
    final showHistory = _searchFocused && _keyword.isEmpty && history.isNotEmpty;

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
                        controller: _searchController,
                        hint: s.searchHint,
                        onChanged: _onSearchChanged,
                        onSubmitted: _onSearchSubmitted,
                        onFocusChange: (f) => setState(() => _searchFocused = f),
                      ),
                    ),
                    if (showHistory)
                      _historyPanel(s, history)
                    else ...[
                      FadeSlideIn(index: 2, child: _sortFilterBar(s)),
                      FadeSlideIn(
                        index: 3,
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
                      FadeSlideIn(index: 4, child: _sectionHeader(s, productsAsync)),
                      _buildProducts(productsAsync, query, s),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Thanh sắp xếp (chip cuộn ngang) + nút mở bộ lọc.
  Widget _sortFilterBar(AppStrings s) {
    final sorts = <(String, String)>[
      (s.sortBestSelling, 'best_selling'),
      (s.sortNewest, 'newest'),
      (s.sortPriceAsc, 'price_asc'),
      (s.sortPriceDesc, 'price_desc'),
      (s.sortRating, 'rating'),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(HomeDims.pagePadding, 2, HomeDims.pagePadding, 2),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final (label, value) in sorts) ...[
                    _sortChip(label, value),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          _filterButton(s),
        ],
      ),
    );
  }

  Widget _sortChip(String label, String value) {
    final sel = _sort == value;
    return Pressable(
      onTap: () => setState(() => _sort = value),
      scale: 0.94,
      child: AnimatedContainer(
        duration: AppMotion.dur(context, AppMotion.base),
        curve: AppMotion.emphasized,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: sel ? AppColors.brand : HomeColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: sel ? AppColors.brand : HomeColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: sel ? Colors.white : HomeColors.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _filterButton(AppStrings s) {
    return Pressable(
      onTap: _openFilters,
      scale: 0.9,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _hasFilters ? AppColors.brand : HomeColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _hasFilters ? AppColors.brand : HomeColors.border),
            ),
            child: Icon(Icons.tune_rounded,
                size: 20, color: _hasFilters ? Colors.white : HomeColors.textSecondary),
          ),
          if (_hasFilters)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.promo,
                  shape: BoxShape.circle,
                  border: Border.all(color: HomeColors.background, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Bảng lịch sử tìm kiếm (khi ô tìm đang focus và trống).
  Widget _historyPanel(AppStrings s, List<String> history) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(HomeDims.pagePadding, 4, HomeDims.pagePadding, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(s.recentSearches, style: HomeText.sectionTitle),
              const Spacer(),
              Pressable(
                onTap: () => ref.read(searchHistoryProvider.notifier).clear(),
                child: Text(s.clearAll,
                    style: const TextStyle(color: AppColors.brand, fontWeight: FontWeight.w600, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final term in history)
                Pressable(
                  onTap: () => _applyHistory(term),
                  scale: 0.95,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                    decoration: BoxDecoration(
                      color: HomeColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: HomeColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.history_rounded, size: 16, color: HomeColors.textSecondary),
                        const SizedBox(width: 6),
                        Text(term, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => ref.read(searchHistoryProvider.notifier).remove(term),
                          child: const Icon(Icons.close_rounded, size: 15, color: HomeColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(AppStrings s, AsyncValue<List<ProductCard>> async) {
    final subtitle = async.maybeWhen(
      data: (list) => s.resultsCount(list.length),
      orElse: () => '',
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(HomeDims.pagePadding, 8, HomeDims.pagePadding, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(_keyword.isEmpty ? s.forYou : '"$_keyword"', style: HomeText.sectionTitle),
          const SizedBox(width: 8),
          Text(subtitle, style: HomeText.meta),
        ],
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

/// Bộ lọc trả về từ sheet.
typedef _Filters = ({int? minPrice, int? maxPrice, double? minRating});

/// Sheet chọn khoảng giá + đánh giá tối thiểu.
class _FilterSheet extends ConsumerStatefulWidget {
  const _FilterSheet({required this.initial});
  final _Filters initial;
  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  late final _from = TextEditingController(text: widget.initial.minPrice?.toString() ?? '');
  late final _to = TextEditingController(text: widget.initial.maxPrice?.toString() ?? '');
  late double? _rating = widget.initial.minRating;

  @override
  void dispose() {
    _from.dispose();
    _to.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: HomeColors.border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Text(s.filters, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            Text(s.priceRange, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _from,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: s.priceFrom, isDense: true, prefixText: '₫ '),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _to,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: s.priceTo, isDense: true, prefixText: '₫ '),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(s.minRatingLabel, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _ratingChip(s.anyLabel, null),
                _ratingChip(s.ratingUp('3'), 3),
                _ratingChip(s.ratingUp('4'), 4),
                _ratingChip(s.ratingUp('4.5'), 4.5),
              ],
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(
                      context,
                      (minPrice: null, maxPrice: null, minRating: null),
                    ),
                    child: Text(s.reset),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(
                      context,
                      (
                        minPrice: int.tryParse(_from.text.trim()),
                        maxPrice: int.tryParse(_to.text.trim()),
                        minRating: _rating,
                      ),
                    ),
                    child: Text(s.apply),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _ratingChip(String label, double? value) {
    final sel = _rating == value;
    return Pressable(
      onTap: () => setState(() => _rating = value),
      scale: 0.94,
      child: AnimatedContainer(
        duration: AppMotion.dur(context, AppMotion.base),
        curve: AppMotion.emphasized,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: sel ? AppColors.brand : HomeColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: sel ? AppColors.brand : HomeColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: sel ? Colors.white : HomeColors.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
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
