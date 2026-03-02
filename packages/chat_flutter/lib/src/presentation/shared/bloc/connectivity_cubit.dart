import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:chat_core/chat_core.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../../di/injection.dart';

part 'connectivity_state.dart';

class ConnectivityCubit extends Cubit<ConnectivityState> {
  ConnectivityCubit()
      : super(const ConnectivityState(isOnline: true)) {
    _init();
  }

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  Future<void> _init() async {
    // Check initial connectivity
    final results = await Connectivity().checkConnectivity();
    _handleResults(results);

    // Listen for changes
    _subscription = Connectivity().onConnectivityChanged.listen(
      _handleResults,
    );
  }

  void _handleResults(List<ConnectivityResult> results) {
    final isOnline = results.any(
      (r) => r != ConnectivityResult.none,
    );
    final wasOffline = !state.isOnline;
    emit(ConnectivityState(isOnline: isOnline));

    // If coming back online, trigger sync
    if (isOnline && wasOffline) {
      sl<SyncEngine>().start();
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
