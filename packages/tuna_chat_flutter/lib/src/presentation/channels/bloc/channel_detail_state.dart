part of 'channel_detail_cubit.dart';

abstract class ChannelDetailState {}

class ChannelDetailInitial extends ChannelDetailState {}

class ChannelDetailLoading extends ChannelDetailState {}

class ChannelDetailLoaded extends ChannelDetailState {
  final List<Membership> members;
  final MemberRole? currentUserRole;
  final String? currentUserId;

  ChannelDetailLoaded({
    required this.members,
    this.currentUserRole,
    this.currentUserId,
  });

  bool get isOwner => currentUserRole == MemberRole.owner;
  bool get isAdmin =>
      currentUserRole == MemberRole.admin ||
      currentUserRole == MemberRole.owner;

  ChannelDetailLoaded copyWith({
    List<Membership>? members,
    MemberRole? currentUserRole,
    String? currentUserId,
  }) =>
      ChannelDetailLoaded(
        members: members ?? this.members,
        currentUserRole: currentUserRole ?? this.currentUserRole,
        currentUserId: currentUserId ?? this.currentUserId,
      );
}

class ChannelDetailError extends ChannelDetailState {
  final String message;
  ChannelDetailError(this.message);
}

class ChannelDetailDeleted extends ChannelDetailState {}
