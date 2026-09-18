import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/providers.dart';
import '../../models/product.dart';
import '../auth/auth_provider.dart';

/// Truy cập API sản phẩm yêu thích.
class FavoriteRepository {
  FavoriteRepository(this._api);
  final ApiClient _api;

  Future<List<ProductCard>> list() async {
    final data = await _api.get('/favorites');
    return (data as List<dynamic>).map((e) => ProductCard.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> add(int productId) => _api.post('/favorites/$productId');
  Future<void> remove(int productId) => _api.delete('/favorites/$productId');
}

final favoriteRepositoryProvider =
    Provider<FavoriteRepository>((ref) => FavoriteRepository(ref.watch(apiClientProvider)));

/// Danh sách sản phẩm yêu thích của người dùng.
final favoritesProvider = FutureProvider<List<ProductCard>>((ref) {
  final auth = ref.watch(authProvider);
  if (!auth.isLoggedIn) return Future.value(const []);
  return ref.watch(favoriteRepositoryProvider).list();
});
