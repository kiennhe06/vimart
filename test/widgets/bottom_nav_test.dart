import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vimart/features/home/widgets/vimart_bottom_nav.dart';

void main() {
  testWidgets('VimartBottomNav vẽ 4 mục và gắn Semantics label theo ngôn ngữ', (
    tester,
  ) async {
    var tapped = -1;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VimartBottomNav(
            currentIndex: 0,
            onTap: (i) => tapped = i,
            labels: const ['Home', 'Cart', 'Orders', 'Account'],
          ),
        ),
      ),
    );

    // 4 icon (mỗi mục 1 icon, chưa có badge giỏ hàng).
    expect(find.byType(Icon), findsNWidgets(4));

    // Nhãn Semantics đổi theo tham số labels (hỗ trợ trợ năng cho nút chỉ có icon).
    expect(find.bySemanticsLabel('Cart'), findsOneWidget);
    expect(find.bySemanticsLabel('Account'), findsOneWidget);

    // Chạm mục thứ 2 gọi onTap(1).
    await tester.tap(find.bySemanticsLabel('Cart'));
    expect(tapped, 1);
  });
}
