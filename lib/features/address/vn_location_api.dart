import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Đơn vị hành chính (tỉnh/thành hoặc phường/xã) — chỉ cần code + tên.
class LocationUnit {
  const LocationUnit(this.code, this.name);
  final int code;
  final String name;

  factory LocationUnit.fromJson(Map<String, dynamic> j) =>
      LocationUnit(j['code'] as int, j['name'] as String);

  @override
  bool operator ==(Object other) => other is LocationUnit && other.code == code;
  @override
  int get hashCode => code.hashCode;
}

/// Gọi API địa giới hành chính VN (bản v2 — cơ cấu 2 cấp: Tỉnh → Phường/Xã,
/// sau sáp nhập 2025, không còn cấp Quận/Huyện). Nguồn: provinces.open-api.vn.
class VnLocationRepository {
  VnLocationRepository()
      : _dio = Dio(BaseOptions(
          baseUrl: 'https://provinces.open-api.vn/api/v2',
          connectTimeout: const Duration(seconds: 12),
          receiveTimeout: const Duration(seconds: 12),
        ));
  final Dio _dio;

  /// Danh sách tỉnh/thành.
  Future<List<LocationUnit>> provinces() async {
    final res = await _dio.get<List<dynamic>>('/p/');
    return (res.data ?? [])
        .map((e) => LocationUnit.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Phường/xã của 1 tỉnh (depth=2 trả kèm danh sách wards).
  Future<List<LocationUnit>> wards(int provinceCode) async {
    final res = await _dio.get<Map<String, dynamic>>('/p/$provinceCode', queryParameters: {'depth': 2});
    final list = (res.data?['wards'] as List<dynamic>? ?? []);
    return list.map((e) => LocationUnit.fromJson(e as Map<String, dynamic>)).toList();
  }
}

final vnLocationRepositoryProvider = Provider<VnLocationRepository>((ref) => VnLocationRepository());

final provincesProvider =
    FutureProvider<List<LocationUnit>>((ref) => ref.watch(vnLocationRepositoryProvider).provinces());

final wardsProvider = FutureProvider.family<List<LocationUnit>, int>(
    (ref, provinceCode) => ref.watch(vnLocationRepositoryProvider).wards(provinceCode));
