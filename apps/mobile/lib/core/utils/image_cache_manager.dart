import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class AppImageCacheManager {
  static const key = 'audioverse_image_cache';

  static CacheManager instance = CacheManager(
    Config(
      key,
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 200,
      repo: JsonCacheInfoRepository(databaseName: key),
      fileService: HttpFileService(),
    ),
  );
}
