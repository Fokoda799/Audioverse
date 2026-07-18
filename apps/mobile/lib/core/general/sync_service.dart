import 'package:Audioverse/core/utils/app_logger.dart';
import 'package:Audioverse/features/personalization/repositories/history_repository.dart';
import 'package:hive_ce/hive.dart';



class SyncService {
  SyncService({
    required HistoryRepository historyRepository,
  })  : _historyRepository = historyRepository;

  final HistoryRepository _historyRepository;
  final Box _box = Hive.box<int>('local_playback_positions');


  /// Called once, right after a successful login/signup. Merges any
  /// locally-stored guest playback positions up to the server.
  /// Best-effort: failures are logged, never thrown, since this should
  /// never block the login flow or surface as a user-facing error.
  Future<void> syncGuestDataToServer() async {
    final localPositions = _box.toMap();
    if (localPositions.isEmpty) return;

    AppLogger.i('Syncing ${localPositions.length} local playback positions to server');

    for (final entry in localPositions.entries) {
      final contentId = entry.key;
      final localPositionSec = entry.value;

      try {
        final serverPositionSec = await _historyRepository.getPositionSec(
          contentId: contentId,
        );

        // Furthest progress wins — never let login regress playback position.
        final resolvedPositionSec = localPositionSec > serverPositionSec
            ? localPositionSec
            : serverPositionSec;

        if (resolvedPositionSec == localPositionSec && localPositionSec > 0) {
          await _historyRepository.updatePosition(
            contentId: contentId,
            positionSec: resolvedPositionSec,
            progressPercent: 0,
          );
        }

        // Local copy is now redundant for this contentId — server is the
        // source of truth again for a logged-in user.
        await _box.delete(contentId);
      } catch (e) {
        AppLogger.w('Sync failed for $contentId, will retry next login: $e');
        // Deliberately not rethrown, and deliberately NOT cleared from
        // local store on failure — leaving it there means it'll be
        // retried on the next sync attempt instead of being silently lost.
      }
    }
  }
}
