import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vimart/app/motion.dart';
import 'package:vimart/widgets/pressable.dart';
import 'package:vimart/widgets/rolling_number.dart';
import 'package:vimart/widgets/spring.dart';

void main() {
  testWidgets(
    'AppMotion.dur giữ nguyên thời lượng khi KHÔNG giảm chuyển động',
    (tester) async {
      late Duration d;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: false),
          child: Builder(
            builder: (context) {
              d = AppMotion.dur(context, AppMotion.base);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(d, AppMotion.base);
    },
  );

  testWidgets('AppMotion.dur về Duration.zero khi bật giảm chuyển động', (
    tester,
  ) async {
    late Duration d;
    late bool reduce;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Builder(
          builder: (context) {
            reduce = context.reduceMotion;
            d = AppMotion.dur(context, AppMotion.slow);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(reduce, isTrue);
    expect(d, Duration.zero);
  });

  testWidgets('Pressable gọi onTap và không làm đổi kích thước layout', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Pressable(
              onTap: () => taps++,
              haptic: false,
              child: const SizedBox(width: 100, height: 40, key: Key('box')),
            ),
          ),
        ),
      ),
    );
    final before = tester.getSize(find.byKey(const Key('box')));
    await tester.tap(find.byKey(const Key('box')), warnIfMissed: false);
    await tester.pumpAndSettle();
    final after = tester.getSize(find.byKey(const Key('box')));
    expect(taps, 1);
    expect(after, before, reason: 'press feedback không được đẩy/đổi layout');
  });

  testWidgets('Springy nhảy thẳng tới đích khi giảm chuyển động', (
    tester,
  ) async {
    double seen = -1;
    Widget build(double v) => MediaQuery(
      data: const MediaQueryData(disableAnimations: true),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Springy(
          value: v,
          builder: (_, val, _) {
            seen = val;
            return const SizedBox();
          },
        ),
      ),
    );
    await tester.pumpWidget(build(0));
    expect(seen, 0);
    await tester.pumpWidget(build(1));
    await tester.pump();
    expect(
      seen,
      1,
      reason: 'giảm chuyển động -> tới đích tức thì, không mô phỏng',
    );
  });

  testWidgets('RollingNumber hiển thị giá trị đã định dạng', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: RollingNumber(value: 1000, format: (v) => '$v đ'),
        ),
      ),
    );
    expect(find.text('1000 đ'), findsOneWidget);
  });
}
