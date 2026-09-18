/// Lỗi API đã được "dịch" sang thông báo tiếng Việt thân thiện cho người dùng.
/// Không bao giờ hiển thị lỗi Dio thô cho người dùng.
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
