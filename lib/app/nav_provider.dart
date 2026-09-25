import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Chỉ số tab đang chọn ở thanh điều hướng dưới (0: Trang chủ, 1: Giỏ, 2: Đơn, 3: Tài khoản).
/// Đặt trong provider để mọi màn có thể chuyển tab (vd nút "Mua sắm ngay" → về Trang chủ).
class BottomNavIndex extends Notifier<int> {
  @override
  int build() => 0;

  /// Chuyển sang tab thứ [i].
  void go(int i) => state = i;
}

final bottomNavIndexProvider = NotifierProvider<BottomNavIndex, int>(BottomNavIndex.new);
