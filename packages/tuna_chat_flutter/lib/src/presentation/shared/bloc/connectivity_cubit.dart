import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:tuna_chat/tuna_chat.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../../di/injection.dart';

part 'connectivity_state.dart';

class ConnectivityCubit extends Cubit<ConnectivityState> {
  /// Creates a [ConnectivityCubit] using the global service locator.
  ConnectivityCubit()
      : this.withDependencies(
          syncEngine: sl<SyncEngine>(),
          connectivity: Connectivity(),
        );

  /// Creates a [ConnectivityCubit] with explicit dependencies. Useful for testing.
  ConnectivityCubit.withDependencies({
    required SyncEngine syncEngine,
    required Connectivity connectivity,
  })  : _syncEngine = syncEngine,
        _connectivity = connectivity,
        super(const ConnectivityState(isOnline: true)) {
    _init();
  }

  final SyncEngine _syncEngine;
  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  Future<void> _init() async {
    // Check initial connectivity
    final results = await _connectivity.checkConnectivity();
    _handleResults(results);

    // Listen for changes
    _subscription = _connectivity.onConnectivityChanged.listen(_handleResults);
  }

  void _handleResults(List<ConnectivityResult> results) {
    final isOnline = results.any(
      (r) => r != ConnectivityResult.none,
    );
    final wasOffline = !state.isOnline;
    emit(ConnectivityState(isOnline: isOnline));

    // If coming back online, trigger sync
    if (isOnline && wasOffline) {
      _syncEngine.start();
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
