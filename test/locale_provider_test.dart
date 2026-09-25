import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vimart/core/i18n/locale_provider.dart';

void main() {
  test(
    'LocaleNotifier: mặc định vi, set/toggle đổi state và đồng bộ appLocale',
    () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(localeProvider), 'vi');

      await container.read(localeProvider.notifier).set('en');
      expect(container.read(localeProvider), 'en');
      expect(appLocale, 'en', reason: 'biến toàn cục phải đồng bộ với state');

      container.read(localeProvider.notifier).toggle();
      expect(container.read(localeProvider), 'vi');
      expect(appLocale, 'vi');
    },
  );
}
