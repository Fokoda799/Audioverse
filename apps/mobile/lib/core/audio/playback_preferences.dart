import 'package:shared_preferences/shared_preferences.dart';

// PlaybackPreferences
//
// Tiny wrapper around shared_preferences for the handful of playback
// settings that should survive app restarts (currently just speed).
// Kept separate from AudioPlayerService so the service itself doesn't
// need to know about raw shared_preferences key strings.
class PlaybackPreferences {
  static const _speedKey = 'playback_speed';

  static Future<double> getSpeed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_speedKey) ?? 1.0;
  }

  static Future<void> setSpeed(double speed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_speedKey, speed);
  }
}
