import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/providers.dart';
import '../auth/auth_provider.dart';

/// Một thông báo gửi tới người dùng.
class AppNotification {
  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    this.body,
    this.orderId,
    required this.isRead,
    this.createdAt,
  });

  final int id;
  final String type; // 'order_status' | 'review_reply'
  final String title;
  final String? body;
  final int? orderId;
  final bool isRead;
  final DateTime? createdAt;

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: (json['id'] as num).toInt(),
        type: json['type'] as String? ?? '',
        title: json['title'] as String? ?? '',
        body: json['body'] as String?,
        orderId: (json['orderId'] as num?)?.toInt(),
        isRead: json['isRead'] as bool? ?? false,
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      );
}

/// Truy cập API thông báo.
class NotificationRepository {
  NotificationRepository(this._api);
  final ApiClient _api;

  Future<List<AppNotification>> list() async {
    final data = await _api.get('/notifications');
    return (data as List<dynamic>)
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<int> unreadCount() async {
    final data = await _api.get('/notifications/unread-count') as Map<String, dynamic>;
    return (data['count'] as num?)?.toInt() ?? 0;
  }

  Future<void> markRead(int id) => _api.put('/notifications/$id/read');
  Future<void> markAllRead() => _api.put('/notifications/read-all');
}

final notificationRepositoryProvider =
    Provider<NotificationRepository>((ref) => NotificationRepository(ref.watch(apiClientProvider)));

/// Danh sách thông báo của người dùng (tự tải lại khi đăng nhập đổi).
final notificationsProvider = FutureProvider<List<AppNotification>>((ref) {
  final auth = ref.watch(authProvider);
  if (!auth.isLoggedIn) return Future.value(const []);
  return ref.watch(notificationRepositoryProvider).list();
});

/// Số thông báo chưa đọc (cho badge trên chuông).
final unreadCountProvider = FutureProvider<int>((ref) {
  final auth = ref.watch(authProvider);
  if (!auth.isLoggedIn) return Future.value(0);
  return ref.watch(notificationRepositoryProvider).unreadCount();
});
