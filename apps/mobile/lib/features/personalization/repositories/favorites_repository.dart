import 'package:Audioverse/features/content/models/models.dart';

// FavoritesRepository
//
// Abstract interface — mirrors the pattern used by ContentRepository.
// This REPLACES the FavoriteRepository stub that was defined inline in
// content_detail_screen.dart earlier; that stub should be deleted once
// this is wired in (see FavoritesScreen/heart-icon delivery notes).
//
// favorites_repository.dart

abstract class FavoritesRepository {
  /// Paginated list of the current user's favorited content, with full
  /// content details joined (cover, title, author, etc.) — matches the
  /// GET /favorites response shape from the backend.
  Future<PaginatedFavorites> getFavorites({required int page});

  /// Upsert on the backend — safe to call even if already favorited.
  Future<void> addFavorite(String contentId);

  /// Safe to call even if not currently favorited — backend returns
  /// removed: false rather than throwing.
  Future<void> removeFavorite(String contentId);
}

// ── PaginatedFavorites ───────────────────────────────────────────────────
//
// Mirrors PaginatedContent's shape (see content_repository_impl.dart) —
// same { items, meta } pattern as every other paginated endpoint in
// this app, just typed for Content directly since /favorites returns
// content with the join already done server-side.
class PaginatedFavorites {
  const PaginatedFavorites({required this.items, required this.meta});

  final List<Content> items;
  final PaginationMeta meta;
}
