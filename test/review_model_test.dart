import 'package:flutter_test/flutter_test.dart';
import 'package:vimart/models/product.dart';

void main() {
  test('Review.fromJson reads the admin reply when present', () {
    final r = Review.fromJson({
      'id': 1,
      'rating': 5,
      'comment': 'tốt',
      'userName': 'An',
      'reply': 'Cảm ơn bạn!',
    });
    expect(r.reply, 'Cảm ơn bạn!');
  });

  test('Review.fromJson leaves reply null when absent', () {
    final r = Review.fromJson({'id': 2, 'rating': 4, 'comment': 'ok'});
    expect(r.reply, isNull);
  });
}
