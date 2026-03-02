part of 'create_channel_bloc.dart';

abstract class CreateChannelEvent {}

class CreateChannelSearchUsers extends CreateChannelEvent {
  final String query;
  CreateChannelSearchUsers(this.query);
}

class CreateChannelToggleMember extends CreateChannelEvent {
  final User user;
  CreateChannelToggleMember(this.user);
}

class CreateChannelSubmitted extends CreateChannelEvent {
  final ChannelType type;
  final String? name;
  final String? description;

  CreateChannelSubmitted({
    required this.type,
    this.name,
    this.description,
  });
}
