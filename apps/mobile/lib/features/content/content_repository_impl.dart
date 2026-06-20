import 'package:Audioverse/core/network/cach_manager.dart';
import 'package:dio/dio.dart';
import 'package:Audioverse/core/utils/app_logger.dart';
import 'package:Audioverse/features/content/models/models.dart';
import 'package:Audioverse/features/content/content_repository.dart';
import 'package:hive/hive.dart';

// Content Repository Implementation
//
// Makes real HTTP calls using Dio.
// The Dio instance is injected — it already has the AuthInterceptor
// attached, so Bearer tokens are added automatically to every request.
//
// Every method follows the same pattern:
//   1. Call the API with Dio
//   2. Parse the JSON response with fromJson()
//   3. Return the clean model — or throw a readable exception

class ContentRepositoryImpl implements ContentRepository {
  final Dio _dio;
  final CacheManager _cache;

  ContentRepositoryImpl(
      {required Dio dio,
        required CacheManager cache
      }) : _dio = dio, _cache = cache;

  // ── GET /content ────────────────────────────────────────────────────────
  // Returns a paginated list — NOT a single Content object.
  @override
  Future<PaginatedContent> getContent({
    required ContentFilters filters,
  }) async {
    try {
      final response = await _dio.get(
        '/content',
        queryParameters: filters.toQueryParams(),
      );

      final data = response.data as Map<String, dynamic>;

      return PaginatedContent(
        items: (data['items'] as List)
            .map((item) => Content.fromJson(item as Map<String, dynamic>))
            .toList(),
        meta: PaginationMeta.fromJson(data['meta'] as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── GET /content/:id ────────────────────────────────────────────────────
  @override
  Future<Content> getContentById({required String id}) async {
    try {
      final box = Hive.box('content_cache');
      final cached = await _cache.get<Content>(box, id,
              (json) => Content.fromJson(
        Map<String, dynamic>.from(json),
      ));

      if (cached != null) {
        return cached;
      }

      final response = await _dio.get('/content/$id');

      await _cache.save(box, id, response.data);

      return Content.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── GET /content/search ─────────────────────────────────────────────────
  // Returns a raw list of lightweight content — not paginated, not wrapped.
  @override
  Future<List<Content>> searchContent({required String query}) async {
    try {
      final response = await _dio.get(
        '/content/search',
        queryParameters: {'q': query},
      );

      return (response.data as List)
          .map((item) => Content.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<List<Content>> getFeatured() async {
    try {
      final response = await _dio.get(
        '/content/featured'
      );

      final data = response.data as List<dynamic>;

      return data.map((e) => Content.fromJson(e as Map<String, dynamic>)).toList();

    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── GET /categories ─────────────────────────────────────────────────────
  @override
  Future<List<Category>> getCategories() async {
    try {
      final box = Hive.box('categories_cache');

      final cached = await _cache.get<List<Category>>(box, 'categories',
          (json) {
            // Explicitly type the intermediate list so .map() and .toList()
            // operate on a known shape instead of dynamic — this is what
            // actually produces a true List<Category>, not List<dynamic>.
            final rawList = json as List<dynamic>;
            return rawList
                .map((e) => Category.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList(); // now correctly inferred as List<Category>
          },
      );

      if (cached != null) return cached;

      final response = await _dio.get('/categories');
      final categories = response.data as List;

      await _cache.save(box, 'categories', categories);

      return categories
          .map((item) => Category.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── GET /content/:id/stream ──────────────────────────────────────────────
  @override
  Future<String> getStreamUrl({required String id}) async {
    try {
      final response = await _dio.get('/content/$id/stream');
      final streamUrl = response.data['streamUrl'] as String?;

      if (streamUrl == null) {
        throw Exception('Server did not return a stream URL');
      }

      return streamUrl;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── Error handling ──────────────────────────────────────────────────────
  // Converts raw DioExceptions into clean, user-readable exceptions.
  // This is the ONLY place in the repository that knows about HTTP status
  // codes — everything above this returns plain Exceptions with messages
  // the UI can display directly.
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
      case 400:
        return Exception(serverMessage ?? 'Invalid request');
      case 401:
        return Exception('Session expired. Please log in again.');
      case 403:
        return Exception('You don\'t have permission to do this');
      case 404:
        return Exception(serverMessage ?? 'Content not found');
      case 409:
        return Exception(serverMessage ?? 'This already exists');
      case 500:
        return Exception('Server error. Please try again later.');
      default:
        AppLogger.e('Unhandled DioException: $e');
        return Exception('Something went wrong. Please try again.');
    }
  }
}
