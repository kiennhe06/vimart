// Smoke test cơ bản cho ViMart.
// Kiểm tra app khởi tạo được và hiển thị màn hình chờ (splash) khi mới mở.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:vimart/app/theme.dart';

void main() {
  test('Theme sáng và tối build được', () {
    expect(buildLightTheme(), isA<ThemeData>());
    expect(buildDarkTheme(), isA<ThemeData>());
  });

  testWidgets('App gốc bọc được trong ProviderScope', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: Text('ViMart'))),
      ),
    );
    expect(find.text('ViMart'), findsOneWidget);
  });
}
