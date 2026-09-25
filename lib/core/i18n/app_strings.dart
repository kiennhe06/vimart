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

  // ---- Chung (bổ sung) ----
  String get delete => _('Xóa', 'Delete');
  String get addShort => _('Thêm', 'Add');
  String get required => _('Bắt buộc', 'Required');
  String get send => _('Gửi', 'Send');
  String get confirm => _('Xác nhận', 'Confirm');
  String get agree => _('Đồng ý', 'Agree');
  String get done => _('Hoàn tất', 'Done');

  // ---- Điều hướng (bottom nav) ----
  String get navHome => _('Trang chủ', 'Home');

  // ---- Trang chủ / thẻ sản phẩm ----
  String get tempOutOfStock => _('Sản phẩm tạm hết hàng', 'Product is temporarily out of stock');
  String get outSuffix => _(' (hết)', ' (out)');

  // ---- Shop / yêu thích ----
  String get shopProducts => _('Sản phẩm của shop', 'Shop products');
  String get shopNoProducts => _('Shop chưa có sản phẩm nào', 'This shop has no products yet');
  String productsCount(int n) => _('$n sản phẩm', '$n products');
  String get noFavorites => _('Bạn chưa thích sản phẩm nào', "You haven't liked any products yet");

  // ---- Sổ địa chỉ ----
  String get noAddresses => _('Chưa có địa chỉ nào', 'No addresses yet');
  String get defaultLabel => _('Mặc định', 'Default');
  String get addAddress => _('Thêm địa chỉ', 'Add address');
  String get addNewAddress => _('Thêm địa chỉ mới', 'Add a new address');
  String get noAddressYet => _('Chưa có địa chỉ nào.', 'No addresses yet.');
  String get recipientName => _('Tên người nhận', 'Recipient name');
  String get phone => _('Số điện thoại', 'Phone number');
  String get streetLine => _('Số nhà, đường', 'House number, street');
  String get streetLineFull => _('Số nhà, tên đường', 'House number, street name');
  String get ward => _('Phường/Xã', 'Ward');
  String get district => _('Quận/Huyện', 'District');
  String get province => _('Tỉnh/Thành phố', 'Province/City');
  String get saveAddress => _('Lưu địa chỉ', 'Save address');
  String get addressSaved => _('Đã lưu địa chỉ', 'Address saved');
  String get newAddress => _('Địa chỉ mới', 'New address');

  // ---- Thanh toán (checkout) ----
  String get checkout => _('Thanh toán', 'Checkout');
  String get selectAddress => _('Vui lòng chọn địa chỉ nhận hàng', 'Please select a delivery address');
  String get codSuccess => _('Đặt hàng thành công! Bạn sẽ trả tiền khi nhận hàng (COD).',
      'Order placed! You will pay on delivery (COD).');
  String get vnpayOpened => _('Đã mở cổng VNPay. Sau khi thanh toán xong, kéo để làm mới đơn hàng.',
      'VNPay opened. After paying, pull to refresh your orders.');
  String get mockPaySuccess => _('Thanh toán (giả lập) thành công! (Chưa cấu hình VNPay sandbox thật.)',
      'Payment (simulated) successful! (Real VNPay sandbox not configured.)');
  String get backHome => _('Về trang chủ', 'Back home');
  String get viewOrders => _('Xem đơn hàng', 'View orders');
  String get shippingAddress => _('Địa chỉ nhận hàng', 'Delivery address');
  String productsSection(int n) => _('Sản phẩm ($n)', 'Products ($n)');
  String get paymentMethod => _('Phương thức thanh toán', 'Payment method');
  String get codOption => _('Thanh toán khi nhận hàng (COD)', 'Cash on delivery (COD)');
  String get vnpayOption => _('Ví VNPay', 'VNPay wallet');
  String placeOrder(String price) => _('Đặt hàng • $price', 'Place order • $price');

  // ---- Mở shop (từ Tài khoản) ----
  String get shopNameLabel => _('Tên shop', 'Shop name');
  String get shopDescOptional => _('Giới thiệu (không bắt buộc)', 'Description (optional)');
  String get createShop => _('Tạo shop', 'Create shop');
  String get shopCreated => _('Mở shop thành công!', 'Shop opened successfully!');

  // ---- Người bán: sản phẩm ----
  String get addProduct => _('Thêm sản phẩm', 'Add product');
  String get editProduct => _('Sửa sản phẩm', 'Edit product');
  String get sellerNoProducts =>
      _('Shop chưa có sản phẩm nào.\nBấm "Thêm sản phẩm" để đăng bán.',
          'Your shop has no products yet.\nTap "Add product" to start selling.');
  String get deleteProduct => _('Xóa sản phẩm', 'Delete product');
  String deleteProductConfirm(String name) =>
      _('Xóa "$name"? Hành động này không thể hoàn tác.',
          'Delete "$name"? This action cannot be undone.');

  // ---- Người bán: đơn hàng ----
  String get noOrdersShort => _('Không có đơn nào', 'No orders');

  // ---- Người bán: form sản phẩm ----
  String get imageUploaded => _('Đã tải ảnh lên', 'Image uploaded');
  String get productSaved => _('Đã lưu sản phẩm', 'Product saved');
  String get productName => _('Tên sản phẩm', 'Product name');
  String get enterProductName => _('Nhập tên sản phẩm', 'Enter product name');
  String get category => _('Danh mục', 'Category');
  String get productImage => _('Ảnh sản phẩm', 'Product image');
  String get uploadingImage => _('Đang tải ảnh...', 'Uploading image...');
  String get pickImage => _('Chọn ảnh từ máy', 'Pick image from device');
  String get orPasteImageLink => _('hoặc dán link ảnh', 'or paste an image link');
  String get variantsSection => _('Phân loại (giá + tồn kho)', 'Variants (price + stock)');
  String get saveProduct => _('Lưu sản phẩm', 'Save product');
  String get variantNameHint => _('Tên (vd: Đỏ/L)', 'Name (e.g. Red/L)');
  String get price => _('Giá', 'Price');
  String get stock => _('Kho', 'Stock');
  String get mustBeNumber => _('Số', 'Number');

  // ---- Chi tiết đơn hàng ----
  String get orderDetail => _('Chi tiết đơn hàng', 'Order details');
  String get recipient => _('Người nhận', 'Recipient');
  String get productsLabel => _('Sản phẩm', 'Products');
  String get paymentLabel => _('Thanh toán', 'Payment');
  String get discount => _('Giảm giá', 'Discount');
  String get method => _('Phương thức', 'Method');
  String get statusLabel => _('Tình trạng', 'Status');
  String get paidFull => _('Đã thanh toán', 'Paid');
  String get unpaid => _('Chưa thanh toán', 'Unpaid');
  String get confirmOrder => _('Xác nhận đơn', 'Confirm order');
  String get reject => _('Từ chối', 'Reject');
  String get rejectConfirm =>
      _('Từ chối đơn này? Hàng sẽ được hoàn về kho.', 'Reject this order? Stock will be returned.');
  String get ship => _('Giao hàng', 'Ship');
  String get cancelOrder => _('Hủy đơn', 'Cancel order');
  String get cancelOrderConfirm =>
      _('Bạn chắc chắn muốn hủy đơn này?', 'Are you sure you want to cancel this order?');
  String get received => _('Đã nhận hàng', 'Received');
  String get receivedConfirm =>
      _('Xác nhận bạn đã nhận được hàng?', 'Confirm you have received the order?');
  String reviewProductLabel(String name) => _('Đánh giá: $name', 'Review: $name');
  String get reviewProductTitle => _('Đánh giá sản phẩm', 'Review product');
  String get reviewHint => _('Nhận xét của bạn (không bắt buộc)', 'Your comment (optional)');

  // ---- Tìm kiếm nâng cao ----
  String get sortLabel => _('Sắp xếp', 'Sort');
  String get sortBestSelling => _('Bán chạy', 'Best selling');
  String get sortNewest => _('Mới nhất', 'Newest');
  String get sortPriceAsc => _('Giá thấp', 'Price ↑');
  String get sortPriceDesc => _('Giá cao', 'Price ↓');
  String get sortRating => _('Đánh giá', 'Top rated');
  String get filters => _('Bộ lọc', 'Filters');
  String get priceRange => _('Khoảng giá', 'Price range');
  String get priceFrom => _('Từ', 'From');
  String get priceTo => _('Đến', 'To');
  String get minRatingLabel => _('Đánh giá tối thiểu', 'Minimum rating');
  String get anyLabel => _('Tất cả', 'Any');
  String ratingUp(String stars) => _('$stars★ trở lên', '$stars★ & up');
  String get apply => _('Áp dụng', 'Apply');
  String get reset => _('Đặt lại', 'Reset');
  String get recentSearches => _('Tìm gần đây', 'Recent searches');
  String get clearAll => _('Xóa hết', 'Clear all');
  String resultsCount(int n) => _('$n kết quả', '$n results');
}

/// Provider trả về bộ chuỗi theo ngôn ngữ hiện tại.
final stringsProvider = Provider<AppStrings>((ref) => AppStrings(ref.watch(localeProvider)));
