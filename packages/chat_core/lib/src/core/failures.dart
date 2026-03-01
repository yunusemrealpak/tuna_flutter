import 'package:equatable/equatable.dart';

/// Domain-layer failures returned via `Either<Failure, T>`.
/// Repositories map Exceptions to Failures.
abstract class Failure extends Equatable {
  const Failure({required this.message});
  final String message;

  @override
  List<Object> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure({required super.message, required this.errorCode});
  final String errorCode;

  @override
  List<Object> get props => [message, errorCode];
}

class CacheFailure extends Failure {
  const CacheFailure({required super.message});
}

class NetworkFailure extends Failure {
  const NetworkFailure({required super.message});
}

class AuthFailure extends Failure {
  const AuthFailure({required super.message, required this.errorCode});
  final String errorCode;

  @override
  List<Object> get props => [message, errorCode];
}
