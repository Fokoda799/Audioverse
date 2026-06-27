import 'package:Audioverse/features/personalization/repositories/history_repository.dart';
import 'package:Audioverse/features/content/models/category_model.dart';
import 'package:Audioverse/features/personalization/models/history_model.dart';
import 'package:flutter/foundation.dart';
import 'package:Audioverse/core/utils/app_logger.dart';

class HistoryProvider extends ChangeNotifier {
  final HistoryRepository _repository;

  HistoryProvider({required HistoryRepository repository})
      : _repository = repository;

  // ── Continue Listening state ────────────────────────────────────────────
  bool _isLoadingContinueListening = false;
  List<History> _continueListening = [];
  String? _continueListeningError;

  bool get isLoadingContinueListening => _isLoadingContinueListening;
  List<History> get continueListening => _continueListening;
  String? get continueListeningError => _continueListeningError;

  // ── Full History (paginated) state ──────────────────────────────────────
  bool _isLoading = false;       // first-page load
  bool _isLoadingMore = false;   // subsequent pages (infinite scroll)
  List<History> _items = [];
  PaginationMeta? _meta;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  List<History> get items => _items;
  String? get errorMessage => _errorMessage;
  bool get hasMore => _meta?.hasNextPage ?? true;
  bool get isEmpty => _items.isEmpty && !_isLoading;

  // ── Continue Listening ───────────────────────────────────────────────────
  //
  // Called by HomeScreen alongside its other loads (categories, featured,
  // content list) — see HOME_PROVIDER_INTEGRATION note at the bottom.
  Future<void> loadContinueListening() async {
    _isLoadingContinueListening = true;
    _continueListeningError = null;
    notifyListeners();

    try {
      _continueListening = await _repository.getContinueListening();
      AppLogger.d("history: ${_continueListening[0].progressPercent}");
      _continueListeningError = null;
    } catch (e, st) {
      AppLogger.e('Failed to load continue listening', error: e, stackTrace: st);
      _continueListeningError = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoadingContinueListening = false;
      notifyListeners();
    }
  }

  // ── Full History — initial load / pull-to-refresh ───────────────────────
  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.getHistory(page: 1);
      _items = result.items;     // replace — this is a fresh load, not an append
      _meta = result.meta;
      _errorMessage = null;
    } catch (e, st) {
      AppLogger.e('Failed to load history', error: e, stackTrace: st);
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Full History — infinite scroll ───────────────────────────────────────
  Future<void> loadMore() async {
    if (_isLoadingMore || !hasMore) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = (_meta?.page ?? 1) + 1;
      final result = await _repository.getHistory(page: nextPage);

      _items = [..._items, ...result.items]; // append, not replace
      _meta = result.meta;
      _errorMessage = null;
    } catch (e, st) {
      AppLogger.e('Failed to load more history', error: e, stackTrace: st);
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // ── Remove one item from history ─────────────────────────────────────────
  //
  // Optimistic, same principle as FavoritesProvider.toggleFavorite() —
  // remove from local state immediately, roll back on failure. Updates
  // BOTH lists since the same contentId could appear in either.
  Future<void> removeFromHistory(String contentId) async {
    final removedFromMain = _items.indexWhere((e) => e.content.id == contentId);
    final removedFromContinue =
    _continueListening.indexWhere((e) => e.content.id == contentId);

    final mainBackup = removedFromMain != -1 ? _items[removedFromMain] : null;
    final continueBackup =
    removedFromContinue != -1 ? _continueListening[removedFromContinue] : null;

    if (mainBackup != null) _items.removeAt(removedFromMain);
    if (continueBackup != null) _continueListening.removeAt(removedFromContinue);
    notifyListeners();

    try {
      await _repository.deleteHistory(contentId);
    } catch (e, st) {
      AppLogger.e('Failed to remove history for $contentId — rolling back',
          error: e, stackTrace: st);

      // Roll back by re-inserting at the original index where possible —
      // keeps the list order stable rather than appending the restored
      // item to the end, which would visually jump on failure.
      if (mainBackup != null) {
        _items.insert(removedFromMain.clamp(0, _items.length), mainBackup);
      }
      if (continueBackup != null) {
        _continueListening.insert(
            removedFromContinue.clamp(0, _continueListening.length), continueBackup);
      }
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  // ── Clear on logout ───────────────────────────────────────────────────────
  void clear() {
    _continueListening = [];
    _items = [];
    _meta = null;
    _errorMessage = null;
    _continueListeningError = null;
    notifyListeners();
  }
}