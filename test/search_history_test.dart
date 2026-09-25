import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vimart/features/catalog/search_history.dart';

/// Chờ _restore() (bất đồng bộ trong build) hoàn tất để test không bị đua.
Future<SearchHistoryNotifier> _ready(ProviderContainer c) async {
  final n = c.read(searchHistoryProvider.notifier);
  await Future<void>.delayed(const Duration(milliseconds: 20));
  return n;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('add đưa lên đầu và bỏ trùng (không phân biệt hoa/thường)', () async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final n = await _ready(c);
    await n.add('Táo');
    await n.add('Cam');
    await n.add('táo'); // trùng "Táo" -> gộp, đưa lên đầu
    expect(c.read(searchHistoryProvider), ['táo', 'Cam']);
  });

  test('giới hạn tối đa 8 mục, mục mới nhất ở đầu', () async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final n = await _ready(c);
    for (var i = 0; i < 12; i++) {
      await n.add('kw$i');
    }
    final list = c.read(searchHistoryProvider);
    expect(list.length, 8);
    expect(list.first, 'kw11');
  });

  test('remove và clear', () async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final n = await _ready(c);
    await n.add('a');
    await n.add('b');
    await n.remove('a');
    expect(c.read(searchHistoryProvider), ['b']);
    await n.clear();
    expect(c.read(searchHistoryProvider), isEmpty);
  });

  test('bỏ qua chuỗi rỗng/khoảng trắng', () async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final n = await _ready(c);
    await n.add('   ');
    await n.add('');
    expect(c.read(searchHistoryProvider), isEmpty);
  });
}
