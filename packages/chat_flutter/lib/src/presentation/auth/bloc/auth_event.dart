part of 'auth_bloc.dart';

abstract class AuthEvent {}

class AuthCheckStatusRequested extends AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;
  AuthLoginRequested({required this.email, required this.password});
}

class AuthRegisterRequested extends AuthEvent {
  final String username;
  final String email;
  final String password;
  final String? displayName;
  AuthRegisterRequested({
    required this.username,
    required this.email,
    required this.password,
    this.displayName,
  });
}

class AuthLogoutRequested extends AuthEvent {}
