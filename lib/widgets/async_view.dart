import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/design.dart';
import '../app/motion.dart';
import '../core/i18n/app_strings.dart';

/// Các widget dùng chung để hiển thị 4 trạng thái: loading / error / empty / data.
/// Giúp mọi màn hình xử lý bất đồng bộ nhất quán, không lặp code.

/// Xuất hiện mềm: mờ + phóng nhẹ từ 0.92 (tôn trọng giảm chuyển động).
class _PopIn extends StatelessWidget {
  const _PopIn({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    if (context.reduceMotion) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.base,
      curve: AppMotion.enter,
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0, 1),
        child: Transform.scale(scale: 0.92 + 0.08 * t, child: child),
      ),
      child: child,
    );
  }
}

/// Đang tải.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});
  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
}

/// Lỗi kèm nút thử lại.
class ErrorView extends ConsumerWidget {
  const ErrorView({super.key, required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: _PopIn(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center),
              if (onRetry != null) ...[
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: Text(ref.watch(stringsProvider).retry),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Không có dữ liệu.
class EmptyView extends StatelessWidget {
  const EmptyView({super.key, required this.message, this.icon = Icons.inbox_outlined});
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: _PopIn(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 56, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center, style: TextStyle(color: context.c.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bọc AsyncValue của Riverpod, tự chọn view phù hợp.
/// [loading] cho phép truyền skeleton riêng; mặc định là spinner.
/// Chuyển giữa loading → data/error được cross-fade nhẹ nhàng.
class AsyncView<T> extends StatelessWidget {
  const AsyncView({
    super.key,
    required this.value,
    required this.data,
    this.onRetry,
    this.loading,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final VoidCallback? onRetry;
  final Widget? loading;

  @override
  Widget build(BuildContext context) {
    final child = value.when(
      // Khi TẢI LẠI (đã có dữ liệu cũ) -> giữ nội dung, cập nhật im lặng, KHÔNG
      // nháy skeleton. Chỉ hiện loading ở lần tải đầu.
      skipLoadingOnReload: true,
      data: data,
      loading: () => loading ?? const LoadingView(),
      error: (err, _) => ErrorView(message: err.toString(), onRetry: onRetry),
    );
    // Giữ nội dung khi refresh (hasValue); chỉ đổi phase khi thật sự đổi trạng thái.
    final phase = value.hasValue
        ? 'data'
        : value.hasError
            ? 'error'
            : 'loading';
    return AnimatedSwitcher(
      duration: AppMotion.dur(context, AppMotion.base),
      switchInCurve: AppMotion.enter,
      switchOutCurve: AppMotion.exit,
      child: KeyedSubtree(key: ValueKey(phase), child: child),
    );
  }
}
