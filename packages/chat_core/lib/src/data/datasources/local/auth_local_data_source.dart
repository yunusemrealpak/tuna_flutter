import 'package:drift/drift.dart';

import 'app_database.dart';
import 'daos/user_dao.dart';
import '../remote/token_storage.dart';
import '../../../domain/entities/user.dart';

abstract class AuthLocalDataSource {
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  });

  Future<String?> getAccessToken();

  Future<String?> getRefreshToken();

  Future<void> clearTokens();

  Future<void> saveUserId(String userId);

  Future<String?> getSavedUserId();

  /// Persist [user] to local DB so it survives app restarts.
  Future<void> cacheUser(User user);

  /// Returns the current user from local DB by [userId].
  /// Returns null if not found or if [userId] is null.
  Future<User?> getCachedUser(String? userId);

  Future<void> clearUser(String? userId);
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  AuthLocalDataSourceImpl(this._tokenStorage, this._userDao);

  final TokenStorage _tokenStorage;
  final UserDao _userDao;

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
  Future<void> saveUserId(String userId) => _tokenStorage.saveUserId(userId);

  @override
  Future<String?> getSavedUserId() => _tokenStorage.getSavedUserId();

  @override
  Future<void> cacheUser(User user) => _userDao.upsert(
        UsersTableCompanion(
          id: Value(user.id),
          username: Value(user.username),
          displayName: Value(user.displayName),
          avatarUrl: Value(user.avatarUrl),
          lastSeenAt: Value(user.lastSeenAt),
          createdAt: Value(user.createdAt),
        ),
      );

  @override
  Future<User?> getCachedUser(String? userId) async {
    if (userId == null) return null;
    final row = await _userDao.findById(userId);
    if (row == null) return null;
    return User(
      id: row.id,
      username: row.username,
      displayName: row.displayName,
      avatarUrl: row.avatarUrl,
      lastSeenAt: row.lastSeenAt,
      createdAt: row.createdAt,
    );
  }

  @override
  Future<void> clearUser(String? userId) async {
    if (userId == null) return;
    await _userDao.deleteById(userId);
  }
}
