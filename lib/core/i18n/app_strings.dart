import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'locale_provider.dart';

/// Chuỗi hiển thị song ngữ (Việt / Anh). Chọn theo ngôn ngữ hiện tại.
/// Dùng: `final s = ref.watch(stringsProvider); Text(s.cart);`
class AppStrings {
  AppStrings(this.locale);
  final String locale; // 'vi' | 'en'
  bool get isEn => locale == 'en';
  String _(String vi, String en) => isEn ? en : vi;

  // ---- Chung ----
  String get tagline => _('Chợ tươi ngon, giao tận nơi', 'Fresh groceries, delivered');
  String get retry => _('Thử lại', 'Retry');
  String get login => _('Đăng nhập', 'Log in');
  String get cancel => _('Hủy', 'Cancel');
  String get no => _('Không', 'No');
  String get save => _('Lưu', 'Save');
  String get connectionError =>
      _('Không kết nối được máy chủ. Kiểm tra mạng hoặc server đã bật chưa.',
          'Cannot reach the server. Check your network or if the server is running.');

  // ---- Trang chủ ----
  String get greeting => _('Xin chào 👋', 'Hello 👋');
  String get freshBadge => _('Tươi ngon', 'Fresh');
  String get promoTitle => _('Giảm 10% đơn đầu tiên 🎉', 'Get 10% off your first order 🎉');
  String get promoSub => _('Mua sắm tươi ngon, giao tận nơi', 'Shop fresh, delivered to your door');
  String get shopNow => _('Mua ngay', 'Shop now');
  String get searchHint => _('Tìm sản phẩm...', 'Search products...');
  String get all => _('Tất cả', 'All');
  String get forYou => _('Gợi ý cho bạn', 'For you');
  String get seeAll => _('Xem tất cả', 'See all');
  String get newLabel => _('Mới', 'New');
  String sold(int n) => _('Đã bán $n', 'Sold $n');
  String get loadingProducts => _('Đang tải sản phẩm...', 'Loading products...');
  String get noProducts => _('Không tìm thấy sản phẩm nào', 'No products found');
  String get addedToCart => _('Đã thêm vào giỏ hàng', 'Added to cart');
  String get loginToBuy => _('Vui lòng đăng nhập để mua hàng', 'Please log in to shop');

  // ---- Chi tiết sản phẩm ----
  String get noReviews => _('Chưa có đánh giá', 'No reviews yet');
  String reviewsWithCount(int n) => _('Đánh giá ($n)', 'Reviews ($n)');
  String get options => _('Phân loại', 'Options');
  String remaining(int n) => _('Còn lại: $n', 'In stock: $n');
  String get description => _('Mô tả', 'Description');
  String get noDescription => _('Chưa có mô tả.', 'No description.');
  String get noReviewYet => _('Chưa có đánh giá nào.', 'No reviews yet.');
  String get user => _('Người dùng', 'User');
  String addToCartWith(String price) => _('Thêm vào giỏ • $price', 'Add to cart • $price');
  String get outOfStock => _('Hết hàng', 'Out of stock');
  String get addedFavorite => _('Đã thêm vào yêu thích', 'Added to favorites');

  // ---- Giỏ hàng ----
  String get cart => _('Giỏ hàng', 'Cart');
  String get loginToViewCart => _('Đăng nhập để xem giỏ hàng của bạn', 'Log in to view your cart');
  String get emptyCart => _('Giỏ hàng đang trống', 'Your cart is empty');
  String get deliveryIn15 => _('Giao trong 15 phút', 'Delivery in 15 min');
  String get subtotal => _('Tạm tính', 'Subtotal');
  String get shippingFee => _('Phí vận chuyển', 'Shipping fee');
  String get total => _('Tổng cộng', 'Total');
  String checkoutItems(int n) => _('Thanh toán • $n món', 'Checkout • $n items');

