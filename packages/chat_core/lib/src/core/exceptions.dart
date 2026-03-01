/// Data-layer exceptions.
/// DataSources throw these; Repositories catch and convert to Failures.
library;

class ServerException implements Exception {
  const ServerException({
    required this.message,
    required this.statusCode,
    required this.errorCode,
  });

  final String message;
  final int statusCode;
  final String errorCode;

  @override
  String toString() =>
      'ServerException(statusCode: $statusCode, errorCode: $errorCode, message: $message)';
}

class CacheException implements Exception {
  const CacheException({required this.message});
  final String message;

  @override
  String toString() => 'CacheException(message: $message)';
}

class NetworkException implements Exception {
  const NetworkException({required this.message});
  final String message;

  @override
  String toString() => 'NetworkException(message: $message)';
}

class AuthException implements Exception {
  const AuthException({required this.message, required this.errorCode});
  final String message;
  final String errorCode;

  @override
  String toString() =>
      'AuthException(errorCode: $errorCode, message: $message)';
}
