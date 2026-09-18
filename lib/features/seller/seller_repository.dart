import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/providers.dart';
import '../../models/product.dart';
import '../auth/auth_provider.dart';

/// Dữ liệu 1 phân loại khi tạo/sửa sản phẩm.
class VariantInput {
  VariantInput({required this.name, required this.price, required this.stock});
  final String name;
  final int price;
  final int stock;

  Map<String, dynamic> toJson() => {'name': name, 'price': price, 'stock': stock};
}

/// Truy cập API dành cho người bán (shop + sản phẩm của shop).
class SellerRepository {
  SellerRepository(this._api);
  final ApiClient _api;

  Future<void> createShop({required String name, String? description}) =>
      _api.post('/shops', body: {'name': name, 'description': description});

  Future<void> updateShop({required String name, String? description}) =>
      _api.put('/shops/me', body: {'name': name, 'description': description});

  Future<List<ProductCard>> myProducts() async {
    final data = await _api.get('/products/mine');
    return (data as List<dynamic>).map((e) => ProductCard.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> createProduct({
    required String name,
    String? description,
    int? categoryId,
    String? imageUrl,
    required List<VariantInput> variants,
  }) =>
      _api.post('/products', body: _productBody(name, description, categoryId, imageUrl, variants));

  Future<void> updateProduct({
    required int id,
    required String name,
    String? description,
    int? categoryId,
    String? imageUrl,
    required List<VariantInput> variants,
  }) =>
      _api.put('/products/$id', body: _productBody(name, description, categoryId, imageUrl, variants));

  Future<void> deleteProduct(int id) => _api.delete('/products/$id');

  Map<String, dynamic> _productBody(
    String name,
    String? description,
    int? categoryId,
    String? imageUrl,
    List<VariantInput> variants,
  ) =>
      {
        'name': name,
        'description': description,
        'categoryId': categoryId,
        'imageUrl': (imageUrl != null && imageUrl.isNotEmpty) ? imageUrl : null,
        'variants': variants.map((v) => v.toJson()).toList(),
      };
}

final sellerRepositoryProvider =
    Provider<SellerRepository>((ref) => SellerRepository(ref.watch(apiClientProvider)));

/// Danh sách sản phẩm của shop tôi.
final myProductsProvider = FutureProvider<List<ProductCard>>((ref) {
  final auth = ref.watch(authProvider);
  if (!auth.isLoggedIn) return Future.value(const []);
  return ref.watch(sellerRepositoryProvider).myProducts();
});
