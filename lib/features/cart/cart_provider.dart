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

/// Tập `variantId` đang được chọn để thanh toán (kiểu Shopee).
///
/// - Món mới thêm vào giỏ mặc định được chọn.
/// - Món bị xóa khỏi giỏ tự động loại khỏi lựa chọn.
/// Lựa chọn được giữ khi đổi số lượng, và chia sẻ giữa màn Giỏ ↔ Thanh toán.
class CartSelectionNotifier extends Notifier<Set<int>> {
  Set<int> _known = {};
  Set<int> _sel = {};

  @override
  Set<int> build() {
    final cart = ref.watch(cartProvider).asData?.value;
    final ids = <int>{};
    if (cart != null) {
      for (final shop in cart.shops) {
        for (final item in shop.items) {
          ids.add(item.variantId);
        }
      }
    }
    final newly = ids.difference(_known); // món mới xuất hiện -> tự chọn
    _sel = {..._sel.where(ids.contains), ...newly};
    _known = ids;
    return _sel;
  }

  void toggle(int variantId) {
    final next = {..._sel};
    if (!next.add(variantId)) next.remove(variantId);
    _sel = next;
    state = next;
  }

  /// Chọn/bỏ chọn nhiều variant cùng lúc (chọn-tất-cả theo shop hoặc toàn giỏ).
  void setMany(Iterable<int> ids, bool selected) {
    final next = {..._sel};
    if (selected) {
      next.addAll(ids);
    } else {
      next.removeAll(ids);
    }
    _sel = next;
    state = next;
  }
}

final cartSelectionProvider =
    NotifierProvider<CartSelectionNotifier, Set<int>>(CartSelectionNotifier.new);

/// Tổng kết phần giỏ ĐANG CHỌN (tiền hàng, số lượng, số shop) để hiển thị &
/// tính phí ship theo số shop có món được chọn.
class SelectedCartSummary {
  const SelectedCartSummary({required this.subtotal, required this.count, required this.shopCount});
  final int subtotal;
  final int count;
  final int shopCount;
}

final selectedCartSummaryProvider = Provider<SelectedCartSummary>((ref) {
  final cart = ref.watch(cartProvider).asData?.value;
  final selected = ref.watch(cartSelectionProvider);
  int subtotal = 0;
  int count = 0;
  final shopIds = <int>{};
  if (cart != null) {
    for (final shop in cart.shops) {
      for (final item in shop.items) {
        if (selected.contains(item.variantId)) {
          subtotal += item.lineTotal;
          count += item.quantity;
          shopIds.add(shop.shopId);
        }
      }
    }
  }
  return SelectedCartSummary(subtotal: subtotal, count: count, shopCount: shopIds.length);
});
