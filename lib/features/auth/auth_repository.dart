import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/providers.dart';
import '../../models/user.dart';

/// Truy cập dữ liệu liên quan tới đăng nhập / tài khoản.
class AuthRepository {
  AuthRepository(this._api);
  final ApiClient _api;

  /// Đăng nhập, trả về (user, token).
  Future<(User, String)> login(String email, String password) async {
    final data = await _api.post('/auth/login', body: {'email': email, 'password': password});
    return (User.fromJson(data['user'] as Map<String, dynamic>), data['token'] as String);
  }

  /// Đăng ký, trả về (user, token).
  Future<(User, String)> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    final data = await _api.post('/auth/register', body: {
      'email': email,
      'password': password,
      'fullName': fullName,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
    });
    return (User.fromJson(data['user'] as Map<String, dynamic>), data['token'] as String);
  }

  /// Lấy thông tin người dùng hiện tại (kèm shop nếu có).
  Future<User> me() async {
    final data = await _api.get('/auth/me');
    return User.fromJson(data as Map<String, dynamic>);
  }
}

final authRepositoryProvider =
    Provider<AuthRepository>((ref) => AuthRepository(ref.watch(apiClientProvider)));
