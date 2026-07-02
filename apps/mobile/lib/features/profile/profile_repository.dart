import 'package:Audioverse/features/profile/profile_models.dart';

// Profile Repository â€” abstract contract
//
// Defines WHAT the profile feature can do.
// The implementation (profile_repository_impl.dart) decides HOW.
//
// This separation means you can swap implementations freely:
//   - Real API in production
//   - Mock in tests
//   - Local cache during offline mode

abstract class ProfileRepository {
  Future<Profile>  getProfile();
  Future<Profile>  update(UpdateProfileRequest data);
  // Future<void>     delete(String id);
}
