import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../models/user.dart';
import 'auth_repository.dart';

/// Trạng thái đăng nhập của app.
class AuthState {
  const AuthState({this.loading = true, this.user});

  /// true khi đang kiểm tra token lúc mở app (chưa biết đăng nhập hay chưa).
  final bool loading;
  final User? user;

  bool get isLoggedIn => user != null;

  AuthState copyWith({bool? loading, User? user, bool clearUser = false}) => AuthState(
        loading: loading ?? this.loading,
        user: clearUser ? null : (user ?? this.user),
      );
}

/// Quản lý đăng nhập/đăng xuất và giữ thông tin người dùng.
class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    _restoreSession();
    return const AuthState(loading: true);
  }

  /// Khi mở app: đọc token đã lưu, nếu còn hợp lệ thì tự đăng nhập lại.
  Future<void> _restoreSession() async {
    final token = await ref.read(tokenStorageProvider).read();
    if (token == null) {
      state = const AuthState(loading: false);
      return;
    }
    ref.read(apiClientProvider).token = token;
    try {
      final user = await ref.read(authRepositoryProvider).me();
      state = AuthState(loading: false, user: user);
    } catch (_) {
      // Token hỏng/hết hạn -> xóa và coi như chưa đăng nhập
      await ref.read(tokenStorageProvider).clear();
      ref.read(apiClientProvider).token = null;
      state = const AuthState(loading: false);
    }
  }

  Future<void> login(String email, String password) async {
    final (user, token) = await ref.read(authRepositoryProvider).login(email, password);
    await _persist(user, token);
  }

  Future<void> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    final (user, token) = await ref
        .read(authRepositoryProvider)
        .register(email: email, password: password, fullName: fullName, phone: phone);
    await _persist(user, token);
  }

  /// Tải lại thông tin người dùng (vd sau khi mở shop).
  Future<void> refreshUser() async {
    final user = await ref.read(authRepositoryProvider).me();
    state = state.copyWith(user: user);
  }

  Future<void> logout() async {
    await ref.read(tokenStorageProvider).clear();
    ref.read(apiClientProvider).token = null;
    state = const AuthState(loading: false, user: null);
  }

  Future<void> _persist(User user, String token) async {
    await ref.read(tokenStorageProvider).save(token);
    ref.read(apiClientProvider).token = token;
    // /auth/login chỉ trả thông tin cơ bản (không kèm shop). Gọi /auth/me để lấy
    // đầy đủ (biết người dùng đã có shop hay chưa) rồi mới cập nhật trạng thái.
    try {
      state = AuthState(loading: false, user: await ref.read(authRepositoryProvider).me());
    } catch (_) {
      state = AuthState(loading: false, user: user);
    }
  }
}

final authProvider =
    NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
