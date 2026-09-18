import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api/api_client.dart';
import 'storage/token_storage.dart';

/// Singleton ApiClient dùng chung toàn app (tự gắn token).
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

/// Nơi lưu token đăng nhập trên máy.
final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());
