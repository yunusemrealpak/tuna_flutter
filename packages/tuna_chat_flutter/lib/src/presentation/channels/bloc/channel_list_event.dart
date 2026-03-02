part of 'channel_list_bloc.dart';

abstract class ChannelListEvent {}

class ChannelListLoadRequested extends ChannelListEvent {}

class ChannelListRefreshRequested extends ChannelListEvent {}

class ChannelListLoadMoreRequested extends ChannelListEvent {}

class ChannelListChannelUpdated extends ChannelListEvent {
  final Channel channel;
  ChannelListChannelUpdated(this.channel);
}
