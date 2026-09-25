import 'package:dio/dio.dart';

import '../constants.dart';
import '../i18n/locale_provider.dart';
import 'api_exception.dart';

/// Chọn thông báo lỗi theo ngôn ngữ hiện tại (dựa vào [appLocale]).
String _err(String vi, String en) => appLocale == 'en' ? en : vi;

/// Lớp gọi API dùng chung (bọc Dio).
///
/// Nhiệm vụ:
/// - Tự gắn token đăng nhập vào mỗi request (nếu đã đăng nhập).
/// - Bóc lớp vỏ { success, data } của backend, chỉ trả về phần `data`.
/// - Dịch mọi lỗi sang [ApiException] với thông báo tiếng Việt.
///
/// Widget KHÔNG gọi trực tiếp lớp này — luôn đi qua provider/repository.
class ApiClient {
  ApiClient() : _dio = Dio(BaseOptions(
          baseUrl: kApiBaseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ));

  final Dio _dio;
  String? _token;

  /// Gắn / gỡ token (gọi khi đăng nhập hoặc đăng xuất).
  set token(String? value) => _token = value;

  Options get _options => Options(
        headers: _token != null ? {'Authorization': 'Bearer $_token'} : null,
      );

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _request(() => _dio.get(path, queryParameters: query, options: _options));

  Future<dynamic> post(String path, {Object? body}) =>
      _request(() => _dio.post(path, data: body, options: _options));

  Future<dynamic> put(String path, {Object? body}) =>
      _request(() => _dio.put(path, data: body, options: _options));

  Future<dynamic> delete(String path, {Object? body}) =>
      _request(() => _dio.delete(path, data: body, options: _options));

  /// Upload 1 file ảnh lên server, trả về URL công khai của ảnh.
  /// Dùng multipart/form-data với field tên "image" (khớp backend).
  Future<String> uploadImage(String filePath) async {
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(filePath),
    });
    final data = await _request(() => _dio.post('/uploads', data: formData, options: _options));
    return (data as Map<String, dynamic>)['url'] as String;
  }

  /// Thực hiện request và bóc tách kết quả / lỗi.
  Future<dynamic> _request(Future<Response> Function() run) async {
    try {
      final res = await run();
      final data = res.data;
      if (data is Map && data['success'] == true) {
        return data['data'];
      }
      // Trường hợp hiếm: 2xx nhưng không đúng định dạng
      return data;
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  /// Dịch lỗi Dio sang thông báo dễ hiểu.
  ApiException _mapError(DioException e) {
    // Server trả body { success:false, message:'...' }
    final data = e.response?.data;
    if (data is Map && data['message'] is String) {
      return ApiException(data['message'] as String, statusCode: e.response?.statusCode);
    }
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return ApiException(_err('Máy chủ phản hồi chậm, vui lòng thử lại.',
            'The server is slow to respond, please try again.'));
      case DioExceptionType.connectionError:
        return ApiException(_err('Không kết nối được máy chủ. Kiểm tra mạng hoặc server đã bật chưa.',
            'Cannot reach the server. Check your network or if the server is running.'));
      default:
        return ApiException(_err('Đã xảy ra lỗi, vui lòng thử lại.',
            'Something went wrong, please try again.'),
            statusCode: e.response?.statusCode);
    }
  }
}
