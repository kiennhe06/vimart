import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/providers.dart';
import '../../models/cart.dart';
import '../auth/auth_provider.dart';

/// Truy cập API giỏ hàng. Mọi thao tác trả về giỏ hàng đã cập nhật.
class CartRepository {
  CartRepository(this._api);
  final ApiClient _api;

  Future<Cart> get() async => Cart.fromJson(await _api.get('/cart') as Map<String, dynamic>);

  Future<Cart> add(int variantId, int quantity) async => Cart.fromJson(
      await _api.post('/cart/items', body: {'variantId': variantId, 'quantity': quantity})
          as Map<String, dynamic>);

  Future<Cart> updateQuantity(int cartItemId, int quantity) async => Cart.fromJson(
      await _api.put('/cart/items/$cartItemId', body: {'quantity': quantity}) as Map<String, dynamic>);

  Future<Cart> remove(int cartItemId) async =>
      Cart.fromJson(await _api.delete('/cart/items/$cartItemId') as Map<String, dynamic>);

  Future<Cart> clear() async => Cart.fromJson(await _api.delete('/cart') as Map<String, dynamic>);
}

final cartRepositoryProvider =
    Provider<CartRepository>((ref) => CartRepository(ref.watch(apiClientProvider)));

/// Trạng thái giỏ hàng, tự đồng bộ với server.
class CartNotifier extends AsyncNotifier<Cart> {
  CartRepository get _repo => ref.read(cartRepositoryProvider);

  @override
  Future<Cart> build() async {
    // Giỏ hàng gắn với người dùng -> theo dõi đăng nhập để tải lại khi login/logout.
    final auth = ref.watch(authProvider);
    if (!auth.isLoggedIn) {
      return Cart(shops: const [], subtotal: 0, itemCount: 0);
    }
    return _repo.get();
  }

  Future<void> add(int variantId, int quantity) async {
    state = AsyncData(await _repo.add(variantId, quantity));
  }

  Future<void> updateQuantity(int cartItemId, int quantity) async {
    state = AsyncData(await _repo.updateQuantity(cartItemId, quantity));
  }

  Future<void> remove(int cartItemId) async {
    state = AsyncData(await _repo.remove(cartItemId));
  }

  Future<void> reload() async {
    state = AsyncData(await _repo.get());
  }
}

final cartProvider = AsyncNotifierProvider<CartNotifier, Cart>(CartNotifier.new);

/// Số lượng món trong giỏ (dùng cho badge trên bottom nav).
final cartCountProvider = Provider<int>((ref) {
  return ref.watch(cartProvider).maybeWhen(data: (c) => c.itemCount, orElse: () => 0);
});
