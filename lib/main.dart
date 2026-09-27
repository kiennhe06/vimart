import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/router.dart';
import 'app/theme.dart';
import 'app/theme_mode_provider.dart';
import 'core/constants.dart';
import 'core/i18n/locale_provider.dart';
import 'features/catalog/catalog_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Nạp dữ liệu định dạng ngày tháng cho cả tiếng Việt và Anh.
  await initializeDateFormatting('vi');
  await initializeDateFormatting('en');
  runApp(const ProviderScope(child: ViMartApp()));
}

/// Widget gốc của toàn app.
class ViMartApp extends ConsumerStatefulWidget {
  const ViMartApp({super.key});

  @override
  ConsumerState<ViMartApp> createState() => _ViMartAppState();
}

class _ViMartAppState extends ConsumerState<ViMartApp> with WidgetsBindingObserver {
  /// Thời điểm app bị đưa xuống nền — để biết đã rời bao lâu khi quay lại.
  DateTime? _pausedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      // Quay lại app sau khi rời đủ lâu -> tải lại catalog để thấy dữ liệu mới
      // (vd sản phẩm admin vừa thêm ở web). Rời chớp nhoáng thì bỏ qua để không
      // refetch thừa. AsyncView giữ dữ liệu cũ trong lúc tải nên không nháy.
      final away = _pausedAt == null ? Duration.zero : DateTime.now().difference(_pausedAt!);
      if (away >= const Duration(seconds: 15)) {
        ref.invalidate(categoriesProvider);
        ref.invalidate(productListProvider);
        ref.invalidate(shopProductsProvider);
        ref.invalidate(productDetailProvider);
      }
      _pausedAt = null;
    }
  }

  @override
  Widget build(BuildContext context) {
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
