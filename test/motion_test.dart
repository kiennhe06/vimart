import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vimart/app/motion.dart';
import 'package:vimart/widgets/pressable.dart';

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
    await tester.tap(find.byKey(const Key('box')));
    await tester.pumpAndSettle();
    final after = tester.getSize(find.byKey(const Key('box')));
    expect(taps, 1);
    expect(after, before, reason: 'press feedback không được đẩy/đổi layout');
  });
}
