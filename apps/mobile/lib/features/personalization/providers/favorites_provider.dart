import 'package:flutter/foundation.dart';
import 'package:Audioverse/core/utils/app_logger.dart';
import 'package:Audioverse/features/personalization/repositories/favorites_repository.dart';

// FavoritesProvider
//
// Owns the SET of favorited content IDs app-wide — this is what every
// heart icon across the app (ContentCard, ContentDetailScreen, search
// results) checks to decide whether to render filled or outlined.
//
// WHY A SET, NOT A LIST OF Content:
// Every heart icon just needs to answer one question fast: "is THIS
// contentId favorited?" — isFavorited(id) is an O(1) Set lookup. If this
// were a List<Content>, every single heart icon render would be doing a
// linear scan, and worse, you'd have two sources of truth for "is this
// favorited" (the Set vs. scanning a list) the moment FavoritesScreen
// also needs the full Content objects for its grid — which it does
// separately, via getFavorites(), kept intentionally distinct from this
// Set. This provider answers "is X favorited", FavoritesScreen's own
// loading logic answers "show me the favorited content".
//
// LOAD ON AUTH: loadFavorites() should be called once, right after
// login succeeds (alongside wherever ProfileProvider.loadProfile() or
// similar gets triggered) — see integration note at the bottom of this
// file for exactly where.
//
// OPTIMISTIC UPDATES: toggleFavorite() flips the UI state IMMEDIATELY,
// before the network call resolves. If the call fails, it's rolled back.
// This is what makes heart-icon taps feel instant rather than waiting
// on a round-trip before the icon changes — see toggleFavorite() below
// for the exact rollback mechanics.
//
// favorites_provider.dart

class FavoritesProvider extends ChangeNotifier {
  final FavoritesRepository _repository;

  FavoritesProvider({required FavoritesRepository repository})
      : _repository = repository;

  // The core state — just IDs, not full Content objects. See the class
  // doc comment above for why.
  Set<String> _favoritedIds = {};

  bool _isLoading = false;
  String? _errorMessage;

  // Tracks which specific contentIds currently have an in-flight toggle
  // request — lets the UI disable/show a tiny spinner on JUST the heart
  // being tapped, rather than a global isLoading disabling every heart
  // icon on screen while any single toggle is in flight.
  final Set<String> _pendingToggles = {};

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Set<String> get favoritedIds => _favoritedIds; // exposed read-only-by-convention

  bool isFavorited(String contentId) => _favoritedIds.contains(contentId);
  bool isToggling(String contentId) => _pendingToggles.contains(contentId);

  // ── Load on auth ─────────────────────────────────────────────────────────
  //
  // Fetches ALL favorited IDs in one go. Note this calls getFavorites()
  // page by page rather than assuming a single page covers everything —
  // a user could easily have more than 10 favorites, and this Set needs
  // to be complete for isFavorited() to be correct anywhere in the app,
  // not just on whatever happens to be page 1.
  Future<void> loadFavorites() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final ids = <String>{};
      int page = 1;

      while (true) {
        final result = await _repository.getFavorites(page: page);
        ids.addAll(result.items.map((content) => content.id));

        if (page >= result.meta.totalPages) break;
        page++;
      }

      _favoritedIds = ids;
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
}

// ─────────────────────────────────────────────────────────────────────────
// INTEGRATION NOTES — not code to copy verbatim, but exact wiring points:
//
// 1. main.dart — construct alongside your other repositories/providers:
//
//      final favoritesRepo = FavoritesRepositoryImpl(dio: dioClient.dio);
//      final favoritesProvider = FavoritesProvider(repository: favoritesRepo);
//
//    ...and register in MultiProvider:
//
//      ChangeNotifierProvider.value(value: widget.favoritesProvider),
//
// 2. Load on auth — wherever your login success flow currently lives
//    (likely inside AuthProvider.login() or a post-login callback in
//    LoginScreen), add:
//
//      await context.read<FavoritesProvider>().loadFavorites();
//
//    The exact call site depends on AuthProvider's current structure,
//    which wasn't shared in this conversation — wire it in alongside
//    however ProfileProvider.loadProfile() is currently triggered post-login,
//    since both need to happen at the same moment.
//
// 3. Clear on logout — wherever AuthProvider.logout() runs, add:
//
//      context.read<FavoritesProvider>().clear();
//
// 4. DELETE the FavoriteRepository stub that was defined inline at the
//    bottom of the earlier content_detail_screen.dart delivery — this
//    FavoritesRepository (note: plural, matching the backend's actual
//    /favorites route) replaces it. The earlier _FavoriteButton widget
//    in that file should be replaced too — see the heart-icon delivery
//    for the replacement.
// ─────────────────────────────────────────────────────────────────────────
