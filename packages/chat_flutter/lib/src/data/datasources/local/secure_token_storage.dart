import 'package:chat_core/chat_core.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Concrete [TokenStorage] backed by [FlutterSecureStorage].
///
/// Lives in `chat_flutter` (not `chat_core`) because flutter_secure_storage
/// is a Flutter plugin that requires native platform code.
class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _kAccessTokenKey = 'chat_sdk_access_token';
  static const _kRefreshTokenKey = 'chat_sdk_refresh_token';
  static const _kUserIdKey = 'chat_sdk_user_id';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> getAccessToken() => _storage.read(key: _kAccessTokenKey);

  @override
  Future<String?> getRefreshToken() => _storage.read(key: _kRefreshTokenKey);

  @override
  Future<String?> getSavedUserId() => _storage.read(key: _kUserIdKey);

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _kAccessTokenKey, value: accessToken);
    await _storage.write(key: _kRefreshTokenKey, value: refreshToken);
  }

  @override
  Future<void> saveUserId(String userId) =>
      _storage.write(key: _kUserIdKey, value: userId);

  @override
  Future<void> clearTokens() async {
    await _storage.delete(key: _kAccessTokenKey);
    await _storage.delete(key: _kRefreshTokenKey);
    await _storage.delete(key: _kUserIdKey);
  }
}
