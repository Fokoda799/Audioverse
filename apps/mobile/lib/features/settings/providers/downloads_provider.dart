import 'package:Audioverse/core/utils/app_logger.dart';
import 'package:flutter/foundation.dart';
import 'package:Audioverse/core/general/downloads_manager.dart';
import 'package:Audioverse/features/content/models/content_models.dart';
import 'package:Audioverse/features/settings/models/download_model.dart';
import 'package:hive_ce/hive.dart';

class DownloadProvider extends ChangeNotifier {
  DownloadProvider({required this.downloadManager}) {
    _box = Hive.box<DownloadItem>('downloads');
  }

  final DownloadManager downloadManager;
  Box<DownloadItem>? _box;

  List<DownloadItem> get downloads => (kIsWeb || _box == null) ? [] : _box!.values.toList()
    ..sort((a, b) => b.key.compareTo(a.key)); // newest first, adjust as needed

  Future<void> startDownload(Content content) async {
    if (_box == null) return;
    
    final localPath = await downloadManager.localPathFor(content.id);

    AppLogger.d('path: $localPath');

    final item = DownloadItem(
      contentId: content.id,
      title: content.title,
      coverUrl: content.coverUrl,
      localPath: localPath,
      status: DownloadStatus.downloading,
    );
    await _box!.put(content.id, item);
    notifyListeners();

    await downloadManager.download(
      content: content,
      onProgress: (received, total) {
        item
          ..downloadedBytes = received
          ..totalBytes = total;
        item.save();
        notifyListeners();
      },
      onComplete: () {
        item.status = DownloadStatus.completed;
        item.save();
        notifyListeners();
      },
      onError: (error) {
        item
          ..status = DownloadStatus.failed
          ..errorMessage = error;
        item.save();
        notifyListeners();
      },
    );
  }

  void cancelDownload(String contentId) {
    if (kIsWeb || _box == null) return;
    downloadManager.cancel(contentId);
    _box!.delete(contentId);
    notifyListeners();
  }

  Future<void> removeDownload(String contentId) async {
    if (kIsWeb || _box == null) return;
    final item = _box!.get(contentId);
    if (item != null) {
      await downloadManager.deleteLocalFile(item.localPath);
      await _box!.delete(contentId);
      notifyListeners();
    }
  }

  bool isDownloaded(String contentId) =>
      _box != null && _box!.get(contentId)?.status == DownloadStatus.completed;

  DownloadItem? statusFor(String contentId) => _box?.get(contentId);
}
