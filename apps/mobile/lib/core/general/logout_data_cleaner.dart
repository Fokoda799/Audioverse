import 'package:Audioverse/core/general/downloads_manager.dart';
import 'package:Audioverse/features/settings/models/download_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:hive_ce/hive.dart';

class LogoutDataCleaner extends ChangeNotifier {
  LogoutDataCleaner({
    required DownloadManager downloadManager,
  }) : _downloadManager = downloadManager;

  final DownloadManager _downloadManager;

  Future<void> clearUserData() async {
    // ── Recent searches ──────────────────────────────────────────────
    final recentSearchesBox = Hive.box('recent_searches');
    await recentSearchesBox.clear();

    // ── Local playback positions ────────────────────────────────────
    final positionsBox = Hive.box<int>('local_playback_positions');
    await positionsBox.clear();
    final downloadsBox = Hive.box<DownloadItem>('downloads');
    for (final item in downloadsBox.values) {
      await _downloadManager.deleteLocalFile(item.localPath);
    }
    await downloadsBox.clear();

    // ── Explicitly NOT cleared: categories_cache, content_cache ─────
    // These aren't user-specific — no reason to force a refetch for
    // the next person/session.
  }
}
