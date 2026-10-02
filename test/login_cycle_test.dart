import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vimart/features/auth/auth_provider.dart';
import 'package:vimart/features/auth/auth_repository.dart';
import 'package:vimart/features/cart/cart_provider.dart';
import 'package:vimart/features/notification/notification_providers.dart';
import 'package:vimart/core/api/api_client.dart';
import 'package:vimart/models/user.dart';

class _FakeAuthRepo extends AuthRepository {
  _FakeAuthRepo() : super(ApiClient());
  User? next;
  @override
  Future<(User, String)> login(String e, String p) async => (next!, 'tok');
  @override
  Future<User> me() async => next!;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('reading cart + unread while logged in does not throw circular dependency', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final repo = _FakeAuthRepo()..next = User(id: 1, email: 'a@a', fullName: 'A', role: 'customer');
    final c = ProviderContainer(overrides: [authRepositoryProvider.overrideWithValue(repo)]);
    addTearDown(c.dispose);

    // Mô phỏng home shell + header giữ cart và unread "sống".
    c.listen(cartProvider, (_, _) {}, fireImmediately: true);
    c.listen(unreadCountProvider, (_, _) {}, fireImmediately: true);

    await c.read(authProvider.notifier).login('a@a', 'x');
    // Chỉ cần tới đây không ném CircularDependencyError là đạt.
    expect(c.read(authProvider).isLoggedIn, true);
  });
}
