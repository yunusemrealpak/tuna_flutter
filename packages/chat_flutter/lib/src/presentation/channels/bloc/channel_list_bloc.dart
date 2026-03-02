import 'package:bloc/bloc.dart';
import 'package:chat_core/chat_core.dart';

import '../../../di/injection.dart';

part 'channel_list_event.dart';
part 'channel_list_state.dart';

class ChannelListBloc extends Bloc<ChannelListEvent, ChannelListState> {
  /// Creates a [ChannelListBloc] using the global [sl] service locator.
  ChannelListBloc() : this.withServiceLocator(sl);

  /// Creates a [ChannelListBloc] with a custom [GetIt] instance.
  /// Useful for testing.
  ChannelListBloc.withServiceLocator(this._sl) : super(ChannelListInitial()) {
    on<ChannelListLoadRequested>(_onLoad);
    on<ChannelListRefreshRequested>(_onRefresh);
    on<ChannelListLoadMoreRequested>(_onLoadMore);
    on<ChannelListChannelUpdated>(_onChannelUpdated);
  }

  final GetIt _sl;
  static const int _pageSize = 20;

  Future<void> _onLoad(
    ChannelListLoadRequested event,
    Emitter<ChannelListState> emit,
  ) async {
    emit(ChannelListLoading());
    final result = await _sl<ChannelRepository>().listChannels(
      limit: _pageSize,
    );
    result.fold(
      (failure) => emit(ChannelListError(failure.message)),
      (data) => emit(ChannelListLoaded(
        channels: data.channels,
        hasMore: data.nextCursor != null,
        nextCursor: data.nextCursor,
      )),
    );
  }

  Future<void> _onRefresh(
    ChannelListRefreshRequested event,
    Emitter<ChannelListState> emit,
  ) async {
    final result = await _sl<ChannelRepository>().listChannels(
      limit: _pageSize,
    );
    result.fold(
      (failure) => emit(ChannelListError(failure.message)),
      (data) => emit(ChannelListLoaded(
        channels: data.channels,
        hasMore: data.nextCursor != null,
        nextCursor: data.nextCursor,
      )),
    );
  }

  Future<void> _onLoadMore(
    ChannelListLoadMoreRequested event,
    Emitter<ChannelListState> emit,
  ) async {
    final current = state;
    if (current is! ChannelListLoaded || !current.hasMore) return;

    final result = await _sl<ChannelRepository>().listChannels(
      cursor: current.nextCursor,
      limit: _pageSize,
    );
    result.fold(
      (failure) => emit(ChannelListError(failure.message)),
      (data) => emit(ChannelListLoaded(
        channels: [...current.channels, ...data.channels],
        hasMore: data.nextCursor != null,
        nextCursor: data.nextCursor,
      )),
    );
  }

  Future<void> _onChannelUpdated(
    ChannelListChannelUpdated event,
    Emitter<ChannelListState> emit,
  ) async {
    final current = state;
    if (current is! ChannelListLoaded) return;

    final updatedChannels = current.channels.map((c) {
      return c.id == event.channel.id ? event.channel : c;
    }).toList();

    emit(ChannelListLoaded(
      channels: updatedChannels,
      hasMore: current.hasMore,
      nextCursor: current.nextCursor,
    ));
  }
}
