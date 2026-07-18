import 'package:flutter/foundation.dart';
import 'package:Audioverse/core/utils/app_logger.dart';
import 'package:Audioverse/features/content/models/models.dart';
import 'package:Audioverse/features/content/content_repository.dart';

class HomeProvider extends ChangeNotifier {
  final ContentRepository   _repository;

  HomeProvider({required ContentRepository repository})
      : _repository = repository;

  bool _isLoadingFeatured = false;
  bool _isLoadingAudiobooks = false;
  List<Content> _featured = [];
  List<Content> _audiobooks = [];
  String? _errorMessage;

  bool get isLoadingFeatured => _isLoadingFeatured;
  bool get isLoadingAudiobooks => _isLoadingAudiobooks;
  List<Content> get featured => _featured;
  List<Content> get audiobooks => _audiobooks;
  String? get errorMessage => _errorMessage;

  // ── Load everything the Home screen needs on first open ────────────────
  //
  // Runs both fetches concurrently rather than sequentially — they're
  // independent of each other, so there's no reason to make the user
  // wait for featured items to finish before continue-listening starts.
  Future<void> loadHome() async {
    await Future.wait([
      _loadFeatured(),
      _loadAudiobooks(),
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
    } catch (e, st) {
      AppLogger.e('Failed to load featured content', error: e, stackTrace: st);
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoadingFeatured = false;
      notifyListeners();
    }
  }

  Future<void> _loadAudiobooks() async {
    _isLoadingAudiobooks = true;
    notifyListeners();

    try {
      final result = await _repository.getContent(
        filters: const ContentFilters(contentType: 'AUDIOBOOK', limit: 10),
      );
      _audiobooks = result.items;
    } catch (e, st) {
      AppLogger.e('Failed to load audiobooks', error: e, stackTrace: st);
    } finally {
      _isLoadingAudiobooks = false;
      notifyListeners();
    }
  }
}
