import 'package:flutter_test/flutter_test.dart';
import 'package:vimart/core/format.dart';

void main() {
  test('formatVnd định dạng tiền kiểu Việt Nam', () {
    expect(formatVnd(89000), '89.000₫');
    expect(formatVnd(0), '0₫');
    expect(formatVnd(1500000), '1.500.000₫');
  });

  test('formatDateTime theo mẫu dd/MM/yyyy HH:mm', () {
    final dt = DateTime(2026, 9, 25, 21, 30);
    expect(formatDateTime(dt), '25/09/2026 21:30');
  });
}
