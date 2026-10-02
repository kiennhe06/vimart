import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/providers.dart';
import '../auth/auth_provider.dart';

/// Một hội thoại (theo góc nhìn của người đang đăng nhập).
class ChatConversation {
  ChatConversation({
    required this.id,
    required this.role,
    required this.title,
    this.avatarUrl,
    required this.shopId,
    this.lastMessage,
    this.lastMessageAt,
    required this.unread,
  });

  final int id;
  final String role; // 'buyer' | 'seller'
  final String title; // tên phía bên kia (shop hoặc khách)
  final String? avatarUrl;
  final int shopId;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unread;

  factory ChatConversation.fromJson(Map<String, dynamic> j) => ChatConversation(
        id: (j['id'] as num).toInt(),
        role: j['role'] as String? ?? 'buyer',
        title: j['title'] as String? ?? '',
        avatarUrl: j['avatarUrl'] as String?,
        shopId: (j['shopId'] as num?)?.toInt() ?? 0,
        lastMessage: j['lastMessage'] as String?,
        lastMessageAt: DateTime.tryParse(j['lastMessageAt']?.toString() ?? ''),
        unread: (j['unread'] as num?)?.toInt() ?? 0,
      );
}

/// Một tin nhắn.
class ChatMessage {
  ChatMessage({
    required this.id,
    this.conversationId,
    required this.senderId,
    required this.body,
    required this.mine,
    this.createdAt,
  });

  final int id;
  final int? conversationId;
  final int senderId;
  final String body;
  final bool mine;
  final DateTime? createdAt;

  /// Dùng cho tin đọc qua REST (`mine` đã có sẵn từ server).
  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
        id: (j['id'] as num).toInt(),
        conversationId: (j['conversationId'] as num?)?.toInt(),
        senderId: (j['senderId'] as num?)?.toInt() ?? 0,
        body: j['body'] as String? ?? '',
        mine: j['mine'] as bool? ?? false,
        createdAt: DateTime.tryParse(j['createdAt']?.toString() ?? ''),
      );

  /// Tin đẩy qua WebSocket không có cờ `mine` -> tự suy theo `myUserId`.
  factory ChatMessage.fromWs(Map<String, dynamic> j, int myUserId) => ChatMessage(
        id: (j['id'] as num).toInt(),
        conversationId: (j['conversationId'] as num?)?.toInt(),
        senderId: (j['senderId'] as num?)?.toInt() ?? 0,
        body: j['body'] as String? ?? '',
        mine: ((j['senderId'] as num?)?.toInt() ?? 0) == myUserId,
        createdAt: DateTime.tryParse(j['createdAt']?.toString() ?? ''),
      );
}

/// Truy cập API chat.
class ChatRepository {
  ChatRepository(this._api);
  final ApiClient _api;

  Future<List<ChatConversation>> conversations() async {
    final data = await _api.get('/chat/conversations');
    return (data as List<dynamic>)
        .map((e) => ChatConversation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ChatConversation> openWithShop(int shopId) async {
    final data = await _api.post('/chat/conversations', body: {'shopId': shopId});
    return ChatConversation.fromJson(data as Map<String, dynamic>);
  }

  Future<List<ChatMessage>> messages(int conversationId) async {
    final data = await _api.get('/chat/conversations/$conversationId/messages');
    return (data as List<dynamic>)
        .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ChatMessage> send(int conversationId, String body) async {
    final data = await _api.post('/chat/conversations/$conversationId/messages', body: {'body': body});
    return ChatMessage.fromJson({...data as Map<String, dynamic>, 'mine': true});
  }

  Future<int> unreadCount() async {
    final data = await _api.get('/chat/unread-count') as Map<String, dynamic>;
    return (data['count'] as num?)?.toInt() ?? 0;
  }
}

final chatRepositoryProvider =
    Provider<ChatRepository>((ref) => ChatRepository(ref.watch(apiClientProvider)));

/// Danh sách hội thoại (tự tải lại khi đăng nhập đổi).
final conversationsProvider = FutureProvider<List<ChatConversation>>((ref) {
  final auth = ref.watch(authProvider);
  if (!auth.isLoggedIn) return Future.value(const []);
  return ref.watch(chatRepositoryProvider).conversations();
});

/// Tổng tin chưa đọc (badge).
final chatUnreadProvider = FutureProvider<int>((ref) {
  final auth = ref.watch(authProvider);
  if (!auth.isLoggedIn) return Future.value(0);
  return ref.watch(chatRepositoryProvider).unreadCount();
});
