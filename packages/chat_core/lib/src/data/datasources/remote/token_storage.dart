/// Abstract token storage interface.
///
/// chat_core defines the contract; chat_flutter provides the concrete
/// implementation backed by flutter_secure_storage.
abstract class TokenStorage {
  Future<String?> getAccessToken();
  Future<String?> getRefreshToken();
  Future<String?> getSavedUserId();
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  });
  Future<void> saveUserId(String userId);
  Future<void> clearTokens();
}
