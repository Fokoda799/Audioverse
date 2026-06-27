import 'package:Audioverse/features/personalization/models/history_model.dart';

abstract class HistoryRepository {
  /// Paginated, full listening history — sorted by lastPlayedAt DESC,
  /// matches GET /history. This is "everything you've ever played",
  /// not just unfinished items.
  Future<PaginatedHistory> getHistory({required int page});

  /// Up to 10 unfinished items, sorted by lastPlayedAt DESC — matches
  /// GET /history/continue-listening. No pagination param: the backend
  /// caps this at 10 by design, it's a small home-screen widget, not a
  /// browsable list.
  Future<List<History>> getContinueListening();

  /// Upsert — call this periodically while audio is playing (e.g. every
  /// 10-15s) to checkpoint progress. Matches PATCH /history/:contentId.
  /// completed is optional: omit it for routine progress checkpoints so
  /// a previously-completed item never gets accidentally reset to false
  /// (see HistoryService.upsert on the backend for why this matters).
  Future<void> updatePosition({
    required String contentId,
    required int positionSec,
    required double progressPercent,
    bool? completed,
  });

  Future<int> getPositionSec({
    required String contentId
  });

  /// Removes one item from history entirely — matches DELETE /history/:contentId.
  /// Safe to call even if no history row exists for this content.
  Future<void> deleteHistory(String contentId);
}
