/// Thông tin flash sale đang áp cho 1 sản phẩm (null nếu không có).
class FlashInfo {
  FlashInfo({required this.discountPercent, required this.salePrice, this.endsAt});
  final int discountPercent;
  final int salePrice;
  final DateTime? endsAt;

  factory FlashInfo.fromJson(Map<String, dynamic> j) => FlashInfo(
        discountPercent: (j['discountPercent'] as num?)?.toInt() ?? 0,
        salePrice: (j['salePrice'] as num?)?.toInt() ?? 0,
        endsAt: DateTime.tryParse(j['endsAt']?.toString() ?? ''),
      );

  static FlashInfo? maybe(dynamic j) =>
      j == null ? null : FlashInfo.fromJson(j as Map<String, dynamic>);
}

/// Sản phẩm dạng thẻ (dùng ở danh sách / trang chủ / tìm kiếm).
class ProductCard {
  ProductCard({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.shopId,
    this.shopName,
    required this.minPrice,
    required this.maxPrice,
    required this.soldCount,
    required this.ratingAvg,
    required this.ratingCount,
    this.flashSale,
  });

  final int id;
  final String name;
  final String? imageUrl;
  final int shopId;
  final String? shopName;
  final int minPrice;
  final int maxPrice;
  final int soldCount;
  final double ratingAvg;
  final int ratingCount;
  final FlashInfo? flashSale;

  bool get hasPriceRange => maxPrice > minPrice;

  factory ProductCard.fromJson(Map<String, dynamic> json) => ProductCard(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String? ?? '',
        imageUrl: json['imageUrl'] as String?,
        shopId: (json['shopId'] as num?)?.toInt() ?? 0,
        shopName: json['shopName'] as String?,
        minPrice: (json['minPrice'] as num?)?.toInt() ?? 0,
        maxPrice: (json['maxPrice'] as num?)?.toInt() ?? 0,
        soldCount: (json['soldCount'] as num?)?.toInt() ?? 0,
        ratingAvg: (json['ratingAvg'] as num?)?.toDouble() ?? 0,
        ratingCount: (json['ratingCount'] as num?)?.toInt() ?? 0,
        flashSale: FlashInfo.maybe(json['flashSale']),
      );
}

/// Một phân loại (size/màu) của sản phẩm — chứa giá và tồn kho.
class Variant {
  Variant({required this.id, required this.name, required this.price, required this.stock});

  final int id;
  final String name;
  final int price;
  final int stock;

  bool get inStock => stock > 0;

  factory Variant.fromJson(Map<String, dynamic> json) => Variant(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String? ?? 'Mặc định',
        price: (json['price'] as num?)?.toInt() ?? 0,
        stock: (json['stock'] as num?)?.toInt() ?? 0,
      );
}

/// Đánh giá của người mua.
class Review {
  Review({
    required this.id,
    required this.rating,
    this.comment,
    this.userName,
    this.createdAt,
    this.reply,
  });

  final int id;
  final int rating;
  final String? comment;
  final String? userName;
  final DateTime? createdAt;

  /// Phản hồi của admin cho đánh giá này (null nếu chưa có).
  final String? reply;

  factory Review.fromJson(Map<String, dynamic> json) => Review(
        id: (json['id'] as num).toInt(),
        rating: (json['rating'] as num?)?.toInt() ?? 0,
        comment: json['comment'] as String?,
        userName: json['userName'] as String?,
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
        reply: json['reply'] as String?,
      );
}

/// Thông tin shop rút gọn trong trang chi tiết.
class ProductShop {
  ProductShop({required this.id, required this.name, this.avatarUrl});

  final int id;
  final String name;
  final String? avatarUrl;

  factory ProductShop.fromJson(Map<String, dynamic> json) => ProductShop(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String? ?? '',
        avatarUrl: json['avatarUrl'] as String?,
      );
}

/// Chi tiết đầy đủ của 1 sản phẩm.
class ProductDetail {
  ProductDetail({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    required this.soldCount,
    required this.ratingAvg,
    required this.ratingCount,
    required this.shop,
    required this.variants,
    required this.reviews,
    this.flashSale,
  });

  final int id;
  final String name;
  final String? description;
  final String? imageUrl;
  final int soldCount;
  final double ratingAvg;
  final int ratingCount;
  final ProductShop shop;
  final List<Variant> variants;
  final List<Review> reviews;
  final FlashInfo? flashSale;

  int get minPrice =>
      variants.isEmpty ? 0 : variants.map((v) => v.price).reduce((a, b) => a < b ? a : b);

  factory ProductDetail.fromJson(Map<String, dynamic> json) => ProductDetail(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String? ?? '',
        description: json['description'] as String?,
        imageUrl: json['imageUrl'] as String?,
        soldCount: (json['soldCount'] as num?)?.toInt() ?? 0,
        ratingAvg: (json['ratingAvg'] as num?)?.toDouble() ?? 0,
        ratingCount: (json['ratingCount'] as num?)?.toInt() ?? 0,
        shop: ProductShop.fromJson(json['shop'] as Map<String, dynamic>),
        variants: (json['variants'] as List<dynamic>? ?? [])
            .map((e) => Variant.fromJson(e as Map<String, dynamic>))
            .toList(),
        reviews: (json['reviews'] as List<dynamic>? ?? [])
            .map((e) => Review.fromJson(e as Map<String, dynamic>))
            .toList(),
        flashSale: FlashInfo.maybe(json['flashSale']),
      );
}
