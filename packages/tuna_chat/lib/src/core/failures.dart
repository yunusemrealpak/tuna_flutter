import 'package:equatable/equatable.dart';

/// Abstract base for all domain-layer failures.
///
/// Repositories map [Exception]s thrown by data sources to [Failure] subclasses
/// and return them as the `Left` side of `Either<Failure, T>`.
///
/// ```dart
/// final result = await messageRepo.sendMessage(channelId, text: 'Hello');
/// result.fold(
///   (failure) {
///     if (failure is NetworkFailure) showOfflineBanner();
///     if (failure is AuthFailure)   redirectToLogin();
///     if (failure is ServerFailure) showErrorToast(failure.message);
///   },
///   (message) => updateUI(message),
/// );
/// ```
abstract class Failure extends Equatable {
  const Failure({required this.message});

  /// Human-readable description of the failure.
  final String message;

  @override
  List<Object> get props => [message];
}

/// Failure originating from a non-2xx backend response.
class ServerFailure extends Failure {
  const ServerFailure({required super.message, required this.errorCode});

  /// Machine-readable error code from the backend (e.g. `NOT_FOUND`).
  final String errorCode;

  @override
  List<Object> get props => [message, errorCode];
}

/// Failure from a local Drift/SQLite cache operation.
class CacheFailure extends Failure {
  const CacheFailure({required super.message});
}

/// Failure due to network unavailability or request timeout.
class NetworkFailure extends Failure {
  const NetworkFailure({required super.message});
}

/// Failure due to authentication error (expired JWT, invalid token).
class AuthFailure extends Failure {
  const AuthFailure({required super.message, required this.errorCode});

  /// Machine-readable error code (e.g. `UNAUTHORIZED`, `TOKEN_EXPIRED`).
  final String errorCode;

  @override
  List<Object> get props => [message, errorCode];
}
