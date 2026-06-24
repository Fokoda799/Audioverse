import 'dart:async';
import 'dart:ui';

import 'package:Audioverse/core/audio/audio_player_service.dart';
import 'package:Audioverse/core/theme/theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:just_audio/just_audio.dart';

class FullPlayerScreen extends StatefulWidget {
  const FullPlayerScreen({super.key});

  @override
  State<FullPlayerScreen> createState() => _FullPlayerScreenState();
}

class _FullPlayerScreenState extends State<FullPlayerScreen> {
  late final StreamSubscription<Duration> _resumeSub;

  @override
  void initState() {
    super.initState();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarContrastEnforced: false,
      ),
    );

    // AudioPlayerService has no BuildContext of its own — it just
    // announces "resumed at X" on this stream, and whichever screen is
    // open reacts with a SnackBar.
    _resumeSub = AudioPlayerService.instance.resumePositionStream.listen((position) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Resumed from ${_formatDuration(position)}')),
      );
    });
  }

  @override
  void dispose() {
    _resumeSub.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final player = AudioPlayerService.instance;
    final content = player.currentContent!;
    final artSize = (MediaQuery.sizeOf(context).width * 0.78).clamp(220.0, 340.0);

    return ValueListenableBuilder(
      valueListenable: player.themeVersion,
      builder: (_, __, ___) {
        return CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.arrowLeft): player.seekBackward,
            const SingleActivator(LogicalKeyboardKey.arrowRight): player.seekForward,
            const SingleActivator(LogicalKeyboardKey.space): () {
              player.isPlaying ? player.pause() : player.resume();
            },
          },
          child: Focus(
            autofocus: true,
            child: Scaffold(
              backgroundColor: Colors.transparent,
              extendBody: true,
              extendBodyBehindAppBar: true,
              body: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(imageUrl: content.coverUrl, fit: BoxFit.cover),
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                    child: Container(color: Colors.black.withValues(alpha: .5)),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [player.primaryColor, player.secondaryColor, AppColors.darkBackground],
                      ),
                    ),
                  ),
                  SafeArea(
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 32),
                                onPressed: () => Navigator.pop(context),
                              ),
                              const Spacer(),
                              const _SleepTimerButton(),
                              const SizedBox(width: 8),
                              const _SpeedButton(),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Container(
                          width: artSize,
                          height: artSize,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 30, offset: const Offset(0, 12)),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: CachedNetworkImage(imageUrl: content.coverUrl, fit: BoxFit.cover),
                          ),
                        ),
                        const SizedBox(height: 40),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            content.title,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.displayMedium(Colors.white),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(content.author?.name ?? '', style: AppTextStyles.bodyLarge(Colors.white70)),
                        const SizedBox(height: 40),
                        const _ProgressSection(),
                        const SizedBox(height: 32),
                        const _ControlsRow(),
                        const Spacer(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

String _formatDuration(Duration d) {
  String two(int n) => n.toString().padLeft(2, '0');
  final hours = d.inHours;
  if (hours > 0) {
    return '$hours:${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}';
  }
  return '${two(d.inMinutes)}:${two(d.inSeconds.remainder(60))}';
}

String _formatSpeedLabel(double speed) {
  if (speed == speed.roundToDouble()) return '${speed.toInt()}x';
  return '${speed}x';
}

class _ProgressSection extends StatefulWidget {
  const _ProgressSection();

  @override
  State<_ProgressSection> createState() => _ProgressSectionState();
}

class _ProgressSectionState extends State<_ProgressSection> {
  // Non-null only while a finger is on the thumb — shows the drag target
  // immediately instead of fighting the live position stream, and the
  // actual seek only fires once on release.
  double? _dragSeconds;

  @override
  Widget build(BuildContext context) {
    final player = AudioPlayerService.instance;

    return StreamBuilder<Duration>(
      stream: player.positionStream,
      initialData: player.position,
      builder: (_, positionSnapshot) {
        final position = positionSnapshot.data ?? Duration.zero;

        return StreamBuilder<Duration?>(
          stream: player.durationStream,
          initialData: player.duration,
          builder: (_, durationSnapshot) {
            final duration = durationSnapshot.data ?? Duration.zero;
            final maxSeconds = duration.inSeconds == 0 ? 1.0 : duration.inSeconds.toDouble();
            final positionSeconds = position.inSeconds.clamp(0, maxSeconds.toInt()).toDouble();
            final sliderValue = (_dragSeconds ?? positionSeconds).clamp(0.0, maxSeconds);

            return StreamBuilder<Duration>(
              stream: player.bufferedPositionStream,
              initialData: Duration.zero,
              builder: (_, bufferedSnapshot) {
                final buffered = bufferedSnapshot.data ?? Duration.zero;
                final bufferedSeconds = buffered.inSeconds.clamp(0, maxSeconds.toInt()).toDouble();

                return Column(
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: Colors.white,
                        inactiveTrackColor: Colors.white24,
                        secondaryActiveTrackColor: Colors.white.withValues(alpha: .35),
                        thumbColor: player.secondaryColor,
                        overlayColor: player.secondaryColor.withValues(alpha: .2),
                      ),
                      child: Slider(
                        value: sliderValue,
                        max: maxSeconds,
                        secondaryTrackValue: bufferedSeconds, // buffered range, lighter color
                        onChanged: (value) => setState(() => _dragSeconds = value),
                        onChangeEnd: (value) {
                          player.seek(Duration(seconds: value.toInt()));
                          setState(() => _dragSeconds = null);
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_formatDuration(Duration(seconds: sliderValue.toInt())), style: const TextStyle(color: Colors.white70)),
                          Text(_formatDuration(duration), style: const TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

class _ControlsRow extends StatelessWidget {
  const _ControlsRow();

  @override
  Widget build(BuildContext context) {
    final player = AudioPlayerService.instance;

    return StreamBuilder<PlayerState>(
      stream: player.playerStateStream,
      initialData: player.player.playerState,
      builder: (_, snapshot) {
        final state = snapshot.data;
        final playing = state?.playing ?? false;
        final buffering = state?.processingState == ProcessingState.loading ||
            state?.processingState == ProcessingState.buffering;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(iconSize: 36, icon: const _SkipIcon(forward: false), onPressed: player.seekBackward),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [player.primaryColor, player.secondaryColor]),
                boxShadow: [BoxShadow(color: player.secondaryColor.withValues(alpha: .5), blurRadius: 20)],
              ),
              child: Center(
                child: buffering
                    ? const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                )
                    : IconButton(
                  iconSize: 40,
                  icon: Icon(playing ? Icons.pause : Icons.play_arrow, color: Colors.white),
                  onPressed: () => playing ? player.pause() : player.resume(),
                ),
              ),
            ),
            IconButton(iconSize: 36, icon: const _SkipIcon(forward: true), onPressed: player.seekForward),
          ],
        );
      },
    );
  }
}

class _SkipIcon extends StatelessWidget {
  const _SkipIcon({required this.forward});
  final bool forward;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(forward ? FontAwesomeIcons.rotateRight: FontAwesomeIcons.rotateLeft, size: 36, color: Colors.white),
          Padding(
            padding: EdgeInsets.only(top: forward ? 2 : 1),
            child: const Text('15', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _SpeedButton extends StatelessWidget {
  const _SpeedButton();

  @override
  Widget build(BuildContext context) {
    final player = AudioPlayerService.instance;

    return StreamBuilder<double>(
      stream: player.speedStream,
      initialData: player.speed,
      builder: (context, snapshot) {
        final speed = snapshot.data ?? 1.0;
        return InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showSpeedSheet(context, player),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
            child: Text(_formatSpeedLabel(speed), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        );
      },
    );
  }
}

class _SleepTimerButton extends StatelessWidget {
  const _SleepTimerButton();

  @override
  Widget build(BuildContext context) {
    final player = AudioPlayerService.instance;

    return StreamBuilder<Duration?>(
      stream: player.sleepTimerRemainingStream,
      initialData: player.sleepTimerRemaining,
      builder: (context, snapshot) {
        final remaining = snapshot.data;
        return InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showSleepTimerSheet(context, player),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                Icon(remaining != null ? Icons.bedtime : Icons.bedtime_outlined, color: Colors.white, size: 22),
                if (remaining != null) ...[
                  const SizedBox(width: 4),
                  Text(_formatDuration(remaining), style: const TextStyle(color: Colors.white, fontSize: 12)),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

void _showSpeedSheet(BuildContext context, AudioPlayerService player) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.darkCard,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (sheetContext) {
      return StreamBuilder<double>(
        stream: player.speedStream,
        initialData: player.speed,
        builder: (_, snapshot) {
          final current = snapshot.data ?? 1.0;
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Playback speed', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                for (final speed in const [0.5, 0.75, 1.0, 1.25, 1.5, 2.0])
                  ListTile(
                    title: Text(_formatSpeedLabel(speed), style: const TextStyle(color: Colors.white)),
                    trailing: (speed - current).abs() < 0.01 ? const Icon(Icons.check, color: Colors.white) : null,
                    onTap: () {
                      player.setSpeed(speed);
                      Navigator.pop(sheetContext);
                    },
                  ),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      );
    },
  );
}

void _showSleepTimerSheet(BuildContext context, AudioPlayerService player) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.darkCard,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (sheetContext) {
      return StreamBuilder<Duration?>(
        stream: player.sleepTimerRemainingStream,
        initialData: player.sleepTimerRemaining,
        builder: (_, snapshot) {
          final remaining = snapshot.data;
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Sleep timer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                for (final minutes in const [5, 10, 15, 30, 45, 60])
                  ListTile(
                    title: Text('$minutes min', style: const TextStyle(color: Colors.white)),
                    onTap: () {
                      player.startSleepTimer(Duration(minutes: minutes));
                      Navigator.pop(sheetContext);
                    },
                  ),
                if (remaining != null)
                  ListTile(
                    title: const Text('Turn off', style: TextStyle(color: Colors.redAccent)),
                    onTap: () {
                      player.cancelSleepTimer();
                      Navigator.pop(sheetContext);
                    },
                  ),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      );
    },
  );
}
