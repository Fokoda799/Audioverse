import 'dart:async';
import 'package:Audioverse/core/network/cach_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:Audioverse/core/utils/app_logger.dart';
import 'package:Audioverse/features/content/models/models.dart';
import 'package:Audioverse/features/content/content_repository.dart';
import 'package:hive/hive.dart';

// Search Provider
//
// Owns the state for the search screen/bar. Debounces user input so we
// don't fire a network request on every single keystroke — only after
// the user pauses typing for a short moment.
//
// Screens read from it via context.watch<SearchProvider>()
// Screens call methods via context.read<SearchProvider>().methodName()
//
// State the UI reacts to:
//   query        → the current search text (so the TextField can stay in sync)
//   isLoading    → show spinner while a search request is in flight
//   results      → the matched content list
//   errorMessage → show error banners
//   hasSearched  → distinguishes "haven't searched yet" from "searched, found nothing"
//                  so the UI can show a different empty state for each

class SearchProvider extends ChangeNotifier {
  late final ContentRepository _repository;
  late final CacheManager _cache;

  // How long to wait after the last keystroke before actually searching.
  // 400ms is a common sweet spot — long enough to avoid firing on every
  // letter, short enough that the results still feel responsive.
  static const _debounceDuration = Duration(milliseconds: 400);

  SearchProvider({required ContentRepository repository, required CacheManager cache}) :
    _cache = cache, _repository = repository;

  Timer? _debounceTimer;

  String _query = '';
  bool _isLoading = false;
  bool _hasSearched = false;
  List<Content> _results = [];
  List<String?> _recentSearches = [];
  String? _errorMessage;

  String get query => _query;
  bool get isLoading => _isLoading;
  bool get hasSearched => _hasSearched;
  List<Content> get results => _results;
  List<String?> get recentSearches => _recentSearches;
  String? get errorMessage => _errorMessage;

  // Distinguishes "user hasn't searched yet" (show suggestions/recent searches)
  // from "user searched and got zero results" (show "no results found")
  bool get hasNoResults => _hasSearched && !_isLoading && _results.isEmpty;

  Future<void> loadRecentSearches() async {
    await _loadRecentSearches();
  }

  // ── Called on every keystroke from the search TextField's onChanged ────
  //
  // This is the main entry point from the UI. It updates the query
  // immediately (so the TextField/UI reflects what was typed), but
  // delays the actual network call via debouncing.
  void onQueryChanged(String newQuery) {
    _query = newQuery;
    notifyListeners(); // update UI immediately (e.g. show/hide a clear button)

    // Cancel any pending search — the user kept typing, so the previous
    // scheduled search is now stale and should not fire.
    _debounceTimer?.cancel();

    if (newQuery.trim().isEmpty) {
      // Don't search on empty input — just clear results immediately
      _results = [];
      _hasSearched = false;
      _errorMessage = null;
      notifyListeners();
      return;
    }

    // Schedule the actual search to run after the debounce window,
    // unless the user types again before then (in which case this
    // timer gets cancelled above on the next call).
    _debounceTimer = Timer(_debounceDuration, () {
      _performSearch(newQuery);
    });
  }

  // ── Run the search immediately ──────────────────────────────────────────
  //
  // Use this for explicit search actions (e.g. user taps a "Search" button
  // or presses Enter) where you want to skip the debounce delay entirely.
  Future<void> searchNow(String query) async {
    _debounceTimer?.cancel();
    _query = query;
    await _performSearch(query);
    await _saveRecentSearch(query);
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _results = await _repository.searchContent(query: query);
      _hasSearched = true;
      _clearError();
    } catch (e, st) {
      AppLogger.e('Search failed for "$query"', error: e, stackTrace: st);
      _setError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadRecentSearches() async {
    try {
      if (!Hive.isBoxOpen('recent_searches')) {
        await Hive.openBox('recent_searches');
      }
      final box = Hive.box('recent_searches');

      final cached = await _cache.get(box, 'queries', (json) {
        if (json is List) {
          return json.map((e) => e?.toString()).toList();
        }
        return <String?>[];
      });
      
      _recentSearches = cached ?? [];
      notifyListeners();

    } catch(e, st) {
      AppLogger.e('Load failed for recent searches', error: e, stackTrace: st);
      _recentSearches = [];
      notifyListeners();
    }
  }

  Future<void> _saveRecentSearch(String query) async {
    try {
      final box = Hive.box('recent_searches');
      await _loadRecentSearches();

      _recentSearches.remove(query);
      _recentSearches.insert(0, query);

      if (_recentSearches.length > 5) _recentSearches.removeLast();

      _cache.save(box, 'queries', _recentSearches);

    } catch(e, st) {
      AppLogger.e('Save failed for recent searches', error: e, stackTrace: st);
      _setError(e);
    }
  }

  // ── Clear the search entirely ────────────────────────────────────────────
  //
  // Call this when the user taps the "X" in the search field, or
  // navigates away from the search screen.
  void clear() {
    _debounceTimer?.cancel();
    _query = '';
    _results = [];
    _hasSearched = false;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(Object e) { _errorMessage = e.toString().replaceAll('Exception: ', ''); }
  void _clearError()       { _errorMessage = null; }

  // ── Cleanup ───────────────────────────────────────────────────────────────
  // Always cancel pending timers when the provider is disposed —
  // otherwise the timer can fire after the widget tree is gone and
  // crash on notifyListeners().
  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
