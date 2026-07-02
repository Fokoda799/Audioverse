import 'package:Audioverse/core/audio/playback_preferences.dart';
import 'package:Audioverse/core/utils/app_logger.dart';
import 'package:Audioverse/features/settings/settings.dart';
import 'package:flutter/foundation.dart';

enum DownloadQuality { low, medium, high }

extension DownloadQualityLabel on DownloadQuality {
  String get label {
    switch (this) {
      case DownloadQuality.low:
        return 'Low';
      case DownloadQuality.medium:
        return 'Medium';
      case DownloadQuality.high:
        return 'High';
    }
  }

  String get description {
    switch (this) {
      case DownloadQuality.low:
        return 'Uses less storage';
      case DownloadQuality.medium:
        return 'Balanced';
      case DownloadQuality.high:
        return 'Best audio quality';
    }
  }

  static DownloadQuality fromString(String value) {
    switch (value) {
      case 'low':
        return DownloadQuality.low;
      case 'medium':
        return DownloadQuality.medium;
      case 'high':
        return DownloadQuality.high;
      default:
        return DownloadQuality.medium;
    }
  }
}

class SettingsProvider extends ChangeNotifier {
  final SettingsRepository _repository;

  SettingsProvider({required SettingsRepository repository})
    : _repository = repository;

  // Supported playback speeds — matches AudioPlayerService speeds
  static const List<double> supportedSpeeds = [
    0.5,
    0.75,
    1.0,
    1.25,
    1.5,
    1.75,
    2.0,
  ];
  // static const List<String> supportedQuality = ['low', 'medium', 'high'];
  // static const List<String> supportedNotification = ['new_releases', 'download_complete', 'recommendations'];

  UserPreferences? _preferences;
  double _defaultPlaybackSpeed = 1.0;
  Map<String?, bool> _notifications = {
    "new_releases": false,
    "download_complete": false,
    "recommendations": false,
  };
  double get defaultPlaybackSpeed => _defaultPlaybackSpeed;
  UserPreferences? get preferences => _preferences;
  Map<String?, bool> get notifications => _notifications;

  DownloadQuality? _downloadQuality = DownloadQuality.medium;
  DownloadQuality? get downloadQuality => _downloadQuality;

  bool _isLoading = false;
  String? _errorMessage;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Call once at app startup (in MultiProvider / main.dart).
  Future<void> load() async {
    _setLoading();

    try {
      _preferences = await _repository.getPreferences();
      _defaultPlaybackSpeed = _preferences?.playbackSpeed ?? 1.0;
      final quality = _preferences?.downloadQuality ?? 'medium';
      _downloadQuality = DownloadQualityLabel.fromString(quality);
      _notifications =
          _preferences?.notifications ??
          {
            "new_releases": false,
            "download_complete": false,
            "recommendations": false,
          };
      _clearError();
    } catch (e) {
      _defaultPlaybackSpeed = await PlaybackPreferences.getSpeed();
      _downloadQuality = DownloadQualityLabel.fromString('medium');
      _notifications = {
        "new_releases": false,
        "download_complete": false,
        "recommendations": false,
      };

      if (_isConnectivityError(e)) {
        AppLogger.w(
          'Loaded local playback speed because preferences sync is offline',
          error: e,
        );
        _clearError();
      } else {
        _setError(e);
      }
    } finally {
      _stopLoading();
    }
  }

  Future<void> setDefaultPlaybackSpeed(double speed) async {
    AppLogger.d('setDefaultPlaybackSpeed called with $speed');
    // _setLoading();
    try {
      if (!supportedSpeeds.contains(speed)) {
        AppLogger.w('Unsupported speed: $speed');
        return;
      }
      _defaultPlaybackSpeed = speed;
      await PlaybackPreferences.setSpeed(speed);
      notifyListeners();

      final currentPrefs = _preferences ?? const UserPreferences();
      final updatedPrefs = currentPrefs.copyWith(playbackSpeed: speed);
      _preferences = updatedPrefs;

      AppLogger.d('Sending updated preferences to server...');
      try {
        _preferences = await _repository.updatePreferences(updatedPrefs);

        AppLogger.i('Playback speed updated successfully');
        _clearError();
      } catch (e) {
        if (_isConnectivityError(e)) {
          AppLogger.w(
            'Skipped syncing playback speed because the app is offline',
            error: e,
          );
          _clearError();
          return;
        }

        rethrow;
      }
    } catch (e) {
      AppLogger.e('Failed to set default playback speed', error: e);
      _setError(e);
    } finally {
      // _stopLoading();
    }
  }

  Future<void> setDownloadQuality(DownloadQuality quality) async {
    AppLogger.d('setDownloadQuality called with ${quality.label}');
    // _setLoading();

    try {
      _downloadQuality = quality;
      notifyListeners();

      final currentPrefs = _preferences ?? const UserPreferences();
      final updatedPrefs = currentPrefs.copyWith(
        downloadQuality: quality.label,
      );
      _preferences = updatedPrefs;

      AppLogger.d('Sending updated preferences to server...');
      try {
        _preferences = await _repository.updatePreferences(updatedPrefs);

        AppLogger.i('Download quality updated successfully');
        _clearError();
      } catch (e) {
        if (_isConnectivityError(e)) {
          AppLogger.w(
            'Skipped syncing download quality because the app is offline',
            error: e,
          );
          _clearError();
          return;
        }

        rethrow;
      }
    } catch (e) {
      AppLogger.e('Failed to set download quality', error: e);
      _setError(e);
    } finally {
      // _stopLoading();
    }
  }

  Future<void> setNotifications(Map<String, bool> notifications) async {
    AppLogger.d('setNotifications called with $notifications');
    // _setLoading();

    try {
      _notifications = notifications;
      notifyListeners();

      final currentPrefs = _preferences ?? const UserPreferences();
      final updatedPrefs = currentPrefs.copyWith(notifications: notifications);
      _preferences = updatedPrefs;

      AppLogger.d('Sending updated preferences to server...');
      try {
        _preferences = await _repository.updatePreferences(updatedPrefs);

        AppLogger.i('Notifications updated successfully');
        _clearError();
      } catch (e) {
        if (_isConnectivityError(e)) {
          AppLogger.w(
            'Skipped syncing notifications because the app is offline',
            error: e,
          );
          _clearError();
          return;
        }

        rethrow;
      }
    } catch (e) {
      AppLogger.e('Failed to set notifications', error: e);
      _setError(e);
    } finally {
      // _stopLoading();
    }
  }

  void _setLoading() {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
  }
  void _stopLoading() {
    _isLoading = false;
    notifyListeners();
  }
  void _setError(Object e) {
    _errorMessage = e.toString().replaceAll('Exception: ', '');
  }
  void _clearError() {
    _errorMessage = null;
  }
  bool _isConnectivityError(Object error) {
    final message = error.toString();
    return message.contains('No internet connection') ||
        message.contains('Connection timed out');
  }
}
