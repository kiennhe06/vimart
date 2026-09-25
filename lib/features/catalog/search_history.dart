import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lưu và quản lý các từ khóa tìm kiếm gần đây (tối đa 8), lưu trên máy.
class SearchHistoryNotifier extends Notifier<List<String>> {
  static const _key = 'search_history';
  static const _max = 8;

  @override
  List<String> build() {
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
