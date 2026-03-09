import '../../core/type_defs.dart';
import '../entities/channel.dart';
import '../entities/membership.dart';

/// Repository for channel CRUD and membership management.
///
/// All methods return [FutureEither] — fold on the result to handle
/// [Failure] (network / auth / server errors) and success values.
///
/// The concrete implementation ([ChannelRepositoryImpl]) is registered
/// in the SDK's dependency injection container. Host apps access it via
/// `TunaChatSDK.instance` or BLoC providers.
abstract class ChannelRepository {
  /// Creates a new channel and adds [memberIds] as initial members.
  ///
  /// - [type]: channel type ([ChannelType.direct], [ChannelType.group], or [ChannelType.public])
  /// - [name]: display name (required for group/public, ignored for direct)
  /// - [description]: optional topic or description
  /// - [memberIds]: list of user IDs to add on creation (in addition to the creator)
  FutureEither<Channel> createChannel({
    required ChannelType type,
    String? name,
    String? description,
    required List<String> memberIds,
  });

  /// Fetches a single channel by [channelId].
  FutureEither<Channel> getChannel(String channelId);

  /// Returns a paginated list of channels the current user is a member of.
  ///
  /// Pass [cursor] from the previous response to fetch the next page.
  FutureEither<({List<Channel> channels, String? nextCursor})> listChannels({
    String? cursor,
    int limit = 20,
  });

  /// Updates [name], [description], and/or [avatarUrl] of a channel.
  FutureEither<Channel> updateChannel(
    String channelId, {
    String? name,
    String? description,
    String? avatarUrl,
  });

  /// Permanently deletes a channel and all its messages.
  FutureEither<void> deleteChannel(String channelId);

  /// Adds a user to the channel with the given [role].
  FutureEither<Membership> addMember(
    String channelId, {
    required String userId,
    required MemberRole role,
  });

  /// Removes a user from the channel.
  FutureEither<void> removeMember(String channelId, String userId);

  /// Returns the full list of members for a channel, including display names and avatars.
  FutureEither<List<Membership>> getMembers(String channelId);

  /// Marks all messages in the channel as read up to [messageId].
  ///
  /// Also resets the [Channel.unreadCount] for this channel in the local cache.
  FutureEither<void> markAsRead(String channelId, String messageId);
}
