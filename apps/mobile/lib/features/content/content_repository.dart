import 'package:Audioverse/features/content/models/models.dart';

// Content Repository â€” abstract contract
//
// Defines WHAT the content feature can do.
// The implementation (content_repository_impl.dart) decides HOW.
//
// This separation means you can swap implementations freely:
//   - Real API in production
//   - Mock in tests
//   - Local cache during offline mode

abstract class ContentRepository {
  Future<PaginatedContent> getContent({
    required ContentFilters filters
  });

  Future<Content> getContentById({
    required String id
  });

  Future<List<Content>> searchContent({
    required String query
  });

  Future<List<Content>> getFeatured();

  Future<List<Category>> getCategories();

  Future<String> getStreamUrl({
    required String id
  });
}
