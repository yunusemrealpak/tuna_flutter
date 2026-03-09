/// Data-layer exceptions thrown by `DataSource` implementations.
///
/// Repository implementations catch these exceptions and convert them to
/// [Failure] subclasses via `Either<Failure, T>`.
library;

/// Thrown when the TunaChat backend returns a non-2xx HTTP response.
///
/// Contains the HTTP [statusCode], a machine-readable [errorCode], and a
/// human-readable [message] from the error envelope.
class ServerException implements Exception {
  const ServerException({
    required this.message,
    required this.statusCode,
    required this.errorCode,
  });

  final String message;

  /// HTTP status code returned by the backend (e.g. 400, 404, 500).
  final int statusCode;

  /// Machine-readable error code from the response body (e.g. `NOT_FOUND`).
  final String errorCode;

  @override
  String toString() =>
      'ServerException(statusCode: $statusCode, errorCode: $errorCode, message: $message)';
}

/// Thrown when a local database (Drift/SQLite) operation fails.
class CacheException implements Exception {
  const CacheException({required this.message});
  final String message;

  @override
  String toString() => 'CacheException(message: $message)';
}

/// Thrown when a network request cannot be completed (timeout, no connectivity).
class NetworkException implements Exception {
  const NetworkException({required this.message});
  final String message;

  @override
  String toString() => 'NetworkException(message: $message)';
}

/// Thrown when the backend returns HTTP 401 and token refresh fails.
///
/// This typically means the user's JWT has expired and a fresh token could
/// not be obtained from [TunaChatConfig.tokenProvider].
class AuthException implements Exception {
  const AuthException({required this.message, required this.errorCode});
  final String message;

  /// Machine-readable error code (e.g. `UNAUTHORIZED`, `TOKEN_EXPIRED`).
  final String errorCode;

  @override
  String toString() =>
      'AuthException(errorCode: $errorCode, message: $message)';
}
