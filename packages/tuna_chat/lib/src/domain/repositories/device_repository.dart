import '../../core/type_defs.dart';

/// Repository for managing push notification device tokens.
///
/// Communicates with `POST /api/v1/devices` and `DELETE /api/v1/devices`.
abstract class DeviceRepository {
  /// Registers a device token for push notifications.
  ///
  /// [platform] must be one of: `ios`, `android`, `web`.
  /// [pushProvider] must be one of: `fcm`, `apns`.
  /// The call is idempotent — registering the same token twice is safe.
  FutureEither<void> registerToken({
    required String token,
    required String platform,
    required String pushProvider,
  });

  /// Deregisters a device token, stopping push delivery to this device.
  FutureEither<void> deregisterToken(String token);
}
