import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/i18n/app_strings.dart';

/// Hiển thị khi khách vãng lai mở một tab cần đăng nhập (Giỏ hàng, Đơn hàng...).
class LoginRequiredView extends ConsumerWidget {
  const LoginRequiredView({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              child: Text(ref.watch(stringsProvider).login),
            ),
          ],
        ),
      ),
    );
  }
}
