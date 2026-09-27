import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vimart/core/api/api_client.dart';
import 'package:vimart/features/auth/auth_provider.dart';
import 'package:vimart/features/auth/auth_repository.dart';
import 'package:vimart/features/catalog/search_history.dart';
import 'package:vimart/models/user.dart';

/// Fake repository cho phép chỉ định người dùng "đăng nhập" mà không cần mạng.
class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository() : super(ApiClient());
  User? next;

  @override
  Future<(User, String)> login(String email, String password) async => (next!, 'token');

  @override
  Future<User> me() async => next!;
}

User _user(int id) =>
    User(id: id, email: 'u$id@vimart.test', fullName: 'User $id', role: 'customer');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('search history is kept per user and does not leak across accounts', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final repo = _FakeAuthRepository();
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    // Giữ provider sống để build() chạy lại mỗi khi đổi tài khoản.
    container.listen(searchHistoryProvider, (_, _) {}, fireImmediately: true);

    Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 20));

    // Người dùng 1 đăng nhập và tìm kiếm.
    repo.next = _user(1);
    await container.read(authProvider.notifier).login('u1@vimart.test', 'x');
    await settle();
    await container.read(searchHistoryProvider.notifier).add('áo thun');
    expect(container.read(searchHistoryProvider), ['áo thun']);

    // Đổi sang người dùng 2 -> KHÔNG được thấy lịch sử của người dùng 1.
    await container.read(authProvider.notifier).logout();
    repo.next = _user(2);
    await container.read(authProvider.notifier).login('u2@vimart.test', 'x');
    await settle();
    expect(container.read(searchHistoryProvider), isEmpty);

    // Quay lại người dùng 1 -> lịch sử cũ vẫn còn nguyên (không bị xóa).
    await container.read(authProvider.notifier).logout();
    repo.next = _user(1);
    await container.read(authProvider.notifier).login('u1@vimart.test', 'x');
    await settle();
    expect(container.read(searchHistoryProvider), ['áo thun']);
  });
}
