/// Abstract token storage interface.
///
/// chat_core defines the contract; chat_flutter provides the concrete
/// implementation backed by flutter_secure_storage.
abstract class TokenStorage {
  Future<String?> getAccessToken();
  Future<String?> getRefreshToken();
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  });
  Future<void> clearTokens();
}
