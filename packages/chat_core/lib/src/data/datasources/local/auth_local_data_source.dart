import '../../datasources/remote/token_storage.dart';
import '../../../domain/entities/user.dart';

abstract class AuthLocalDataSource {
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  });

  Future<String?> getAccessToken();

  Future<String?> getRefreshToken();

  Future<void> clearTokens();

  Future<void> cacheUser(User user);

  Future<User?> getCachedUser();

  Future<void> clearUser();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  AuthLocalDataSourceImpl(this._tokenStorage);

  final TokenStorage _tokenStorage;
  User? _cachedUser;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) =>
      _tokenStorage.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );

  @override
  Future<String?> getAccessToken() => _tokenStorage.getAccessToken();

  @override
  Future<String?> getRefreshToken() => _tokenStorage.getRefreshToken();

  @override
  Future<void> clearTokens() => _tokenStorage.clearTokens();

  @override
  Future<void> cacheUser(User user) async {
    _cachedUser = user;
  }

  @override
  Future<User?> getCachedUser() async => _cachedUser;

  @override
  Future<void> clearUser() async {
    _cachedUser = null;
  }
}
