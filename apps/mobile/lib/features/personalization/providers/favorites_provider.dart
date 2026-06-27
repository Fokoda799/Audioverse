import 'package:Audioverse/features/content/models/category_model.dart';
import 'package:Audioverse/features/content/models/content_models.dart';
import 'package:flutter/foundation.dart';
import 'package:Audioverse/core/utils/app_logger.dart';
import 'package:Audioverse/features/personalization/repositories/favorites_repository.dart';

class FavoritesProvider extends ChangeNotifier {
  final FavoritesRepository _repository;

  FavoritesProvider({required FavoritesRepository repository})
    : _repository = repository;

  // The core state — just IDs, not full Content objects. See the class
  // doc comment above for why.
  Set<String> _favoritedIds = {};
  List<Content> _items = [];
  PaginationMeta? _meta;

  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;

  // Tracks which specific contentIds currently have an in-flight toggle
  // request — lets the UI disable/show a tiny spinner on JUST the heart
  // being tapped, rather than a global isLoading disabling every heart
  // icon on screen while any single toggle is in flight.
  final Set<String> _pendingToggles = {};

  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoading;
  String? get errorMessage => _errorMessage;
  Set<String> get favoritedIds => _favoritedIds;
  List<Content> get items => _items;

  bool isFavorited(String contentId) => _favoritedIds.contains(contentId);
  bool isToggling(String contentId) => _pendingToggles.contains(contentId);
  bool get hasMore => _meta?.hasNextPage ?? true;
  bool get isEmpty => _items.isEmpty && !_isLoading;


  Future<void> load() async {
    _setLoading();

    try {
      final results = await _repository.getFavorites(page: 1);
      _items = results.items;
      _meta = results.meta;
      _clearError();
    } catch (e, st) {
      AppLogger.e('Failed to load favorite content list', error: e, stackTrace: st);
      _setError(e);
    } finally {
      _stopLoading();
    }
  }

  Future<void> loadMore() async {
    if(!hasMore || _isLoadingMore) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final results = await _repository.getFavorites(page: (_meta?.page ?? 1) +1);
      _items = [..._items, ...results.items];
      _meta = results.meta;
    } catch (e, st) {
      AppLogger.e('Failed to load more favorites content', error: e, stackTrace: st);
      _setError(e);
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // ── Load on auth ─────────────────────────────────────────────────────────
  //
  // Fetches ALL favorited IDs in one go using the dedicated ids endpoint.
  Future<void> loadFavorites() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _favoritedIds = await _repository.getFavoriteIds();
      _errorMessage = null;
    } catch (e, st) {
      AppLogger.e('Failed to load favorites', error: e, stackTrace: st);
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      // Deliberately don't clear _favoritedIds on failure — if this is
      // called again later (e.g. retry), stale-but-present data is less
      // disruptive than every heart icon suddenly appearing unfavorited.
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Clear on logout ───────────────────────────────────────────────────────
  //
  // Call this from wherever AuthProvider.logout() is handled — without
  // it, the NEXT user to log in on this device would briefly see the
  // PREVIOUS user's favorited hearts until loadFavorites() completes.
  void clear() {
    _favoritedIds = {};
    _pendingToggles.clear();
    _errorMessage = null;
    notifyListeners();
  }

  // ── Optimistic toggle ──────────────────────────────────────────────────────
  //
  // This is the method every heart icon's onTap calls. Flips the Set
  // immediately (optimistic), fires the network call, and rolls back
  // ONLY if the call fails — the UI never has to wait for the server
  // to confirm before the heart visually updates.
  Future<void> toggleFavorite(String contentId) async {
    final wasAlreadyFavorited = isFavorited(contentId);

    // ── Optimistic update — happens synchronously, before any await ────────
    if (wasAlreadyFavorited) {
      _favoritedIds.remove(contentId);
    } else {
      _favoritedIds.add(contentId);
    }
    _pendingToggles.add(contentId);
    notifyListeners(); // heart icon updates RIGHT NOW, network call hasn't even started

    try {
      if (wasAlreadyFavorited) {
        await _repository.removeFavorite(contentId);
      } else {
        await _repository.addFavorite(contentId);
      }
      // Success — the optimistic state IS the correct state, nothing more to do.
    } catch (e, st) {
      AppLogger.e(
        'Failed to toggle favorite for $contentId — rolling back',
        error: e,
        stackTrace: st,
      );

      // ── Rollback — undo exactly what we did above, restoring the
      // state to what it was BEFORE this method was called. Using
      // wasAlreadyFavorited (captured at the top, before any mutation)
      // rather than re-deriving from the now-mutated Set is what makes
      // this rollback correct even if toggleFavorite() were somehow
      // called again on the same id before this one's network call resolved.
      if (wasAlreadyFavorited) {
        _favoritedIds.add(contentId); // it WAS favorited, put it back
      } else {
        _favoritedIds.remove(contentId); // it WASN'T favorited, undo the add
      }

      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _pendingToggles.remove(contentId);
      notifyListeners(); // reflect either the confirmed success or the rollback
    }
  }

  void _setLoading()       { _isLoading = true;  _errorMessage = null; notifyListeners(); }
  void _stopLoading()      { _isLoading = false; notifyListeners(); }
  void _setError(Object e) { _errorMessage = e.toString().replaceAll('Exception: ', ''); }
  void _clearError()       { _errorMessage = null; }
}
