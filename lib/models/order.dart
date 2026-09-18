/// Đơn hàng dạng tóm tắt (danh sách đơn).
class OrderSummary {
  OrderSummary({
    required this.id,
    required this.code,
    required this.groupCode,
    required this.shopId,
    this.shopName,
    this.buyerName,
    required this.status,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.total,
    this.createdAt,
  });

  final int id;
  final String code;
  final String groupCode;
  final int shopId;
  final String? shopName;
  final String? buyerName;
  final String status;
  final String paymentMethod;
  final String paymentStatus;
  final int total;
  final DateTime? createdAt;

  bool get isPaid => paymentStatus == 'paid';

  factory OrderSummary.fromJson(Map<String, dynamic> json) => OrderSummary(
        id: (json['id'] as num).toInt(),
        code: json['code'] as String? ?? '',
        groupCode: json['groupCode'] as String? ?? '',
        shopId: (json['shopId'] as num?)?.toInt() ?? 0,
        shopName: json['shopName'] as String?,
        buyerName: json['buyerName'] as String?,
        status: json['status'] as String? ?? 'pending',
        paymentMethod: json['paymentMethod'] as String? ?? 'cod',
        paymentStatus: json['paymentStatus'] as String? ?? 'unpaid',
        total: (json['total'] as num?)?.toInt() ?? 0,
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      );
}

/// Một dòng sản phẩm trong đơn.
class OrderItem {
  OrderItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.variantName,
    this.imageUrl,
    required this.price,
    required this.quantity,
    required this.reviewed,
  });

  final int id;
  final int? productId;
  final String productName;
  final String variantName;
  final String? imageUrl;
  final int price;
  final int quantity;
  final bool reviewed;

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        id: (json['id'] as num).toInt(),
        productId: (json['productId'] as num?)?.toInt(),
        productName: json['productName'] as String? ?? '',
        variantName: json['variantName'] as String? ?? '',
        imageUrl: json['imageUrl'] as String?,
        price: (json['price'] as num?)?.toInt() ?? 0,
        quantity: (json['quantity'] as num?)?.toInt() ?? 1,
        reviewed: json['reviewed'] as bool? ?? false,
      );
}

/// Chi tiết đầy đủ của 1 đơn.
class OrderDetail {
  OrderDetail({
    required this.summary,
    required this.recipientName,
    required this.recipientPhone,
    required this.addressText,
    required this.subtotal,
    required this.shippingFee,
    required this.discount,
    this.note,
    required this.items,
  });

  final OrderSummary summary;
  final String recipientName;
  final String recipientPhone;
  final String addressText;
  final int subtotal;
  final int shippingFee;
  final int discount;
  final String? note;
  final List<OrderItem> items;

  factory OrderDetail.fromJson(Map<String, dynamic> json) => OrderDetail(
        summary: OrderSummary.fromJson(json),
        recipientName: json['recipientName'] as String? ?? '',
        recipientPhone: json['recipientPhone'] as String? ?? '',
        addressText: json['addressText'] as String? ?? '',
        subtotal: (json['subtotal'] as num?)?.toInt() ?? 0,
        shippingFee: (json['shippingFee'] as num?)?.toInt() ?? 0,
        discount: (json['discount'] as num?)?.toInt() ?? 0,
        note: json['note'] as String?,
        items: (json['items'] as List<dynamic>? ?? [])
            .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
