import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Hiển thị khi khách vãng lai mở một tab cần đăng nhập (Giỏ hàng, Đơn hàng...).
class LoginRequiredView extends StatelessWidget {
  const LoginRequiredView({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 56, color: Colors.grey),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.push('/login'),
              child: const Text('Đăng nhập'),
            ),
          ],
        ),
      ),
    );
  }
}
