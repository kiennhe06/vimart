import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/auth_provider.dart';

/// Lưu và quản lý các từ khóa tìm kiếm gần đây (tối đa 8), lưu trên máy.
///
/// Lịch sử được tách RIÊNG theo từng người dùng: mỗi tài khoản dùng một key
/// khác nhau (`search_history_<userId>`), khách chưa đăng nhập dùng
/// `search_history_guest`. Nhờ đó khi đổi tài khoản, lịch sử của tài khoản
/// trước không hiện ở tài khoản mới, nhưng vẫn còn nguyên khi quay lại.
class SearchHistoryNotifier extends Notifier<List<String>> {
  static const _prefix = 'search_history_';
  static const _max = 8;

  /// Key lưu trữ ứng với người dùng hiện tại (cập nhật lại mỗi khi đổi tài khoản).
  String _key = '${_prefix}guest';

  @override
  List<String> build() {
    // Theo dõi đăng nhập -> đổi tài khoản thì tự nạp lại đúng lịch sử của user đó.
    final user = ref.watch(authProvider).user;
    _key = user != null ? '$_prefix${user.id}' : '${_prefix}guest';
    _restore();
    return const [];
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getStringList(_key) ?? const [];
  }

  /// Thêm 1 từ khóa lên đầu (bỏ trùng, giới hạn số lượng).
  Future<void> add(String term) async {
    final t = term.trim();
    if (t.isEmpty) return;
    final next = <String>[
      t,
      ...state.where((e) => e.toLowerCase() != t.toLowerCase()),
    ].take(_max).toList();
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, next);
  }

  Future<void> remove(String term) async {
    state = state.where((e) => e != term).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, state);
  }

  Future<void> clear() async {
    state = const [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

final searchHistoryProvider =
    NotifierProvider<SearchHistoryNotifier, List<String>>(SearchHistoryNotifier.new);
