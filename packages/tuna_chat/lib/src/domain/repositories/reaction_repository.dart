import '../../core/type_defs.dart';
import '../entities/reaction.dart';

abstract class ReactionRepository {
  FutureEither<Reaction> addReaction(
    String channelId,
    String messageId, {
    required String type,
  });

  FutureEither<List<Reaction>> getReactions(
    String channelId,
    String messageId,
  );

  FutureEither<void> removeReaction(
    String channelId,
    String messageId,
    String type,
  );
}
