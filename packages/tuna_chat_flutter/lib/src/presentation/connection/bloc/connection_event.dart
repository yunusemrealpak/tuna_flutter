part of 'connection_bloc.dart';

abstract class ConnectionEvent {}

class ConnectUserRequested extends ConnectionEvent {
  ConnectUserRequested({required this.userId, required this.token});
  final String userId;
  final String token;
}

class DisconnectUserRequested extends ConnectionEvent {}
