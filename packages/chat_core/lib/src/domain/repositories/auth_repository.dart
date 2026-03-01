import '../../core/type_defs.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  FutureEither<({User user, String accessToken, String refreshToken})> register({
    required String username,
    required String email,
    required String password,
    String? displayName,
  });

  FutureEither<({User user, String accessToken, String refreshToken})> login({
    required String email,
    required String password,
  });

  FutureEither<({String accessToken, String refreshToken})> refreshToken({
    required String refreshToken,
  });

  FutureEither<void> logout();

  FutureEither<User?> getCurrentUser();
}
