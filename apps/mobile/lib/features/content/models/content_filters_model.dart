// Content Filters Model
//
// Pure Dart data class — no Flutter, no Dio, no external dependencies.
// Represents the query parameters accepted by GET /content on the backend
// (see QueryContentDto in NestJS). This class's only job is to turn itself
// into a Map<String, String> that Dio can send as query parameters.
//
// Keeping this separate from Content/Category means the UI layer can build
// up filters (search text, selected category, page number) without knowing
// anything about how they get serialized into an HTTP request.

class ContentFilters {
  final String? search;
  final String? categoryId;
  final String? authorId;
  final String? contentType;   // e.g. "NOVEL", "PODCAST"
  final bool? isPublished;
  final int page;
  final int limit;

  const ContentFilters({
    this.search,
    this.categoryId,
    this.authorId,
    this.contentType,
    this.isPublished,
    this.page = 1,
    this.limit = 10,
  });

  /// Converts this object into a query parameter map for Dio.
  ///
  /// Only includes a key if its value is non-null — this matches the
  /// backend's behavior of treating missing/undefined query params as
  /// "no filter," rather than sending the literal string "null".
  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (search != null && search!.isNotEmpty) {
      params['search'] = search;
    }
    if (categoryId != null) {
      params['categoryId'] = categoryId;
    }
    if (authorId != null) {
      params['authorId'] = authorId;
    }
    if (contentType != null) {
      params['contentType'] = contentType;
    }
    if (isPublished != null) {
      params['isPublished'] = isPublished;
    }

    return params;
  }

  /// Returns a copy of these filters with the given fields replaced.
  ///
  /// Pass `clearSearch: true` / `clearCategoryId: true` / etc. to explicitly
  /// remove a filter — just passing `null` for the field itself wouldn't
  /// distinguish "I want to clear this" from "I'm not changing this,"
  /// since copyWith's normal pattern treats null as "keep existing value."
  ContentFilters copyWith({
    String? search,
    String? categoryId,
    String? authorId,
    String? contentType,
    bool? isPublished,
    int? page,
    int? limit,
    bool clearSearch = false,
    bool clearCategoryId = false,
    bool clearAuthorId = false,
    bool clearContentType = false,
    bool clearIsPublished = false,
  }) {
    return ContentFilters(
      search: clearSearch ? null : (search ?? this.search),
      categoryId: clearCategoryId ? null : (categoryId ?? this.categoryId),
      authorId: clearAuthorId ? null : (authorId ?? this.authorId),
      contentType: clearContentType ? null : (contentType ?? this.contentType),
      isPublished: clearIsPublished ? null : (isPublished ?? this.isPublished),
      // Changing any actual filter should reset pagination back to page 1 —
      // otherwise the user could land on "page 3" of a now much-smaller result set.
      page: page ?? 1,
      limit: limit ?? this.limit,
    );
  }

  /// Convenience constructor for moving to the next page while
  /// keeping every other filter exactly the same.
  ContentFilters nextPage() => copyWith(page: page + 1);

  /// Convenience constructor for resetting to page 1 with all filters cleared —
  /// e.g. when the user taps "Clear filters" in the UI.
  factory ContentFilters.initial() => const ContentFilters();

  /// True if any filter (other than pagination) is currently active.
  /// Useful for showing a "Clear filters" button only when needed.
  bool get hasActiveFilters =>
      (search != null && search!.isNotEmpty) ||
          categoryId != null ||
          authorId != null ||
          contentType != null ||
          isPublished != null;

  @override
  String toString() => 'ContentFilters(${toQueryParams()})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          (other is ContentFilters &&
              other.search == search &&
              other.categoryId == categoryId &&
              other.authorId == authorId &&
              other.contentType == contentType &&
              other.isPublished == isPublished &&
              other.page == page &&
              other.limit == limit);

  @override
  int get hashCode => Object.hash(
    search,
    categoryId,
    authorId,
    contentType,
    isPublished,
    page,
    limit,
  );
}
