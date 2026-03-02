import '../../core/type_defs.dart';
import '../entities/user.dart';

/// Repository for managing the SDK connection lifecycle.
///
/// Host app calls [connectUser] after obtaining a host-signed JWT from
/// its own backend. The SDK validates the token by fetching the user
/// profile from the server and establishes a WebSocket connection.
abstract class ConnectionRepository {
  /// Connect the SDK with the given [userId] (external ID from host app)
  /// and [token] (HMAC-SHA256 JWT signed by host backend with api_secret).
  ///
  /// On success: token set in ApiClient, WS connection established,
  /// current user available via [currentUser].
  FutureEither<User> connectUser({
    required String userId,
    required String token,
  });

  /// Disconnect the SDK: close WS, clear in-memory token and user.
  FutureEither<void> disconnectUser();

  /// The currently connected user, or null if not connected.
  User? get currentUser;
}
