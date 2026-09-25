import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/providers.dart';
import '../../models/category.dart';
import '../../models/product.dart';

/// Truy cập dữ liệu sản phẩm & danh mục (phần công khai, khách vãng lai xem được).
class CatalogRepository {
  CatalogRepository(this._api);
  final ApiClient _api;

  /// Tìm / lọc sản phẩm.
  Future<List<ProductCard>> listProducts({
    String? keyword,
    int? categoryId,
    int? shopId,
    String sort = 'newest',
    int? minPrice,
    int? maxPrice,
    double? minRating,
  }) async {
    final data = await _api.get('/products', query: {
      if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
      'categoryId': ?categoryId,
      'shopId': ?shopId,
      'minPrice': ?minPrice,
      'maxPrice': ?maxPrice,
      'minRating': ?minRating,
      'sort': sort,
      'limit': 50,
    });
    final items = (data['items'] as List<dynamic>? ?? []);
    return items.map((e) => ProductCard.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Chi tiết 1 sản phẩm.
  Future<ProductDetail> getProduct(int id) async {
    final data = await _api.get('/products/$id');
    return ProductDetail.fromJson(data as Map<String, dynamic>);
  }

  /// Danh sách danh mục.
  Future<List<Category>> listCategories() async {
    final data = await _api.get('/categories');
    return (data as List<dynamic>).map((e) => Category.fromJson(e as Map<String, dynamic>)).toList();
  }
}

final catalogRepositoryProvider =
    Provider<CatalogRepository>((ref) => CatalogRepository(ref.watch(apiClientProvider)));
