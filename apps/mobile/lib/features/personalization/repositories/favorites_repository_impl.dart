import 'package:dio/dio.dart';
import 'package:Audioverse/core/utils/app_logger.dart';
import 'package:Audioverse/features/content/models/models.dart';
import 'package:Audioverse/features/personalization/favorites_repository.dart';

// FavoritesRepositoryImpl
//
// Real HTTP implementation, following the exact same shape as
// ContentRepositoryImpl: try/catch DioException, _handleError() at the
// bottom, no caching (favorites change frequently via user action, so
// caching them like categories would risk showing stale heart states).

class FavoritesRepositoryImpl implements FavoritesRepository {
  final Dio _dio;

  FavoritesRepositoryImpl({required Dio dio}) : _dio = dio;

  // ── GET /favorites ────────────────────────────────────────────────────────
  @override
  Future<PaginatedFavorites> getFavorites({required int page}) async {
    try {
      final response = await _dio.get(
        '/favorites',
        queryParameters: {'page': page, 'limit': 10},
      );

      final data = response.data as Map<String, dynamic>;

      return PaginatedFavorites(
        // Backend's GET /favorites returns items shaped as
        // { ...favoriteFields, content: {...} } — we only need the
        // nested `content` object here, not the favorite wrapper row
        // itself (id, createdAt of the favorite aren't useful to the UI).
        items: (data['items'] as List)
            .map((item) => Content.fromJson(
            (item as Map<String, dynamic>)['content'] as Map<String, dynamic>))
            .toList(),
        meta: PaginationMeta.fromJson(data['meta'] as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── POST /favorites/:contentId ────────────────────────────────────────────
  @override
  Future<void> addFavorite(String contentId) async {
    try {
      await _dio.post('/favorites/$contentId');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── DELETE /favorites/:contentId ──────────────────────────────────────────
  @override
  Future<void> removeFavorite(String contentId) async {
    try {
      await _dio.delete('/favorites/$contentId');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Identical pattern to ContentRepositoryImpl._handleError —
  // kept consistent rather than introducing a shared base class for
  // what's currently just two small repositories.
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
        AppLogger.e('Unhandled DioException in FavoritesRepository: $e');
        return Exception('Something went wrong. Please try again.');
    }
  }
}
