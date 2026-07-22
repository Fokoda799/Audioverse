import 'dart:async';
// import 'dart:ui';
import 'package:Audioverse/core/audio/playback_preferences.dart';
import 'package:Audioverse/core/theme/app_colors.dart';
import 'package:Audioverse/features/content/models/content_models.dart';
import 'package:Audioverse/features/personalization/repositories/history_repository.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:Audioverse/core/utils/app_logger.dart';
import 'package:palette_generator/palette_generator.dart';

class AudioPlayerService {
  AudioPlayerService._internal();

  static final AudioPlayerService instance = AudioPlayerService._internal();

  late final AudioPlayer _player;
  final ValueNotifier<int> themeVersion = ValueNotifier(0);
  bool _isInitialized = false;
  Content? _currentContent;
  Color _primaryColor = AppColors.darkBackground;
  Color _secondaryColor = AppColors.darkBackground;

  // ── Pluggable history sync ──────────────────────────────────────────────
  // Optional by design — until a real implementation is attached, every
  // history-related call below silently no-ops instead of throwing, so
  // playback works fine even before that backend route exists.
  HistoryRepository? _historyRepository;
  void attachHistoryRepository(HistoryRepository repository) {
    _historyRepository = repository;
  }

  Timer? _historySyncTimer;
  static const _historySyncInterval = Duration(seconds: 10);

  // Fires once per playContent() call IF a saved position was found and
  // seeked to, so the UI can show a "Resumed from X:XX" toast without
  // this service needing a BuildContext of its own.
  final _resumeController = StreamController<Duration>.broadcast();
  Stream<Duration> get resumePositionStream => _resumeController.stream;

  // ── Sleep timer ───────────────────────────────────────────────────────────
  Timer? _sleepTimerTicker;
  Duration? _sleepTimerRemaining;
  static const _sleepFadeWindow = Duration(seconds: 30);
  final _sleepTimerController = StreamController<Duration?>.broadcast();
  Stream<Duration?> get sleepTimerRemainingStream => _sleepTimerController.stream;
  Duration? get sleepTimerRemaining => _sleepTimerRemaining;

  // ── Interruption handling ────────────────────────────────────────────────
  bool _resumeAfterInterruption = false;

  AudioPlayer get player => _player;
  Content? get currentContent => _currentContent;
  Color get primaryColor => _primaryColor;
  Color get secondaryColor => _secondaryColor;

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<Duration> get bufferedPositionStream => _player.bufferedPositionStream;
  Stream<int?> get currentIndexStream => _player.currentIndexStream;
  Stream<double> get speedStream => _player.speedStream;

  bool get isPlaying => _player.playing;
  Duration get position => _player.position;
  Duration? get duration => _player.duration;
  double get speed => _player.speed;

  Future<void> init() async {
    if (_isInitialized) {
      AppLogger.d('AudioPlayerService already initialized — skipping');
      return;
    }

    if (!kIsWeb) {
      await JustAudioBackground.init(
        androidNotificationChannelId: 'com.example.mobile.audio',
        androidNotificationChannelName: 'AudioVerse Playback',
        androidNotificationOngoing: false,
        androidStopForegroundOnPause: false,
      );
    }

    _player = AudioPlayer();

    if (!kIsWeb) {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());

      // ── Audio focus / interruptions ────────────────────────────────────────
      // Phone calls and other apps' audio fire interruption events; losing
      // a headphone connection fires "becoming noisy". just_audio_background
      // already gives us lock-screen controls — this is the other half:
      // reacting correctly when something else wants the speaker.
      session.interruptionEventStream.listen((event) {
        if (event.begin) {
          switch (event.type) {
            case AudioInterruptionType.duck:
              _player.setVolume(0.3);
              break;
            case AudioInterruptionType.pause:
            case AudioInterruptionType.unknown:
              _resumeAfterInterruption = _player.playing;
              _player.pause();
              break;
          }
        } else {
          switch (event.type) {
            case AudioInterruptionType.duck:
              _player.setVolume(1.0);
              break;
            case AudioInterruptionType.pause:
              if (_resumeAfterInterruption) {
                _resumeAfterInterruption = false;
                _player.play();
              }
              break;
            case AudioInterruptionType.unknown:
              break;
          }
        }
      });

      // Headphones unplugged / Bluetooth disconnected — pause rather than
      // suddenly blasting through the phone speaker.
      session.becomingNoisyEventStream.listen((_) => _player.pause());
    }

