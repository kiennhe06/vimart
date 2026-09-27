import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vimart/features/auth/auth_provider.dart';
import 'package:vimart/features/catalog/search_history.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('logout wipes local user data so it cannot leak to the next account', () async {
    // Arrange: giả lập tài khoản trước đã có lịch sử tìm kiếm lưu trên máy.
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final history = container.read(searchHistoryProvider.notifier);
    await history.add('áo thun');
    await history.add('điện thoại');
    expect(container.read(searchHistoryProvider), ['điện thoại', 'áo thun']);

    // Act: đăng xuất (bước bắt buộc khi chuyển sang tài khoản khác).
    await container.read(authProvider.notifier).logout();

    // Assert: dữ liệu cục bộ bị xóa cả trong bộ nhớ lẫn trên đĩa.
    expect(container.read(searchHistoryProvider), isEmpty);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('search_history'), isNull);
  });
}
