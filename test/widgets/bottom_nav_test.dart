import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vimart/features/home/widgets/vimart_bottom_nav.dart';

void main() {
  testWidgets(
    'VimartBottomNav vẽ 4 mục, gắn Semantics label và chạm gọi onTap',
    (tester) async {
      final handle = tester.ensureSemantics();
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

      // 4 icon (mỗi mục 1 icon, badge giỏ ẩn khi count = 0).
      expect(find.byType(Icon), findsNWidgets(4));

      // Nhãn Semantics gắn theo tham số labels (trợ năng cho nút chỉ có icon).
      Finder labelled(String l) => find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.label == l,
      );
      expect(labelled('Cart'), findsOneWidget);
      expect(labelled('Account'), findsOneWidget);

      // Chạm vào mục Giỏ hàng (theo icon) gọi onTap(1).
      await tester.tap(find.byIcon(Icons.shopping_cart_rounded));
      expect(tapped, 1);

      handle.dispose();
    },
  );
}
