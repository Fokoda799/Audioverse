import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:Audioverse/features/content/content_repository.dart';
import 'package:Audioverse/features/content/models/content_models.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class DownloadManager {

  final ContentRepository _contentRepository;
  final Dio _dio;
  final Map<String, CancelToken> _cancelTokens = {};

  DownloadManager({required ContentRepository contentRepository, required Dio dio})
      : _dio = dio,
        _contentRepository = contentRepository;

  Future<String> localPathFor(String contentId) async {
    
    final dir = await getApplicationDocumentsDirectory();
    final downloadsDir = Directory('${dir.path}/general');
    if (!await downloadsDir.exists()) {
      await downloadsDir.create(recursive: true);
    }
    return '${downloadsDir.path}/$contentId.mp3';
  }

  /// Starts (or resumes) a download. Reports progress via [onProgress].
  Future<void> download({
    required Content content,
    required void Function(int received, int total) onProgress,
    required void Function() onComplete,
    required void Function(String error) onError,
  }) async {
    
    final cancelToken = CancelToken();
    _cancelTokens[content.id] = cancelToken;

    try {
      final audioUrl = await _contentRepository.getStreamUrl(id: content.id); // your existing method
      final localPath = await localPathFor(content.id);

      await _dio.download(
        audioUrl,
        localPath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (total > 0) onProgress(received, total);
        },
      );

      onComplete();
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        return; // cancelled deliberately, not a failure
      }
      onError(e.message ?? 'Download failed');
    } catch (e) {
      onError(e.toString());
    } finally {
      _cancelTokens.remove(content.id);
    }
  }

  void cancel(String contentId) {
    _cancelTokens[contentId]?.cancel();
  }

  Future<void> deleteLocalFile(String localPath) async {
    if (kIsWeb) return;
    final file = File(localPath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
