import 'package:flutter_test/flutter_test.dart';
import 'package:vimart/core/i18n/app_strings.dart';

void main() {
  test('AppStrings đổi chuỗi theo ngôn ngữ', () {
    final vi = AppStrings('vi');
    final en = AppStrings('en');
    expect(vi.isEn, isFalse);
    expect(en.isEn, isTrue);
    expect(vi.cart, isNot(equals(en.cart)));
    expect(vi.checkout, isNot(equals(en.checkout)));
  });

  test('orderStatus dịch hết mọi trạng thái, fallback về key lạ', () {
    final en = AppStrings('en');
    for (final s in [
      'pending',
      'confirmed',
      'shipping',
      'completed',
      'cancelled',
    ]) {
      expect(en.orderStatus(s), isNotEmpty);
      expect(
        en.orderStatus(s),
        isNot(equals(s)),
        reason: 'trạng thái "$s" phải được dịch',
      );
    }
    expect(en.orderStatus('khong-biet'), equals('khong-biet'));
  });

  test('các getter có tham số chèn đúng số', () {
    final en = AppStrings('en');
    expect(en.sold(5), contains('5'));
    expect(en.checkoutItems(3), contains('3'));
    expect(en.productsCount(2), contains('2'));
    expect(en.orderCode('VM123'), contains('VM123'));
  });
}
