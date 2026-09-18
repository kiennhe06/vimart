import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/router.dart';
import 'app/theme.dart';
import 'core/constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Nạp dữ liệu định dạng ngày tháng tiếng Việt trước khi chạy app.
  await initializeDateFormatting('vi');
  runApp(const ProviderScope(child: ViMartApp()));
}

/// Widget gốc của toàn app.
class ViMartApp extends ConsumerWidget {
  const ViMartApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: kAppName,
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: ThemeMode.light, // mặc định sáng cho app mua sắm
      routerConfig: router,
      // Hỗ trợ tiếng Việt cho các widget hệ thống (lịch, chọn ngày...).
      locale: const Locale('vi'),
      supportedLocales: const [Locale('vi'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
