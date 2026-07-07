import 'package:Audioverse/features/auth/auth.dart';

// This is the CONTRACT — a pure description of what auth can do.
// It has no code inside the methods, just the signatures.
// Nothing in here knows about Dio, HTTP, or JSON.
abstract class AuthRepository {
  Future<User> register({
    required String name,
    required String email,
    required String password,
  });

  Future<User> login({
    required String email,
    required String password,
  });

  Future<User> googleSignIn({
    required String tokenId,
  });

  Future<void> logout();

  Future<void> refreshToken(String refreshToken);

  Future<User> getCurrentUser();

  Future<bool> deleteAccount(String password);
}
