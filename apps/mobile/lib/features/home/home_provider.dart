import 'package:flutter/foundation.dart';
import 'package:Audioverse/core/utils/app_logger.dart';
import 'package:Audioverse/features/content/models/models.dart';
import 'package:Audioverse/features/content/content_repository.dart';

class HomeProvider extends ChangeNotifier {
  final ContentRepository   _repository;

  HomeProvider({required ContentRepository repository})
      : _repository = repository;

  bool _isLoadingFeatured = false;
  List<Content> _featured = [];
  String? _errorMessage;

  bool get isLoadingFeatured => _isLoadingFeatured;
  List<Content> get featured => _featured;
  String? get errorMessage => _errorMessage;

  // ── Load everything the Home screen needs on first open ────────────────
  //
  // Runs both fetches concurrently rather than sequentially — they're
  // independent of each other, so there's no reason to make the user
  // wait for featured items to finish before continue-listening starts.
  Future<void> loadHome() async {
    await Future.wait([
      _loadFeatured(),
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
}
