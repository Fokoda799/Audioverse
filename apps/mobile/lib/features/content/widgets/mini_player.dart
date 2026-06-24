import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:Audioverse/core/audio/audio_player_service.dart';

// MiniPlayer
//
// Persistent playback bar shown across every screen once something is
// loaded into AudioPlayerService. Tinted with a two-color gradient
// extracted from the current cover art (see _extractPalette in
// audio_player_service.dart) — that's what themeVersion/primaryColor/
// secondaryColor below are for.
//
// STATE SOURCE: reads AudioPlayerService.instance directly, not through
// Provider/context.read() — consistent with the rest of the player
// architecture, since it's a process-wide singleton, not scoped state.
//
// VISIBILITY: shows/hides itself based on whether anything is loaded —
// the parent shell always includes <MiniPlayer/> and lets it decide.
//
// PLACEMENT: sits directly above the bottom nav bar — see
// MAIN_SCAFFOLD_CHANGES.md for exactly where it's inserted.
//
// mini_player.dart

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final service = AudioPlayerService.instance;

    // Rebuilds when a new palette finishes extracting for the current
    // track — themeVersion is bumped once per successful extraction,
    // see _extractPalette().
    return ValueListenableBuilder<int>(
      valueListenable: service.themeVersion,
      builder: (_, __, ___) {
        return StreamBuilder<SequenceState?>(
          stream: service.player.sequenceStateStream,
          builder: (context, sequenceSnapshot) {
            final current = service.currentMiniContent;

            // Nothing loaded (fresh launch, or stop() was called) —
            // collapse to nothing rather than an empty bar.
            final hasContent =
                current != null && sequenceSnapshot.data?.currentSource != null;

            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: !hasContent
                  ? const SizedBox.shrink()
                  : _MiniPlayerBar(
                key: const ValueKey('mini-player'),
                content: current,
                primaryColor: service.primaryColor,
                secondaryColor: service.secondaryColor,
              ),
            );
          },
        );
      },
    );
  }
}

class _MiniPlayerBar extends StatelessWidget {
  const _MiniPlayerBar({
    super.key,
    required this.content,
    required this.primaryColor,
    required this.secondaryColor,
  });

  final MiniPlayerContent content;
  final Color primaryColor;
  final Color secondaryColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      elevation: 10,
      child: InkWell(
        onTap: () => context.push('/player'),
        child: Container(
          height: 72,
          // margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            // borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primaryColor, secondaryColor],
            ),
          ),
          child: Row(
            children: [
              _Thumbnail(coverUrl: content.coverUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      content.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      content.authorName ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const _PlayPauseButton(),
              // No queue concept yet (per earlier decision) — visibly
              // disabled rather than hidden, so the control surface stays
              // predictable: "next" exists as a concept but isn't wired,
              // rather than silently missing.
              IconButton(
                onPressed: null,
                icon: Icon(
                  Icons.skip_next_rounded,
                  color: Colors.white.withValues(alpha: 0.35),
                  size: 30,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Play/Pause button ───────────────────────────────────────────────────
//
// Three states, not just isPlaying — buffering/loading disables the
// button entirely (prevents a tap mid-buffer firing pause() on a player
// that hasn't actually started yet), then playing/paused swap icon and
// tap behavior. Always reads the LIVE stream value rather than a locally
// tracked bool, so this stays correct even when playback state changes
// from elsewhere (lock-screen controls, ContentDetailScreen's own Play
// button — both drive this same AudioPlayerService singleton).
class _PlayPauseButton extends StatelessWidget {
  const _PlayPauseButton();

  @override
  Widget build(BuildContext context) {
    final service = AudioPlayerService.instance;

    return StreamBuilder<PlayerState>(
      stream: service.playerStateStream,
      builder: (context, snapshot) {
        final playerState = snapshot.data;
        final processingState = playerState?.processingState;
        final isPlaying = playerState?.playing ?? false;

        final isBuffering = processingState == ProcessingState.loading ||
            processingState == ProcessingState.buffering;

        if (isBuffering) {
          return const Padding(
            padding: EdgeInsets.all(8),
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: Colors.white,
              ),
            ),
          );
        }

        return IconButton(
          onPressed: () {
            if (isPlaying) {
              service.pause();
            } else {
              service.resume();
            }
          },
          icon: Icon(
            isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            color: Colors.white,
            size: 30,
          ),
        );
      },
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.coverUrl});

  final String? coverUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: coverUrl != null
          ? CachedNetworkImage(
        imageUrl: coverUrl!,
        width: 50,
        height: 50,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          width: 50,
          height: 50,
          color: Colors.white.withValues(alpha: 0.15),
        ),
        errorWidget: (context, url, error) => Container(
          width: 50,
          height: 50,
          color: Colors.white.withValues(alpha: 0.15),
          child: const Icon(Icons.music_note_rounded,
              color: Colors.white, size: 20),
        ),
      )
          : Container(
        width: 50,
        height: 50,
        color: Colors.white.withValues(alpha: 0.15),
        child: const Icon(Icons.music_note_rounded,
            color: Colors.white, size: 20),
      ),
    );
  }
}
