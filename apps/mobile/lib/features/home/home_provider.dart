import 'package:flutter/foundation.dart';
import 'package:Audioverse/core/utils/app_logger.dart';
import 'package:Audioverse/features/content/models/models.dart';
import 'package:Audioverse/features/content/content_repository.dart';
import 'package:Audioverse/features/home/widgets/continue_listening_row.dart';

// Home Provider
//
// Owns the two pieces of home-screen state that don't belong to any of
// the existing content providers: the featured carousel items, and the
// continue-listening row. ContentListProvider/CategoriesProvider (built
// previously) handle the grid and chips respectively — this provider is
// scoped specifically to what's unique about the Home screen.
//
// Screens read from it via context.watch<HomeProvider>()
// Screens call methods via context.read<HomeProvider>().methodName()
//
// State the UI reacts to:
//   isLoadingFeatured           → shimmer for the carousel
//   isLoadingContinueListening  → shimmer for the continue-listening row
//   featured                    → items for FeaturedCarousel
//   continueListening           → items for ContinueListeningRow
//   errorMessage                → show error banners
//
// home_provider.dart

class HomeProvider extends ChangeNotifier {
  final ContentRepository   _repository;

  HomeProvider({required ContentRepository repository})
      : _repository = repository;

  bool _isLoadingFeatured = false;
  bool _isLoadingContinueListening = false;
  List<Content> _featured = [];
  List<ContinueListeningItem> _continueListening = [];
  String? _errorMessage;

  bool get isLoadingFeatured => _isLoadingFeatured;
  bool get isLoadingContinueListening => _isLoadingContinueListening;
  List<Content> get featured => _featured;
  List<ContinueListeningItem> get continueListening => _continueListening;
  String? get errorMessage => _errorMessage;

  // ── Load everything the Home screen needs on first open ────────────────
  //
  // Runs both fetches concurrently rather than sequentially — they're
  // independent of each other, so there's no reason to make the user
  // wait for featured items to finish before continue-listening starts.
  Future<void> loadHome() async {
    await Future.wait([
      _loadFeatured(),
      _loadContinueListening(),
    ]);
  }

  // ── Pull-to-refresh entry point ─────────────────────────────────────────
  // Identical to loadHome() for now, but kept as its own named method so
  // HomeScreen's RefreshIndicator has a clear, intention-revealing call
  // site rather than reusing loadHome() and leaving readers to wonder if
  // refresh should behave differently in the future.
  Future<void> refresh() => loadHome();

  Future<void> _loadFeatured() async {
    _isLoadingFeatured = true;
    notifyListeners();

    try {
      // Featured items are simply the most-played published content —
      // reuses the existing /content endpoint with a small page size
      // rather than requiring a dedicated backend endpoint.
      final result = await _repository.getFeatured();
      _featured = result;
      _errorMessage = null;
    } catch (e, st) {
      AppLogger.e('Failed to load featured content', error: e, stackTrace: st);
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoadingFeatured = false;
      notifyListeners();
    }
  }

  Future<void> _loadContinueListening() async {
    _isLoadingContinueListening = true;
    notifyListeners();

    try {
      // NOTE: requires a ListeningHistoryRepository method (e.g.
      // getInProgress()) that returns ListeningHistory rows joined with
      // their Content — not yet built in this delivery. Wired here as
      // the integration point; swap in the real call once that
      // repository exists.
      _continueListening = [];
      _errorMessage = null;
    } catch (e, st) {
      AppLogger.e('Failed to load continue listening', error: e, stackTrace: st);
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoadingContinueListening = false;
      notifyListeners();
    }
  }
}
