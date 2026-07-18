import 'package:flutter/foundation.dart' hide Category;
import 'package:Audioverse/core/utils/app_logger.dart';
import 'package:Audioverse/features/content/models/models.dart';
import 'package:Audioverse/features/content/content_repository.dart';

// Categories Provider
//
// Owns the state for the full category list — e.g. the horizontal
// category chips/cards on the home screen.
//
// This is a simple, mostly-static list (categories rarely change), so
// unlike ContentListProvider there's no pagination here — just load once
// and cache it for the lifetime of the provider instance.
//
// Screens read from it via context.watch<CategoriesProvider>()
// Screens call methods via context.read<CategoriesProvider>().methodName()
//
// State the UI reacts to:
//   isLoading    → show spinner/shimmer while categories load
//   categories   → the full list, already sorted by sortOrder (server does this)
//   errorMessage → show error banners

class CategoriesProvider extends ChangeNotifier {
  final ContentRepository _repository;

  CategoriesProvider({required ContentRepository repository})
      : _repository = repository;

  bool _isLoading = false;
  List<Category> _categories = [];
  String? _errorMessage;

  bool get isLoading => _isLoading;
  List<Category> get categories => _categories;
  String? get errorMessage => _errorMessage;

  bool get isEmpty => _categories.isEmpty && !_isLoading;

  // ── Load all categories ─────────────────────────────────────────────────
  Future<void> loadCategories() async {
    _setLoading();
    try {
      _categories = await _repository.getCategories();
      _clearError();
    } catch (e, st) {
      AppLogger.e('Failed to load categories', error: e, stackTrace: st);
      _setError(e);
    } finally {
      _stopLoading();
    }
  }

  // ── Find a category by slug ─────────────────────────────────────────────
  //
  // Handy when navigating from a category card — the UI usually already
  // knows the slug (it's in the URL/route) and needs the full Category
  // object (for its colorHex/iconName) without firing another network call.
  Category? findBySlug(String slug) {
    for (final category in _categories) {
      if (category.slug == slug) return category;
    }
    return null;
  }

  void _setLoading()       { _isLoading = true;  _errorMessage = null; notifyListeners(); }
  void _stopLoading()      { _isLoading = false; notifyListeners(); }
  void _setError(Object e) { _errorMessage = e.toString().replaceAll('Exception: ', ''); }
  void _clearError()       { _errorMessage = null; }
}
