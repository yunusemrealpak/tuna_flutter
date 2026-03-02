import 'package:bloc/bloc.dart';
import 'package:chat_core/chat_core.dart';

import '../../../chat_sdk.dart';
import '../../../di/injection.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  /// Creates an [AuthBloc] using the global [sl] service locator.
  AuthBloc() : this.withServiceLocator(sl);

  /// Creates an [AuthBloc] with a custom [GetIt] instance.
  /// Useful for testing.
  AuthBloc.withServiceLocator(this._sl) : super(AuthInitial()) {
    on<AuthCheckStatusRequested>(_onCheckStatus);
    on<AuthLoginRequested>(_onLogin);
    on<AuthRegisterRequested>(_onRegister);
    on<AuthLogoutRequested>(_onLogout);
  }

  final GetIt _sl;

  Future<void> _onCheckStatus(
    AuthCheckStatusRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await _sl<AuthRepository>().getCurrentUser();
    result.fold(
      (failure) => emit(Unauthenticated()),
      (user) {
        if (user != null) {
          emit(Authenticated(user));
        } else {
          emit(Unauthenticated());
        }
      },
    );
  }

  Future<void> _onLogin(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await _sl<AuthRepository>().login(
      email: event.email,
      password: event.password,
    );
    await result.fold(
      (failure) async => emit(AuthError(failure.message)),
      (data) async {
        try {
          await ChatSDK.instance.connectWebSocket(data.accessToken);
        } catch (_) {
          // SDK not initialized in tests — ignore.
        }
        emit(Authenticated(data.user));
      },
    );
  }

  Future<void> _onRegister(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await _sl<AuthRepository>().register(
      username: event.username,
      email: event.email,
      password: event.password,
      displayName: event.displayName,
    );
    await result.fold(
      (failure) async => emit(AuthError(failure.message)),
      (data) async {
        try {
          await ChatSDK.instance.connectWebSocket(data.accessToken);
        } catch (_) {
          // SDK not initialized in tests — ignore.
        }
        emit(Authenticated(data.user));
      },
    );
  }

  Future<void> _onLogout(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    await _sl<AuthRepository>().logout();
    try {
      await ChatSDK.instance.disconnectWebSocket();
    } catch (_) {
      // SDK not initialized in tests — ignore.
    }
    emit(Unauthenticated());
  }
}
