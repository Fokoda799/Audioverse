import 'package:Audioverse/features/settings/settings_models.dart';

// Settings Repository â€” abstract contract
//
// Defines WHAT the settings feature can do.
// The implementation (settings_repository_impl.dart) decides HOW.
//
// This separation means you can swap implementations freely:
//   - Real API in production
//   - Mock in tests
//   - Local cache during offline mode

abstract class SettingsRepository {
  Future<UserPreferences> updatePreferences(UserPreferences data);

  Future<UserPreferences> getPreferences();

}
