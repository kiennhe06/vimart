/// Thông tin shop rút gọn gắn kèm user (null nếu chưa mở shop).
class UserShop {
  UserShop({required this.id, required this.name, this.status});

  final int id;
  final String name;
  final String? status;

  factory UserShop.fromJson(Map<String, dynamic> json) => UserShop(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String? ?? '',
        status: json['status'] as String?,
      );
}

/// Người dùng đang đăng nhập.
class User {
  User({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    required this.role,
    this.shop,
  });

  final int id;
  final String email;
  final String fullName;
  final String? phone;
  final String role; // 'customer' | 'admin'
  final UserShop? shop;

  bool get isAdmin => role == 'admin';
  bool get hasShop => shop != null;

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: (json['id'] as num).toInt(),
        email: json['email'] as String? ?? '',
        fullName: json['fullName'] as String? ?? '',
        phone: json['phone'] as String?,
        role: json['role'] as String? ?? 'customer',
        shop: json['shop'] is Map<String, dynamic>
            ? UserShop.fromJson(json['shop'] as Map<String, dynamic>)
            : null,
      );
}