  // ---- Đơn hàng ----
  String get orders => _('Đơn hàng', 'Orders');
  String get loginToViewOrders => _('Đăng nhập để xem đơn hàng của bạn', 'Log in to view your orders');
  String get tabPending => _('Chờ xác nhận', 'Pending');
  String get tabConfirmed => _('Đã xác nhận', 'Confirmed');
  String get tabShipping => _('Đang giao', 'Shipping');
  String get tabCompleted => _('Hoàn thành', 'Completed');
  String get noOrders => _('Chưa có đơn hàng nào', 'No orders yet');
  String get shopAndReturn => _('Hãy mua sắm và quay lại đây nhé', 'Start shopping and check back here');
  String get shopNowBtn => _('Mua sắm ngay', 'Shop now');
  String orderCode(String code) => _('Đơn $code', 'Order $code');
  String customer(String name) => _('Khách: $name', 'Customer: $name');
  String get paid => _('Đã trả', 'Paid');

  /// Nhãn trạng thái đơn theo ngôn ngữ.
  String orderStatus(String status) {
    switch (status) {
      case 'pending':
        return tabPending;
      case 'confirmed':
        return tabConfirmed;
      case 'shipping':
        return tabShipping;
      case 'completed':
        return tabCompleted;
      case 'cancelled':
        return _('Đã hủy', 'Cancelled');
      default:
        return status;
    }
  }

  // ---- Tài khoản ----
  String get account => _('Tài khoản', 'Account');
  String get loginToManage => _('Đăng nhập để quản lý tài khoản', 'Log in to manage your account');
  String get roleAdmin => _('Quản trị viên', 'Administrator');
  String get roleSeller => _('Người bán', 'Seller');
  String get roleBuyer => _('Người mua', 'Buyer');
  String get favoriteProducts => _('Sản phẩm yêu thích', 'Favorite products');
  String get addressBook => _('Sổ địa chỉ', 'Address book');
  String get sellerChannel => _('Kênh người bán', 'Seller channel');
  String get myShopProducts => _('Sản phẩm của shop', 'My products');
  String get myShopOrders => _('Đơn hàng của shop', 'Shop orders');
  String get openShop => _('Mở shop bán hàng', 'Open a shop');
  String get language => _('Ngôn ngữ', 'Language');
  String get logout => _('Đăng xuất', 'Log out');
  String get logoutConfirm => _('Bạn muốn đăng xuất khỏi tài khoản?', 'Do you want to log out?');

  // ---- Đăng nhập / Đăng ký ----
  String get email => _('Email', 'Email');
  String get password => _('Mật khẩu', 'Password');
  String get fullName => _('Họ và tên', 'Full name');
  String get phoneOptional => _('Số điện thoại (không bắt buộc)', 'Phone (optional)');
  String get emailInvalid => _('Email không hợp lệ', 'Invalid email');
  String get enterPassword => _('Vui lòng nhập mật khẩu', 'Please enter your password');
  String get passwordMin6 => _('Mật khẩu tối thiểu 6 ký tự', 'Password must be at least 6 characters');
  String get enterName => _('Vui lòng nhập họ tên', 'Please enter your name');
  String get noAccount => _('Chưa có tài khoản?', 'No account yet?');
  String get signUpNow => _('Đăng ký ngay', 'Sign up');
  String get browseGuest => _('Xem hàng trước (khách vãng lai)', 'Browse as guest');
  String get demoAccounts => _('Tài khoản dùng thử (mật khẩu: 123456)', 'Demo accounts (password: 123456)');
  String get demoBuyer => _('• buyer@vimart.vn — người mua', '• buyer@vimart.vn — buyer');
  String get demoSeller => _('• seller1@vimart.vn — người bán', '• seller1@vimart.vn — seller');
  String get demoAdmin => _('• admin@vimart.vn — quản trị', '• admin@vimart.vn — admin');
  String get register => _('Đăng ký', 'Sign up');
  String get createAccount => _('Tạo tài khoản', 'Create account');
  String get registerTitle => _('Tạo tài khoản ViMart', 'Create your ViMart account');
  String get registerSub => _('Chỉ mất một phút để bắt đầu mua sắm', 'It only takes a minute to start shopping');
}

/// Provider trả về bộ chuỗi theo ngôn ngữ hiện tại.
final stringsProvider = Provider<AppStrings>((ref) => AppStrings(ref.watch(localeProvider)));
