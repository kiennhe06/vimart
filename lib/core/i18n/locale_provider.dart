import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Quản lý ngôn ngữ app: 'vi' (mặc định) hoặc 'en'. Lưu lại trên máy.
class LocaleNotifier extends Notifier<String> {
  static const _key = 'app_locale';

  @override
  String build() {
    _restore();
    return 'vi';
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved != null && saved != state) state = saved;
  }

  /// Đổi ngôn ngữ và lưu lại.
  Future<void> set(String code) async {
    state = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, code);
  }

  /// Đảo qua lại vi <-> en.
  void toggle() => set(state == 'vi' ? 'en' : 'vi');
}

final localeProvider = NotifierProvider<LocaleNotifier, String>(LocaleNotifier.new);
