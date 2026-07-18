import 'package:hive_ce/hive.dart';

part 'download_model.g.dart';

@HiveType(typeId: 5) // pick an unused typeId
enum DownloadStatus {
  @HiveField(0)
  queued,
  @HiveField(1)
  downloading,
  @HiveField(2)
  paused,
  @HiveField(3)
  completed,
  @HiveField(4)
  failed,
}

@HiveType(typeId: 6)
class DownloadItem extends HiveObject {
  DownloadItem({
    required this.contentId,
    required this.title,
    required this.coverUrl,
    required this.localPath,
    required this.status,
    this.totalBytes = 0,
    this.downloadedBytes = 0,
    this.errorMessage,
  });

  @HiveField(0)
  final String contentId;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String coverUrl;

  @HiveField(3)
  final String localPath;

  @HiveField(4)
  DownloadStatus status;

  @HiveField(5)
  int totalBytes;

  @HiveField(6)
  int downloadedBytes;

  @HiveField(7)
  String? errorMessage;

  double get progress => totalBytes == 0 ? 0 : downloadedBytes / totalBytes;
}