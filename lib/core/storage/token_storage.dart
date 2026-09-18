import 'package:shared_preferences/shared_preferences.dart';

/// Lưu / đọc "vé đăng nhập" (JWT token) trên máy để giữ trạng thái đăng nhập
/// sau khi tắt mở lại app.
class TokenStorage {
  static const _key = 'auth_token';

  /// Lưu token sau khi đăng nhập thành công.
  Future<void> save(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, token);
  }

  /// Đọc token đang lưu (null nếu chưa đăng nhập).
  Future<String?> read() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }

  /// Xóa token khi đăng xuất.
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