    _player.playbackEventStream.listen(
          (_) {},
      onError: (Object e, StackTrace st) {
        AppLogger.e('Playback stream error', error: e, stackTrace: st);
      },
    );

    // Restore the last speed the user picked, before anything plays.
    final savedSpeed = await PlaybackPreferences.getSpeed();
    await _player.setSpeed(savedSpeed);

    _isInitialized = true;
    AppLogger.d('AudioPlayerService initialized');
  }

  Future<void> playContent({
    required Content content,
    required String streamUrl,
  }) async {
    if (!_isInitialized) {
      throw StateError(
        'AudioPlayerService.init() must be called before playContent()',
      );
    }

    _currentContent = content;
    _historySyncTimer?.cancel();

    try {
      if (!kIsWeb) {
        final palette = await PaletteGenerator.fromImageProvider(
          NetworkImage(content.coverUrl),
        ).timeout(const Duration(seconds: 2));
        _primaryColor = palette.dominantColor?.color ?? AppColors.darkBackground;
        _secondaryColor = palette.vibrantColor?.color ??
            palette.darkMutedColor?.color ??
            AppColors.darkBackground;
      }
    } catch (e) {
      AppLogger.w('Failed to generate palette (likely CORS on Web): $e');
      _primaryColor = AppColors.darkBackground;
      _secondaryColor = AppColors.darkBackground;
    }

    themeVersion.value++;

    try {
      final audioSource = AudioSource.uri(
        Uri.parse(streamUrl),
        tag: MediaItem(
          id: content.id,
          title: content.title,
          artist: content.author?.name,
          artUri: Uri.parse(content.coverUrl),
        ),
      );

      await _player.setAudioSource(audioSource);

      // Guard against a leftover sleep-timer fade silently carrying over
      // into a brand new track.
      await _player.setVolume(1.0);

      try {
        final savedPositionSec = await _historyRepository?.getPositionSec(contentId: content.id);
        if (savedPositionSec != null && savedPositionSec > 0) {
          final resumePosition = Duration(seconds: savedPositionSec);
          await _player.seek(resumePosition);
          _resumeController.add(resumePosition);
        }
      } catch (e) {
        AppLogger.w('Could not fetch resume position for ${content.id}, starting from 0: $e');
      }

      _player.play();
      _syncPositionNow();
      _startHistorySync(content.id);
    } catch (e, st) {
      AppLogger.e('Failed to play content ${content.id}', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> pause() async {
    await _player.pause();
    _syncPositionNow();
  }

  Future<void> resume() => _player.play();

  Future<void> stop() async {
    await _player.stop();
    _historySyncTimer?.cancel();
    _syncPositionNow();
  }

  Future<void> seek(Duration position) => _player.seek(position);

  Future<void> setSpeed(double speed) async {
    await _player.setSpeed(speed);
    await PlaybackPreferences.setSpeed(speed);
  }

  // ── ±15s skip ─────────────────────────────────────────────────────────────
  static const skipAmount = Duration(seconds: 15);

  Future<void> seekForward() async {
    final target = position + skipAmount;
    final clampMax = duration;
    await _player.seek(clampMax != null && target > clampMax ? clampMax : target);
  }

  Future<void> seekBackward() async {
    final target = position - skipAmount;
    await _player.seek(target < Duration.zero ? Duration.zero : target);
  }

  // ── History sync ──────────────────────────────────────────────────────────
  void _startHistorySync(String contentId) {
    _historySyncTimer = Timer.periodic(_historySyncInterval, (_) {
      final totalDuration = duration;
      if (_player.playing && totalDuration != null && totalDuration.inSeconds > 0) {
        _historyRepository?.updatePosition(
            contentId: contentId,
            positionSec: _player.position.inSeconds,
            progressPercent: (_player.position.inSeconds / duration!.inSeconds) * 100
        );
      }
    });
  }

  void _syncPositionNow() {
    final content = _currentContent;
    final totalDuration = duration;
    if (content != null && totalDuration != null && totalDuration.inSeconds > 0) {
      _historyRepository?.updatePosition(
          contentId: content.id,
          positionSec: _player.position.inSeconds,
          progressPercent: (_player.position.inSeconds / duration!.inSeconds) * 100
      );
    }
  }

  // ── Sleep timer ───────────────────────────────────────────────────────────
  void startSleepTimer(Duration duration) {
    _sleepTimerTicker?.cancel();
    _sleepTimerRemaining = duration;
    _sleepTimerController.add(_sleepTimerRemaining);

    _sleepTimerTicker = Timer.periodic(const Duration(seconds: 1), (_) async {
      final remaining = _sleepTimerRemaining! - const Duration(seconds: 1);
      _sleepTimerRemaining = remaining;
      _sleepTimerController.add(remaining);

      if (remaining <= _sleepFadeWindow && remaining > Duration.zero) {
        final fadeProgress = remaining.inMilliseconds / _sleepFadeWindow.inMilliseconds;
        await _player.setVolume(fadeProgress.clamp(0.0, 1.0));
      }

      if (remaining <= Duration.zero) {
        _sleepTimerTicker?.cancel();
        _sleepTimerTicker = null;
        _sleepTimerRemaining = null;
        _sleepTimerController.add(null);
        await _player.pause();
        await _player.setVolume(1.0);
        _syncPositionNow();
      }
    });
  }

  void cancelSleepTimer() {
    _sleepTimerTicker?.cancel();
    _sleepTimerTicker = null;
    _sleepTimerRemaining = null;
    _sleepTimerController.add(null);
    _player.setVolume(1.0);
  }

  bool isCurrentContent(String contentId) {
    final currentTag = _player.sequenceState?.currentSource?.tag;
    return currentTag is MediaItem && currentTag.id == contentId;
  }

  MiniPlayerContent? get currentMiniContent {
    if (_currentContent == null) return null;

    final tag = _player.sequenceState?.currentSource?.tag;
    if (tag is! MediaItem) return null;

    return MiniPlayerContent(
      id: tag.id,
      title: tag.title,
      authorName: tag.artist,
      coverUrl: tag.artUri?.toString(),
    );
  }

  Future<void> dispose() async {
    _historySyncTimer?.cancel();
    _sleepTimerTicker?.cancel();
    await _resumeController.close();
    await _sleepTimerController.close();
    await _player.dispose();
    _isInitialized = false;
  }

  Future<void> stopAndClear() async {
    await _player.stop();
    _historySyncTimer?.cancel();
    _sleepTimerTicker?.cancel();
    await _resumeController.close();
    await _sleepTimerController.close();
    _currentContent = null;
    // Bump themeVersion to force MiniPlayer's ValueListenableBuilder to
    // rebuild — currentMiniContent is a plain getter, not itself a stream,
    // so nothing re-checks it unless something explicitly triggers a
    // rebuild. themeVersion is already the mechanism MiniPlayer listens to
    // for exactly this kind of "re-evaluate my state" signal.
    themeVersion.value++;
  }
}



class MiniPlayerContent {
  const MiniPlayerContent({
    required this.id,
    required this.title,
    this.authorName,
    this.coverUrl,
  });

  final String id;
  final String title;
  final String? authorName;
  final String? coverUrl;
}
