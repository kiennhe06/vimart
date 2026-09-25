import 'package:flutter/material.dart';

import '../app/motion.dart';

/// Hiển thị ảnh từ URL, có xử lý sẵn: đang tải, lỗi, và không có ảnh.
/// Ảnh mờ dần khi tải xong (không "nhảy bụp"). Dùng Image.network (không thư viện ngoài).
class NetworkImageBox extends StatelessWidget {
  const NetworkImageBox({super.key, required this.url, this.fit = BoxFit.cover});

  final String? url;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) return _placeholder(Icons.image_not_supported_outlined);

    return Image.network(
      url!,
      fit: fit,
      // Hiển thị nền xám mờ trong lúc tải ảnh.
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(color: Colors.grey.shade100);
      },
      // Mờ dần ảnh khi frame đầu tiên sẵn sàng (bỏ hiệu ứng "pop" cứng).
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: AppMotion.dur(context, const Duration(milliseconds: 320)),
          curve: AppMotion.enter,
          child: child,
        );
      },
      // Ảnh lỗi (link hỏng) -> hiện icon thay thế.
      errorBuilder: (context, error, stack) => _placeholder(Icons.broken_image_outlined),
    );
  }

  Widget _placeholder(IconData icon) => Container(
        color: Colors.grey.shade200,
        child: Icon(icon, color: Colors.grey),
      );
}
