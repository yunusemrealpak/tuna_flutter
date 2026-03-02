import '../../core/type_defs.dart';
import '../entities/user.dart';

abstract class UserRepository {
  FutureEither<User> getMe();

  FutureEither<User> updateProfile({
    String? displayName,
    String? avatarUrl,
  });

  FutureEither<User> getUser(String userId);

  FutureEither<List<User>> searchUsers(String query);
}
