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

/// Các route công khai (khách vãng lai xem được, không cần đăng nhập).
const _publicRoutes = {'/', '/login', '/register'};

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
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
      GoRoute(
        path: '/product/:id',
        builder: (_, s) => ProductDetailScreen(productId: int.parse(s.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/shop/:id',
        builder: (_, s) => ShopScreen(shopId: int.parse(s.pathParameters['id']!)),
      ),
      GoRoute(path: '/checkout', builder: (_, _) => const CheckoutScreen()),
      GoRoute(path: '/favorites', builder: (_, _) => const FavoritesScreen()),
      GoRoute(path: '/addresses', builder: (_, _) => const AddressesScreen()),
      GoRoute(
        path: '/order/:id',
        builder: (_, s) => OrderDetailScreen(orderId: int.parse(s.pathParameters['id']!)),
      ),
      GoRoute(path: '/seller/products', builder: (_, _) => const SellerProductsScreen()),
      GoRoute(path: '/seller/products/new', builder: (_, _) => const ProductFormScreen()),
      GoRoute(
        path: '/seller/products/edit/:id',
        builder: (_, s) => ProductFormScreen(productId: int.parse(s.pathParameters['id']!)),
      ),
      GoRoute(path: '/seller/orders', builder: (_, _) => const SellerOrdersScreen()),
    ],
  );
});

/// Màn hình chờ trong lúc kiểm tra đăng nhập khi mở app.
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.storefront, size: 72, color: Color(0xFFF4511E)),
            SizedBox(height: 16),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
