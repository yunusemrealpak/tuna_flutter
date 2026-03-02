import 'package:bloc/bloc.dart';
import 'package:tuna_chat/tuna_chat.dart';

import '../../../di/injection.dart';

part 'connection_event.dart';
part 'connection_state.dart';

class ConnectionBloc extends Bloc<ConnectionEvent, ConnectionState> {
  /// Creates a [ConnectionBloc] using the global [sl] service locator.
  ConnectionBloc() : this.withServiceLocator(sl);

  /// Creates a [ConnectionBloc] with a custom [GetIt] instance.
  /// Useful for testing.
  ConnectionBloc.withServiceLocator(this._sl) : super(ConnectionInitial()) {
    on<ConnectUserRequested>(_onConnect);
    on<DisconnectUserRequested>(_onDisconnect);
  }

  final GetIt _sl;

  Future<void> _onConnect(
    ConnectUserRequested event,
    Emitter<ConnectionState> emit,
  ) async {
    emit(ConnectionConnecting());
    final result = await _sl<ConnectionRepository>().connectUser(
      userId: event.userId,
      token: event.token,
    );
    result.fold(
      (failure) => emit(ConnectionError(failure.message)),
      (user) => emit(ConnectionConnected(user)),
    );
  }

  Future<void> _onDisconnect(
    DisconnectUserRequested event,
    Emitter<ConnectionState> emit,
  ) async {
    await _sl<ConnectionRepository>().disconnectUser();
    emit(ConnectionDisconnected());
  }
}
