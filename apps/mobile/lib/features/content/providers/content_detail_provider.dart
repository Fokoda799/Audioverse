import 'package:flutter/foundation.dart';
import 'package:Audioverse/core/utils/app_logger.dart';
import 'package:Audioverse/features/content/models/content_models.dart';
import 'package:Audioverse/features/content/content_repository.dart';

// Content Detail Provider
//
// Owns the state for a SINGLE content item's detail screen — e.g. when
// the user taps a book/podcast and lands on its detail page.
//
// Unlike ContentListProvider, this provider is scoped to ONE content id,
// passed in at construction time. A new instance should be created each
// time the user navigates to a different content's detail screen
// (typically via ChangeNotifierProvider(create: (_) => ContentDetailProvider(...))
// inside the route, rather than a single global instance).
//
// Screens read from it via context.watch<ContentDetailProvider>()
// Screens call methods via context.read<ContentDetailProvider>().methodName()
//
// State the UI reacts to:
//   isLoading       → show spinner while the detail loads
//   content         → the loaded content, or null before/if it fails
//   errorMessage     → show error banners
//   isLoadingStream  → show a small spinner on the Play button while
//                       fetching a fresh signed stream URL

class ContentDetailProvider extends ChangeNotifier {
  final ContentRepository _repository;
  final String contentId;

  ContentDetailProvider({
    required ContentRepository repository,
    required this.contentId,
  }) : _repository = repository;

  bool _isLoading = false;
  bool _isLoadingStream = false;
  Content? _content;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  bool get isLoadingStream => _isLoadingStream;
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

  // ── Load the content detail ─────────────────────────────────────────────
  //
  // Call this from initState() / when the provider is first created.
  Future<void> loadContent() async {
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

  void _setLoading()       { _isLoading = true;  _errorMessage = null; notifyListeners(); }
  void _stopLoading()      { _isLoading = false; notifyListeners(); }
  void _setError(Object e) { _errorMessage = e.toString().replaceAll('Exception: ', ''); }
  void _clearError()       { _errorMessage = null; }
}
