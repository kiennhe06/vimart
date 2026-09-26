import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/router.dart';
import 'app/theme.dart';
import 'app/theme_mode_provider.dart';
import 'core/constants.dart';
import 'core/i18n/locale_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Nạp dữ liệu định dạng ngày tháng cho cả tiếng Việt và Anh.
  await initializeDateFormatting('vi');
  await initializeDateFormatting('en');
  runApp(const ProviderScope(child: ViMartApp()));
}

/// Widget gốc của toàn app.
class ViMartApp extends ConsumerWidget {
  const ViMartApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final localeCode = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: kAppName,
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: themeMode,
      routerConfig: router,
      // Ngôn ngữ theo lựa chọn người dùng (vi / en).
      locale: Locale(localeCode),
      supportedLocales: const [Locale('vi'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
