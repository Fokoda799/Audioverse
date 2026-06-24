// HistoryRepository
//
// Stub interface only — mirrors the FavoriteRepository pattern already
// used in ContentDetailScreen, for the same reason: the real backend
// route isn't wired up yet, but AudioPlayerService needs somewhere to
// call through to so resume-from-last-position and periodic position
// sync can be built now and connected to a real implementation later
// without touching the player itself.
//
// Wire up a real implementation against your NestJS /history endpoints
// and attach it once at app startup:
//
//   AudioPlayerService.instance.attachHistoryRepository(MyHistoryRepository(...));
//
// Until that's done, every history-related feature below silently
// no-ops — playback still works fine without it.
abstract class HistoryRepository {
  /// GET /history/:contentId — last saved playback position in seconds,
  /// or null if there's no history for this content yet.
  Future<int?> getPositionSec(String contentId);

  /// PATCH /history/:contentId — called every 10s while playing and once
  /// on pause/stop. Treat failures as non-fatal (log, don't throw); a
  /// missed sync tick shouldn't interrupt playback.
  Future<void> syncPosition(String contentId, int positionSec);
}
