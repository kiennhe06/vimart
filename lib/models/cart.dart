/// Một dòng trong giỏ hàng.
class CartItem {
  CartItem({
    required this.cartItemId,
    required this.variantId,
    required this.variantName,
    required this.productId,
    required this.productName,
    this.imageUrl,
    required this.price,
    required this.stock,
    required this.quantity,
    required this.lineTotal,
  });

  final int cartItemId;
  final int variantId;
  final String variantName;
  final int productId;
  final String productName;
  final String? imageUrl;
  final int price;
  final int stock;
  final int quantity;
  final int lineTotal;

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        cartItemId: (json['cartItemId'] as num).toInt(),
        variantId: (json['variantId'] as num).toInt(),
        variantName: json['variantName'] as String? ?? '',
        productId: (json['productId'] as num).toInt(),
        productName: json['productName'] as String? ?? '',
        imageUrl: json['imageUrl'] as String?,
        price: (json['price'] as num?)?.toInt() ?? 0,
        stock: (json['stock'] as num?)?.toInt() ?? 0,
        quantity: (json['quantity'] as num?)?.toInt() ?? 1,
        lineTotal: (json['lineTotal'] as num?)?.toInt() ?? 0,
      );
}

/// Nhóm các món trong giỏ theo shop.
class CartShop {
  CartShop({required this.shopId, required this.shopName, required this.items});

  final int shopId;
  final String shopName;
  final List<CartItem> items;

  factory CartShop.fromJson(Map<String, dynamic> json) => CartShop(
        shopId: (json['shopId'] as num).toInt(),
        shopName: json['shopName'] as String? ?? '',
        items: (json['items'] as List<dynamic>? ?? [])
            .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Toàn bộ giỏ hàng.
class Cart {
  Cart({required this.shops, required this.subtotal, required this.itemCount});

  final List<CartShop> shops;
  final int subtotal;
  final int itemCount;

  bool get isEmpty => itemCount == 0;

  factory Cart.fromJson(Map<String, dynamic> json) => Cart(
        shops: (json['shops'] as List<dynamic>? ?? [])
            .map((e) => CartShop.fromJson(e as Map<String, dynamic>))
            .toList(),
        subtotal: (json['subtotal'] as num?)?.toInt() ?? 0,
        itemCount: (json['itemCount'] as num?)?.toInt() ?? 0,
      );
}
