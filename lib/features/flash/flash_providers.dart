import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/providers.dart';

/// Một sản phẩm trong đợt flash sale.
class FlashProduct {
  FlashProduct({
    required this.productId,
    required this.name,
    this.imageUrl,
    required this.discountPercent,
    required this.price,
    required this.salePrice,
    required this.sold,
    this.qtyLimit,
  });

  final int productId;
  final String name;
  final String? imageUrl;
  final int discountPercent;
  final int price;
  final int salePrice;
  final int sold;
  final int? qtyLimit;

  factory FlashProduct.fromJson(Map<String, dynamic> j) => FlashProduct(
        productId: (j['productId'] as num).toInt(),
        name: j['name'] as String? ?? '',
        imageUrl: j['imageUrl'] as String?,
        discountPercent: (j['discountPercent'] as num?)?.toInt() ?? 0,
        price: (j['price'] as num?)?.toInt() ?? 0,
        salePrice: (j['salePrice'] as num?)?.toInt() ?? 0,
        sold: (j['sold'] as num?)?.toInt() ?? 0,
        qtyLimit: (j['qtyLimit'] as num?)?.toInt(),
      );
}

/// Một đợt flash sale đang chạy.
class FlashSale {
  FlashSale({required this.id, required this.name, this.endsAt, required this.items});
  final int id;
  final String name;
  final DateTime? endsAt;
  final List<FlashProduct> items;

  factory FlashSale.fromJson(Map<String, dynamic> j) => FlashSale(
        id: (j['id'] as num).toInt(),
        name: j['name'] as String? ?? '',
        endsAt: DateTime.tryParse(j['endsAt']?.toString() ?? ''),
        items: (j['items'] as List<dynamic>? ?? [])
            .map((e) => FlashProduct.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class FlashRepository {
  FlashRepository(this._api);
  final ApiClient _api;

  Future<List<FlashSale>> active() async {
    final data = await _api.get('/flash-sales/active');
    return (data as List<dynamic>)
        .map((e) => FlashSale.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

final flashRepositoryProvider =
    Provider<FlashRepository>((ref) => FlashRepository(ref.watch(apiClientProvider)));

/// Các đợt flash sale đang chạy (public, không cần đăng nhập).
final activeFlashProvider = FutureProvider<List<FlashSale>>((ref) {
  return ref.watch(flashRepositoryProvider).active();
});
