part of 'channel_list_bloc.dart';

abstract class ChannelListState {}

class ChannelListInitial extends ChannelListState {}

class ChannelListLoading extends ChannelListState {}

class ChannelListLoaded extends ChannelListState {
  final List<Channel> channels;
  final bool hasMore;
  final String? nextCursor;

  ChannelListLoaded({
    required this.channels,
    required this.hasMore,
    this.nextCursor,
  });
}

class ChannelListError extends ChannelListState {
  final String message;
  ChannelListError(this.message);
}
