import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/format.dart';
import '../../../models/product.dart';
import '../../../widgets/network_image_box.dart';

/// Thẻ sản phẩm hiển thị trong lưới. Bấm vào mở trang chi tiết.
class ProductCardView extends StatelessWidget {
  const ProductCardView({super.key, required this.product});
  final ProductCard product;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => context.push('/product/${product.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: NetworkImageBox(url: product.imageUrl),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, height: 1.3),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    formatVnd(product.minPrice),
                    style: const TextStyle(
                        color: AppColors.brand, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 13, color: AppColors.accent),
                      const SizedBox(width: 2),
                      Text(
                        product.ratingCount > 0 ? product.ratingAvg.toStringAsFixed(1) : 'Mới',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      const Spacer(),
                      Text('Đã bán ${product.soldCount}',
                          style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
