import 'package:intl/intl.dart';

/// Định dạng số tiền sang dạng "89.000₫".
String formatVnd(num amount) {
  final formatter = NumberFormat.decimalPattern('vi');
  return '${formatter.format(amount)}₫';
}

/// Định dạng ngày giờ sang "18/09/2026 21:30".
String formatDateTime(DateTime dt) {
  return DateFormat('dd/MM/yyyy HH:mm').format(dt.toLocal());
}

/// Đổi trạng thái đơn (tiếng Anh trong DB) sang nhãn tiếng Việt.
String orderStatusLabel(String status) {
  switch (status) {
    case 'pending':
      return 'Chờ xác nhận';
    case 'confirmed':
      return 'Đã xác nhận';
    case 'shipping':
      return 'Đang giao';
    case 'completed':
      return 'Hoàn thành';
    case 'cancelled':
      return 'Đã hủy';
    default:
      return status;
  }
}
