/// Các hằng số dùng chung toàn app.
library;

/// Địa chỉ gốc của backend API.
///
/// LƯU Ý khi chạy thật:
/// - iOS Simulator / máy tính: dùng http://localhost:4100
/// - Android Emulator: đổi thành http://10.0.2.2:4100 (emulator hiểu 10.0.2.2 là máy tính)
/// - Điện thoại thật: dùng IP LAN của máy tính, ví dụ http://192.168.1.10:4100
const String kApiBaseUrl = 'http://localhost:4100/api';

/// Tên app hiển thị.
const String kAppName = 'ViMart';
