import 'package:flutter/foundation.dart';
import 'package:Audioverse/core/utils/app_logger.dart';
import 'package:Audioverse/features/content/models/models.dart';
import 'package:Audioverse/features/content/content_repository.dart';

class ContentListProvider extends ChangeNotifier {
  final ContentRepository _repository;

  ContentListProvider({required ContentRepository repository})
      : _repository = repository;

  bool _isLoading = false;       // true only during the FIRST load (empty list)
  bool _isLoadingMore = false;   // true while fetching an additional page
  String? _errorMessage;

  List<Content> _items = [];
  ContentFilters _filters = ContentFilters.initial();
  PaginationMeta? _meta;

  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  List<Content> get items => _items;
  ContentFilters get filters => _filters;

  // Whether another page exists — drives infinite scroll triggers in the UI.
  // Defaults to true before the first load so the UI doesn't assume
  // "no more pages" before we've actually checked.
  bool get hasMore => _meta?.hasNextPage ?? true;

  bool get isEmpty => _items.isEmpty && !_isLoading;

  // ── Initial load / refresh ──────────────────────────────────────────────
  //
  // Call this when the screen first opens, or when the user pulls to refresh.
  // Always resets to page 1 and replaces the entire list — this is NOT
  // for pagination, use loadMore() for that.
  Future<void> load({ContentFilters? filters}) async {
    // Allow the caller to pass new filters (e.g. switching category tabs)
    // without forcing them to manually reset the page number — copyWith
    // already resets page to 1 whenever filters change.
    if (filters != null) {
      _filters = filters;
    } else {
      _filters = _filters.copyWith(page: 1);
    }

    _setLoading();
    try {
      final result = await _repository.getContent(filters: _filters);
      _items = result.items;       // replace, don't append — this is a fresh load
      _meta = result.meta;
      _clearError();
    } catch (e, st) {
      AppLogger.e('Failed to load content list', error: e, stackTrace: st);
      _setError(e);
    } finally {
      _stopLoading();
    }
  }

  // ── Load the next page and append ───────────────────────────────────────
  //
  // Call this from a scroll listener when the user nears the bottom of the
  // list. Appends new items rather than replacing — that's what makes
  // infinite scroll work without the list jumping or flickering.
  Future<void> loadMore() async {
    // Guard against duplicate calls — e.g. if the scroll listener fires
    // multiple times before the previous loadMore() finishes
    if (_isLoadingMore || !hasMore) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final nextFilters = _filters.copyWith(page: (_meta?.page ?? 1) + 1);
      final result = await _repository.getContent(filters: nextFilters);

      _items = [..._items, ...result.items]; // append, preserving existing items
      _meta = result.meta;
      _filters = nextFilters;
      _clearError();
    } catch (e, st) {
      AppLogger.e('Failed to load more content', error: e, stackTrace: st);
      _setError(e);
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // ── Update filters and reload from page 1 ───────────────────────────────
  //
  // Use this when the user changes a filter — e.g. taps a different
  // category chip, or toggles a content type filter.
  Future<void> applyFilters(ContentFilters newFilters) async {
    await load(filters: newFilters);
  }

  // ── Clear all filters and reload ────────────────────────────────────────
  Future<void> clearFilters() async {
    await load(filters: ContentFilters.initial());
  }

  void _setLoading()       { _isLoading = true;  _errorMessage = null; notifyListeners(); }
  void _stopLoading()      { _isLoading = false; notifyListeners(); }
  void _setError(Object e) { _errorMessage = e.toString().replaceAll('Exception: ', ''); }
  void _clearError()       { _errorMessage = null; }
}
