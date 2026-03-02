import '../../core/type_defs.dart';
import '../entities/channel.dart';
import '../entities/membership.dart';

abstract class ChannelRepository {
  FutureEither<Channel> createChannel({
    required ChannelType type,
    String? name,
    String? description,
    required List<String> memberIds,
  });

  FutureEither<Channel> getChannel(String channelId);

  FutureEither<({List<Channel> channels, String? nextCursor})> listChannels({
    String? cursor,
    int limit = 20,
  });

  FutureEither<Channel> updateChannel(
    String channelId, {
    String? name,
    String? description,
    String? avatarUrl,
  });

  FutureEither<void> deleteChannel(String channelId);

  FutureEither<Membership> addMember(
    String channelId, {
    required String userId,
    required MemberRole role,
  });

  FutureEither<void> removeMember(String channelId, String userId);

  FutureEither<List<Membership>> getMembers(String channelId);

  FutureEither<void> markAsRead(String channelId, String messageId);
}
