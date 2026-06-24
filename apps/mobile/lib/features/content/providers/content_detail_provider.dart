import 'package:Audioverse/features/content/models/content_filters_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:Audioverse/core/utils/app_logger.dart';
import 'package:Audioverse/features/content/models/content_models.dart';
import 'package:Audioverse/features/content/content_repository.dart';

class ContentDetailProvider extends ChangeNotifier {
  final ContentRepository _repository;
  final String contentId;

  static const _limit = 10;

  ContentDetailProvider({
    required ContentRepository repository,
    required this.contentId,
  }) : _repository = repository;

  bool _isLoading = false;
  bool _isLoadingStream = false;
  Content? _content;
  List<Content> _byAuthor = [];
  List<Content> _byCategory = [];
  String? _errorMessage;

  bool get isLoading => _isLoading;
  bool get isLoadingStream => _isLoadingStream;
  List<Content> get byCategory => _byCategory;
  List<Content> get byAuthor => _byAuthor;
  Content? get content => _content;
  String? get errorMessage => _errorMessage;

  // Convenient direct getters — so screens don't have to write
  // content?.title everywhere
  String? get title => _content?.title;
  String? get description => _content?.description;
  String? get coverUrl => _content?.coverUrl;
  String get formattedDuration => _content?.formattedDuration ?? '';
  ContentAuthor? get author => _content?.author;
  ContentCategory? get category => _content?.category;

  Future<void> load() async {
    await _loadContent();
    await Future.wait([
      _loadByAuthor(content?.author?.id),
      _loadByCategory(content?.category?.id),
    ]);
  }

  // ── Load the content detail ─────────────────────────────────────────────
  //
  // Call this from initState() / when the provider is first created.
  Future<void> _loadContent() async {
    _setLoading();
    try {
      _content = await _repository.getContentById(id: contentId);
      _clearError();
    } catch (e, st) {
      AppLogger.e('Failed to load content $contentId', error: e, stackTrace: st);
      _setError(e);
    } finally {
      _stopLoading();
    }
  }

  // ── Get a fresh signed stream URL and start playback ───────────────────
  //
  // Always fetches a NEW signed URL rather than caching one — signed URLs
  // expire (typically after 1 hour), so requesting a fresh one each time

  // the user presses Play avoids ever handing the player an expired link.
  //
  // Returns the URL so the caller (e.g. an audio player widget) can use it
  // directly, while also exposing isLoadingStream for a button spinner.
  Future<String?> getStreamUrl() async {
    _isLoadingStream = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final url = await _repository.getStreamUrl(id: contentId);
      return url;
    } catch (e, st) {
      AppLogger.e('Failed to get stream URL for $contentId', error: e, stackTrace: st);
      _setError(e);
      return null;
    } finally {
      _isLoadingStream = false;
      notifyListeners();
    }
  }

  Future<void> _loadByAuthor(String? authorId) async {
    AppLogger.d("Get author");
    if (authorId == null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final ContentFilters filters = const ContentFilters();

      final results = await _repository.getContent(filters: filters.copyWith(
          authorId: authorId,
          limit: _limit
      ));
      // Exclude the content item currently being viewed from its own
      // "more from this author" row.
      _byAuthor = results.items.where((c) => c.id != contentId).toList();
    } catch (e, st) {
      AppLogger.e('Failed to load related-by-author for $authorId', error: e, stackTrace: st);
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadByCategory(String? categoryId) async {
    if (categoryId == null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final ContentFilters filters = const ContentFilters();

      final results = await _repository.getContent(filters: filters.copyWith(
          categoryId: categoryId,
          limit: _limit
      ));
      _byCategory = results.items.where((c) => c.id != contentId).toList();
    } catch (e, st) {
      AppLogger.e('Failed to load related-by-category for $categoryId', error: e, stackTrace: st);
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _setLoading()       { _isLoading = true;  _errorMessage = null; notifyListeners(); }
  void _stopLoading()      { _isLoading = false; notifyListeners(); }
  void _setError(Object e) { _errorMessage = e.toString().replaceAll('Exception: ', ''); }
  void _clearError()       { _errorMessage = null; }
}
