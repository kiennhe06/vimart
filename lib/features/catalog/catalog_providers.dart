import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/category.dart';
import '../../models/product.dart';
import 'catalog_repository.dart';

/// Bộ lọc tìm sản phẩm. Dùng record để Riverpod tự so sánh (cache đúng theo bộ lọc).
typedef ProductQuery = ({String keyword, int? categoryId, String sort});

/// Danh sách danh mục (ít thay đổi).
final categoriesProvider = FutureProvider<List<Category>>((ref) {
  return ref.watch(catalogRepositoryProvider).listCategories();
});

/// Danh sách sản phẩm theo bộ lọc.
final productListProvider =
    FutureProvider.family<List<ProductCard>, ProductQuery>((ref, query) {
  return ref.watch(catalogRepositoryProvider).listProducts(
        keyword: query.keyword,
        categoryId: query.categoryId,
        sort: query.sort,
      );
});

/// Sản phẩm của 1 shop (dùng ở trang shop).
final shopProductsProvider = FutureProvider.family<List<ProductCard>, int>((ref, shopId) {
  return ref.watch(catalogRepositoryProvider).listProducts(shopId: shopId);
});

/// Chi tiết 1 sản phẩm theo id.
final productDetailProvider = FutureProvider.family<ProductDetail, int>((ref, id) {
  return ref.watch(catalogRepositoryProvider).getProduct(id);
});
