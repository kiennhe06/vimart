import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/design.dart';
import '../../app/theme.dart';
import '../../core/format.dart';
import '../../core/i18n/app_strings.dart';
import '../../widgets/app_skeleton.dart';
import '../../widgets/async_view.dart';
import '../../widgets/entrance.dart';
import 'notification_providers.dart';

/// Màn hình danh sách thông báo của người dùng.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(notificationsProvider);
    final s = ref.watch(stringsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(s.notifications),
        actions: [
          TextButton(
            onPressed: () async {
              await ref.read(notificationRepositoryProvider).markAllRead();
              ref.invalidate(notificationsProvider);
              ref.invalidate(unreadCountProvider);
            },
            child: Text(s.markAllRead),
          ),
        ],
      ),
      body: AsyncView(
        value: async,
        loading: const SkeletonList(count: 6),
        onRetry: () => ref.invalidate(notificationsProvider),
        data: (items) {
          if (items.isEmpty) {
            return EmptyView(message: s.noNotifications, sticker: 'bell');
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(notificationsProvider);
              ref.invalidate(unreadCountProvider);
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) => FadeSlideIn(
                index: i,
                child: _NotificationTile(items[i]),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  const _NotificationTile(this.n);
  final AppNotification n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOrder = n.type == 'order_status';
    final icon = isOrder ? Icons.local_shipping_outlined : Icons.reviews_outlined;
    return Material(
      color: n.isRead ? context.c.surface : AppColors.accent.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          if (!n.isRead) {
            await ref.read(notificationRepositoryProvider).markRead(n.id);
            ref.invalidate(notificationsProvider);
            ref.invalidate(unreadCountProvider);
          }
          if (isOrder && n.orderId != null && context.mounted) {
            context.push('/order/${n.orderId}');
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.accent.withValues(alpha: 0.14),
                child: Icon(icon, color: AppColors.accent, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(n.title,
                              style: TextStyle(
                                  fontWeight: n.isRead ? FontWeight.w600 : FontWeight.w800)),
                        ),
                        if (!n.isRead)
                          Container(
                            width: 9,
                            height: 9,
                            margin: const EdgeInsets.only(left: 6, top: 4),
                            decoration: const BoxDecoration(
                                color: AppColors.accent, shape: BoxShape.circle),
                          ),
                      ],
                    ),
                    if (n.body != null && n.body!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(n.body!, style: TextStyle(color: context.c.textSecondary)),
                      ),
                    if (n.createdAt != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(formatDateTime(n.createdAt!),
                            style: TextStyle(fontSize: 12, color: context.c.textSecondary)),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
