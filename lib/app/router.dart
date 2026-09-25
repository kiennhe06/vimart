import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/address/addresses_screen.dart';
import '../features/auth/auth_provider.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/catalog/product_detail_screen.dart';
import '../features/catalog/shop_screen.dart';
import '../features/checkout/checkout_screen.dart';
import '../features/favorite/favorites_screen.dart';
import '../features/order/order_detail_screen.dart';
import '../features/seller/product_form_screen.dart';
import '../features/seller/seller_orders_screen.dart';
import '../features/seller/seller_products_screen.dart';
import 'home_shell.dart';
import 'motion.dart';
import 'theme.dart';

/// Các route công khai (khách vãng lai xem được, không cần đăng nhập).
const _publicRoutes = {'/', '/login', '/register'};

/// Trang có chuyển cảnh fade-through + phóng nhẹ (tôn trọng giảm chuyển động).
CustomTransitionPage<void> _appPage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: AppMotion.page,
    reverseTransitionDuration: AppMotion.base,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (context.reduceMotion) return child;
      final curved = CurvedAnimation(
        parent: animation,
        curve: AppMotion.emphasized,
        reverseCurve: AppMotion.exit,
      );
      return FadeTransition(
        opacity: curved,
        child: Transform.scale(scale: 0.98 + 0.02 * curved.value, child: child),
      );
    },
  );
}

/// Cấu hình điều hướng toàn app (go_router) + bảo vệ route cần đăng nhập.
final routerProvider = Provider<GoRouter>((ref) {
  // Bộ báo hiệu để router tự đánh giá lại redirect khi trạng thái đăng nhập đổi.
  final refresh = ValueNotifier(0);
  ref.listen(authProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final path = state.matchedLocation;

      // Đang kiểm tra token lúc mở app -> ở màn splash chờ.
      if (auth.loading) return path == '/splash' ? null : '/splash';

      // Kiểm tra xong: nếu đang ở splash thì về trang chủ.
      if (path == '/splash') return '/';

      final isPublic = _publicRoutes.contains(path) || path.startsWith('/product/') || path.startsWith('/shop/');

      // Chưa đăng nhập mà vào trang cần quyền -> chuyển sang đăng nhập.
      if (!auth.isLoggedIn && !isPublic) return '/login';

      // Đã đăng nhập mà mở lại trang login/register -> về trang chủ.
      if (auth.isLoggedIn && (path == '/login' || path == '/register')) return '/';

      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const _SplashScreen()),
      GoRoute(path: '/', builder: (_, _) => const HomeShell()),
      GoRoute(path: '/login', pageBuilder: (_, s) => _appPage(s, const LoginScreen())),
      GoRoute(path: '/register', pageBuilder: (_, s) => _appPage(s, const RegisterScreen())),
      GoRoute(
        path: '/product/:id',
        pageBuilder: (_, s) =>
            _appPage(s, ProductDetailScreen(productId: int.parse(s.pathParameters['id']!))),
      ),
      GoRoute(
        path: '/shop/:id',
        pageBuilder: (_, s) => _appPage(s, ShopScreen(shopId: int.parse(s.pathParameters['id']!))),
      ),
      GoRoute(path: '/checkout', pageBuilder: (_, s) => _appPage(s, const CheckoutScreen())),
      GoRoute(path: '/favorites', pageBuilder: (_, s) => _appPage(s, const FavoritesScreen())),
      GoRoute(path: '/addresses', pageBuilder: (_, s) => _appPage(s, const AddressesScreen())),
      GoRoute(
        path: '/order/:id',
        pageBuilder: (_, s) =>
            _appPage(s, OrderDetailScreen(orderId: int.parse(s.pathParameters['id']!))),
      ),
      GoRoute(
        path: '/seller/products',
        pageBuilder: (_, s) => _appPage(s, const SellerProductsScreen()),
      ),
      GoRoute(
        path: '/seller/products/new',
        pageBuilder: (_, s) => _appPage(s, const ProductFormScreen()),
      ),
      GoRoute(
        path: '/seller/products/edit/:id',
        pageBuilder: (_, s) =>
            _appPage(s, ProductFormScreen(productId: int.parse(s.pathParameters['id']!))),
      ),
      GoRoute(path: '/seller/orders', pageBuilder: (_, s) => _appPage(s, const SellerOrdersScreen())),
    ],
  );
});

/// Màn hình chờ trong lúc kiểm tra đăng nhập khi mở app — logo "thở" nhẹ.
class _SplashScreen extends StatefulWidget {
  const _SplashScreen();
  @override
  State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))
        ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pulse = context.reduceMotion
        ? const AlwaysStoppedAnimation(1.0)
        : Tween(begin: 0.92, end: 1.06).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: pulse,
              child: Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(color: AppColors.brandSoft, shape: BoxShape.circle),
                child: const Icon(Icons.storefront_rounded, size: 48, color: AppColors.brand),
              ),
            ),
            const SizedBox(height: 22),
            const SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(strokeWidth: 2.6, color: AppColors.brand),
            ),
          ],
        ),
      ),
    );
  }
}
