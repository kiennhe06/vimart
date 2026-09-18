import 'package:flutter/material.dart';

/// Hiển thị ảnh từ URL, có xử lý sẵn: đang tải, lỗi, và không có ảnh.
/// Dùng Image.network của Flutter (không cần thư viện ngoài).
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
      // Ảnh lỗi (link hỏng) -> hiện icon thay thế.
      errorBuilder: (context, error, stack) => _placeholder(Icons.broken_image_outlined),
    );
  }

  Widget _placeholder(IconData icon) => Container(
        color: Colors.grey.shade200,
        child: Icon(icon, color: Colors.grey),
      );
}
