import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../core/constants.dart';
import '../../core/providers.dart';
import '../auth/auth_provider.dart';
import 'chat_providers.dart';

/// Kết nối WebSocket tới server để nhận tin nhắn real-time.
/// Tự kết nối lại khi rớt mạng; phát tin qua [messages] (broadcast).
class ChatSocket {
  ChatSocket({required this.token, required this.myUserId}) {
    if (token != null && token!.isNotEmpty) _connect();
  }

  final String? token;
  final int myUserId;

  final _controller = StreamController<ChatMessage>.broadcast();
  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  Timer? _retry;
  bool _disposed = false;

  Stream<ChatMessage> get messages => _controller.stream;

  Uri get _wsUri {
    final base = Uri.parse(kApiBaseUrl); // http://host:port/api
    return base.replace(
      scheme: base.scheme == 'https' ? 'wss' : 'ws',
      path: '/ws',
      queryParameters: {'token': token!},
    );
  }

  void _connect() {
    if (_disposed) return;
    try {
      _channel = WebSocketChannel.connect(_wsUri);
      _sub = _channel!.stream.listen(
        (data) {
          try {
            final json = jsonDecode(data as String) as Map<String, dynamic>;
            if (json['type'] == 'message' && json['message'] != null) {
              _controller.add(
                ChatMessage.fromWs(json['message'] as Map<String, dynamic>, myUserId),
              );
            }
          } catch (_) {
            // bỏ qua gói tin lỗi
          }
        },
        onDone: _scheduleReconnect,
        onError: (_) => _scheduleReconnect(),
        cancelOnError: true,
      );
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_disposed) return;
    _sub?.cancel();
    _channel = null;
    _retry?.cancel();
    _retry = Timer(const Duration(seconds: 3), _connect);
  }

  void dispose() {
    _disposed = true;
    _retry?.cancel();
    _sub?.cancel();
    _channel?.sink.close();
    _controller.close();
  }
}

/// Socket dùng chung. Kết nối lại khi đăng nhập đổi; khi có tin mới thì tự làm
/// mới danh sách hội thoại + badge chưa đọc để cập nhật real-time ở mọi nơi.
final chatSocketProvider = Provider<ChatSocket>((ref) {
  final auth = ref.watch(authProvider);
  final token = ref.watch(apiClientProvider).token;
  final socket = ChatSocket(
    token: auth.isLoggedIn ? token : null,
    myUserId: auth.user?.id ?? 0,
  );
  final sub = socket.messages.listen((_) {
    ref.invalidate(chatUnreadProvider);
    ref.invalidate(conversationsProvider);
  });
  ref.onDispose(() {
    sub.cancel();
    socket.dispose();
  });
  return socket;
});
