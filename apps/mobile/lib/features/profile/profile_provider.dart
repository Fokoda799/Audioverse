import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:Audioverse/core/network/file_upload/storage_repository.dart';
import 'package:Audioverse/core/utils/app_logger.dart';
import 'package:Audioverse/features/profile/profile_models.dart';
import 'package:Audioverse/features/profile/profile_repository.dart';

// profile_provider.dart
class ProfileProvider extends ChangeNotifier {
  final ProfileRepository _repository;
  final StorageRepository _storageRepository;

  ProfileProvider({
    required ProfileRepository repository,
    required StorageRepository storageRepository,
  })
    : _repository =         repository,
      _storageRepository =  storageRepository;

  bool _isLoading    = false;
  bool _isUploadingAvatar = false;
  Profile? _profile;
  String? _errorMessage;

  bool         get isLoading    => _isLoading;
  bool get isUploadingAvatar => _isUploadingAvatar;
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


  Future<void> updateAvatar(File imageFile) async {
    _isUploadingAvatar = true;
    notifyListeners();

    try {
      final publicId = await _storageRepository.uploadCoverImage(imageFile);
      await _repository.update(_profile!.copyWith(avatarUrl: publicId));
      _clearError();
    } catch (e, st) {
      AppLogger.e('Failed to update avatar', error: e, stackTrace: st);
      _setError(e);
      rethrow; // let ProfileScreen know it failed, so it can decide whether
      // to keep showing the local preview or revert it (see screen
      // changes below)
    } finally {
      _isUploadingAvatar = false;
      notifyListeners();
    }
  }

  void _setLoading()        { _isLoading = true;  _errorMessage = null; notifyListeners(); }
  void _stopLoading()       { _isLoading = false; notifyListeners(); }
  void _setError(Object e)  { _errorMessage = e.toString().replaceAll('Exception: ', ''); }
  void _clearError()        { _errorMessage = null; }
}
