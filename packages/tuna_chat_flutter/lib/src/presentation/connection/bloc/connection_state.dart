part of 'connection_bloc.dart';

abstract class ConnectionState {}

class ConnectionInitial extends ConnectionState {}

class ConnectionConnecting extends ConnectionState {}

class ConnectionConnected extends ConnectionState {
  ConnectionConnected(this.user);
  final User user;
}

class ConnectionDisconnected extends ConnectionState {}

class ConnectionError extends ConnectionState {
  ConnectionError(this.message);
  final String message;
}
