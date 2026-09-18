/// Địa chỉ nhận hàng.
class Address {
  Address({
    required this.id,
    required this.recipientName,
    required this.phone,
    required this.line,
    this.ward,
    this.district,
    this.province,
    required this.isDefault,
  });

  final int id;
  final String recipientName;
  final String phone;
  final String line;
  final String? ward;
  final String? district;
  final String? province;
  final bool isDefault;

  /// Gộp thành 1 dòng địa chỉ đầy đủ để hiển thị.
  String get fullAddress =>
      [line, ward, district, province].where((e) => e != null && e.isNotEmpty).join(', ');

  factory Address.fromJson(Map<String, dynamic> json) => Address(
        id: (json['id'] as num).toInt(),
        recipientName: json['recipientName'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        line: json['line'] as String? ?? '',
        ward: json['ward'] as String?,
        district: json['district'] as String?,
        province: json['province'] as String?,
        isDefault: json['isDefault'] as bool? ?? false,
      );
}
