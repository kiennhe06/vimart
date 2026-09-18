import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/providers.dart';
import '../../models/address.dart';
import '../auth/auth_provider.dart';

/// Truy cập API sổ địa chỉ nhận hàng.
class AddressRepository {
  AddressRepository(this._api);
  final ApiClient _api;

  Future<List<Address>> list() async {
    final data = await _api.get('/users/me/addresses');
    return (data as List<dynamic>).map((e) => Address.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> add({
    required String recipientName,
    required String phone,
    required String line,
    String? ward,
    String? district,
    String? province,
    bool isDefault = false,
  }) =>
      _api.post('/users/me/addresses', body: {
        'recipientName': recipientName,
        'phone': phone,
        'line': line,
        'ward': ward,
        'district': district,
        'province': province,
        'isDefault': isDefault,
      });

  Future<void> remove(int id) => _api.delete('/users/me/addresses/$id');
}

final addressRepositoryProvider =
    Provider<AddressRepository>((ref) => AddressRepository(ref.watch(apiClientProvider)));

/// Danh sách địa chỉ của người dùng.
final addressesProvider = FutureProvider<List<Address>>((ref) {
  final auth = ref.watch(authProvider);
  if (!auth.isLoggedIn) return Future.value(const []);
  return ref.watch(addressRepositoryProvider).list();
});
