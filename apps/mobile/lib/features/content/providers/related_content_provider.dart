import 'package:Audioverse/features/content/models/content_filters_model.dart';
import 'package:flutter/foundation.dart';
import 'package:Audioverse/core/utils/app_logger.dart';
import 'package:Audioverse/features/content/models/content_models.dart';
import 'package:Audioverse/features/content/content_repository.dart';

// Related Content Provider
//
// Scoped to ONE content detail screen, same lifecycle pattern as
// ContentDetailProvider — create a fresh instance per content id (don't
// make this a global/app-wide provider).
//
// Owns TWO independent lists — "more from this author" and "more in this
// category" — each with its own loading/error state, so one failing
// (e.g. author has no other content, or the category fetch 404s) doesn't
// block or blank out the other row.
//
// STUB NOTE: ContentRepository does not yet have a method for fetching
// content by author or category. _fetchByAuthor / _fetchByCategory below
// call placeholder repository methods (getContentByAuthor /
// getContentByCategory) that you'll need to add to ContentRepository,
// hitting GET /content?authorId=X&limit=10 and GET /content?categoryId=X&limit=10
// respectively. Until those exist, this provider will throw on load and
// the rows will silently render their empty state (see RelatedContentRow's
// _hasError handling) rather than crash the detail screen.
class RelatedContentProvider extends ChangeNotifier {
  final ContentRepository _repository;
  final String? authorId;
  final String? categoryId;
  final String excludeContentId;

  static const _limit = 10;

  RelatedContentProvider({
    required ContentRepository repository,
    required this.excludeContentId,
    this.authorId,
    this.categoryId,
  }) : _repository = repository;

  bool _isLoadingAuthor = false;
  bool _isLoadingCategory = false;
  List<Content> _byAuthor = [];
  List<Content> _byCategory = [];
  String? _authorError;
  String? _categoryError;

  bool get isLoadingAuthor => _isLoadingAuthor;
  bool get isLoadingCategory => _isLoadingCategory;
  List<Content> get byAuthor => _byAuthor;
  List<Content> get byCategory => _byCategory;
  String? get authorError => _authorError;
  String? get categoryError => _categoryError;

  // ── Load both rows in parallel ──────────────────────────────────────────
  //
  // Call from initState() / on provider creation. Each fetch is wrapped
  // independently so a failure in one doesn't prevent the other from
  // completing — Future.wait with eagerError: false would also work, but
  // running them as two separate try/catch blocks keeps each row's error
  // state cleanly scoped to that row.
  Future<void> loadRelated() async {
    await Future.wait([
      _loadByAuthor(),
      _loadByCategory(),
    ]);
  }

  Future<void> _loadByAuthor() async {
    if (authorId == null) return;

    _isLoadingAuthor = true;
    _authorError = null;
    notifyListeners();

    try {
      final ContentFilters filters = const ContentFilters();

      final results = await _repository.getContent(filters: filters.copyWith(
        authorId: authorId,
        limit: _limit
      ));
      // Exclude the content item currently being viewed from its own
      // "more from this author" row.
      _byAuthor = results.items.where((c) => c.id != excludeContentId).toList();
    } catch (e, st) {
      AppLogger.e('Failed to load related-by-author for $authorId', error: e, stackTrace: st);
      _authorError = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoadingAuthor = false;
      notifyListeners();
    }
  }

  Future<void> _loadByCategory() async {
    if (categoryId == null) return;

    _isLoadingCategory = true;
    _categoryError = null;
    notifyListeners();

    try {
      final ContentFilters filters = const ContentFilters();

      final results = await _repository.getContent(filters: filters.copyWith(
        categoryId: categoryId,
        limit: _limit
      ));
      _byCategory = results.items.where((c) => c.id != excludeContentId).toList();
    } catch (e, st) {
      AppLogger.e('Failed to load related-by-category for $categoryId', error: e, stackTrace: st);
      _categoryError = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoadingCategory = false;
      notifyListeners();
    }
  }
}
