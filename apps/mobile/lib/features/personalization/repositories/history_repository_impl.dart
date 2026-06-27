import 'package:Audioverse/features/personalization/models/history_model.dart';
import 'package:Audioverse/features/personalization/repositories/history_repository.dart';
import 'package:dio/dio.dart';
import 'package:Audioverse/core/utils/app_logger.dart';
import 'package:Audioverse/features/content/models/models.dart';

// HistoryRepositoryImpl
//
// Real HTTP implementation. No caching — history changes constantly
// during playback (updatePosition is called every few seconds), so a
// cache layer here would be actively counterproductive, unlike
// categories which barely change.
//
// history_repository_impl.dart

class HistoryRepositoryImpl implements HistoryRepository {
  final Dio _dio;

  HistoryRepositoryImpl({required Dio dio}) : _dio = dio;

  // ── GET /history ────────────────────────────────────────────────────────
  @override
  Future<PaginatedHistory> getHistory({required int page}) async {
    try {
      final response = await _dio.get(
        '/history',
        queryParameters: {'page': page, 'limit': 10},
      );

      final data = response.data as Map<String, dynamic>;

      return PaginatedHistory(
        items: (data['items'] as List)
            .map((item) => History.fromJson(item as Map<String, dynamic>))
            .toList(),
        meta: PaginationMeta.fromJson(data['meta'] as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── GET /history/continue-listening ───────────────────────────────────────
  //
  // Returns a raw List, not a paginated wrapper — matches the backend's
  // HistoryService.getContinueListening(), which deliberately has no
  // pagination (fixed cap of 10 items server-side).
  @override
  Future<List<History>> getContinueListening() async {
    try {
      final response = await _dio.get('/history/continue-listening');

      return (response.data as List)
          .map((item) => History.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── PATCH /history/:contentId ─────────────────────────────────────────────
  @override
  Future<void> updatePosition({
    required String contentId,
    required int positionSec,
    required double progressPercent,
    bool? completed,
  }) async {
    try {
      final data = <String, dynamic>{
        'positionSec': positionSec,
        'progressPercent': progressPercent,
      };

      if (completed != null) {
        data['completed'] = completed;
      }

      await _dio.patch('/history/$contentId', data: data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<int> getPositionSec({required String contentId}) async {
    try {
      final response = await _dio.get('/history/$contentId');
      AppLogger.d(response.data);
      final data = response.data;
      return data is num ? data.toInt() : 0;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── DELETE /history/:contentId ────────────────────────────────────────────
  @override
  Future<void> deleteHistory(String contentId) async {
    try {
      await _dio.delete('/history/$contentId');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(DioException e) {
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout) {
      return Exception('No internet connection. Please try again.');
    }

    final statusCode = e.response?.statusCode;
    final serverMessage = e.response?.data is Map
        ? (e.response?.data as Map)['message']
        : null;

    switch (statusCode) {
      case 401:
        return Exception('Session expired. Please log in again.');
      case 404:
        return Exception(serverMessage ?? 'Content not found');
      default:
        AppLogger.e('Unhandled DioException in HistoryRepository: $e');
        return Exception('Something went wrong. Please try again.');
    }
  }
}
