import 'package:flutter/foundation.dart';
import 'package:Audioverse/core/utils/app_logger.dart';
import 'profile_models.dart';
import 'profile_repository.dart';

// Profile Provider
//
// Owns ALL state for the profile feature.
// Screens read from it via context.watch<ProfileProvider>()
// Screens call methods via context.read<ProfileProvider>().methodName()
//
// State the UI reacts to:
//   isLoading    â†’ show spinners, disable buttons
//   data         â†’ the main data object for this feature
//   errorMessage â†’ show error banners

// profile_provider.dart
class ProfileProvider extends ChangeNotifier {
  final ProfileRepository _repository;

  ProfileProvider({required ProfileRepository repository})
      : _repository = repository;

  bool         _isLoading    = false;
  Profile? _profile;
  String?      _errorMessage;

  bool         get isLoading    => _isLoading;
  Profile? get profile      => _profile;
  String?      get errorMessage => _errorMessage;

  // Convenient direct getters — so screens don't have to
  // write profile?.displayName every single time
  String?           get displayName => _profile?.displayName;
  String?           get avatarUrl   => _profile?.avatarUrl;
  String?           get bio         => _profile?.bio;
  UserPreferences   get preferences => _profile?.preferences ?? const UserPreferences();

  Future<void> loadProfile() async {
    _setLoading();
    try {
      _profile = await _repository.getProfile();
      _clearError();
    } catch (e, st) {
      AppLogger.e('Failed to load profile', error: e, stackTrace: st);
      _setError(e);
    } finally {
      _stopLoading();
    }
  }

  void _setLoading()        { _isLoading = true;  _errorMessage = null; notifyListeners(); }
  void _stopLoading()       { _isLoading = false; notifyListeners(); }
  void _setError(Object e)  { _errorMessage = e.toString().replaceAll('Exception: ', ''); }
  void _clearError()        { _errorMessage = null; }
}
