// Content Model
//
// Pure Dart data class — no Flutter, no Dio, no external dependencies.
// This is the shape of a single audio content item as it flows through
// the app: from the API response, through repositories/providers, into the UI.

import 'package:Audioverse/features/content/models/category_model.dart';

class Content {
  final String id;
  final String title;
  final String slug;
  final String? description;
  final String coverUrl;
  final String? audioUrl;
  final int? durationSec;
  final String contentType;
  final String? language;
  final bool? isPublished;
  final int playCount;
  final String? authorId;
  final String? categoryId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Nested objects — present when the API includes relations
  // (e.g. GET /content/:id includes full author + category)
  final ContentAuthor? author;
  final ContentCategory? category;

  const Content({
    required this.id,
    required this.title,
    required this.slug,
    this.description,
    required this.coverUrl,
    this.audioUrl,
    this.durationSec,
    required this.contentType,
    this.isPublished,
    required this.playCount,
    this.authorId,
    this.categoryId,
    this.createdAt,
    this.updatedAt,
    this.language,
    this.author,
    this.category,
  });

  /// Build from the JSON your NestJS server returns.
  /// Keys match NestJS's default camelCase serialization.
  factory Content.fromJson(Map<String, dynamic> json) {
    return Content(
      id:          json['id'] as String,
      title:       json['title'] as String,
      slug:        json['slug'] as String,
      description: json['description'] as String?,
      coverUrl:    json['cover-url'] as String,
      audioUrl:    json['audio-url'] as String?,
      durationSec: json['duration-sec'] as int?,
      contentType: json['content-type'] as String,
      language:    json['language'] as String?,
      isPublished: json['is-published'] as bool?,
      playCount:   json['play-count'] as int,
      authorId:    json['author-id'] as String?,
      categoryId:  json['category-id'] as String?,
      createdAt:   json['created-at'] == null
        ? null
        : DateTime.parse(json['created-at'] as String),
      updatedAt:   json['updated-at'] == null
          ? null
          : DateTime.parse(json['updated-at'] as String),

      // These are only present when the API includes the relation.
      // We guard with null checks so this model works whether the
      // backend sends the full nested object or just the raw IDs.
      author: json['author'] != null
          ? ContentAuthor.fromJson(Map<String, dynamic>.from(json['author'] as Map))
          : null,
      category: json['category'] != null
          ? ContentCategory.fromJson(Map<String, dynamic>.from(json['category'] as Map))
          : null,
    );
  }

  /// Convert back to JSON — used when sending data TO the server,
  /// e.g. in a create/update request body.
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'slug': slug,
    'description': description,
    'coverUrl': coverUrl,
    'audioUrl': audioUrl,
    'durationSec': durationSec,
    'contentType': contentType,
    'language': language,
    'isPublished': isPublished,
    'playCount': playCount,
    'authorId': authorId,
    'categoryId': categoryId,
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };

  /// Returns a copy of this Content with the given fields replaced.
  /// Useful for local optimistic updates — e.g. bumping playCount
  /// in the UI immediately, before the server confirms it.
  Content copyWith({
    String? title,
    String? description,
    String? coverUrl,
    String? audioUrl,
    int? durationSec,
    String? contentType,
    String? language,
    bool? isPublished,
    int? playCount,
    String? authorId,
    String? categoryId,
    ContentAuthor? author,
    ContentCategory? category,
  }) {
    return Content(
      id: id,
      title: title ?? this.title,
      slug: slug,
      description: description ?? this.description,
      coverUrl: coverUrl ?? this.coverUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      durationSec: durationSec ?? this.durationSec,
      contentType: contentType ?? this.contentType,
      language: language ?? this.language,
      isPublished: isPublished ?? this.isPublished,
      playCount: playCount ?? this.playCount,
      authorId: authorId ?? this.authorId,
      categoryId: categoryId ?? this.categoryId,
      createdAt: createdAt,
      updatedAt: updatedAt,
      author: author ?? this.author,
      category: category ?? this.category,
    );
  }

  /// Human-readable duration, e.g. "1h 23m" or "45m".
  /// Handy for displaying directly in list tiles without extra logic in the UI.
  String get formattedDuration {
    final hours = durationSec! ~/ 3600;
    final minutes = (durationSec! % 3600) ~/ 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  @override
  String toString() => 'Content(id: $id, title: $title, type: $contentType)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Content && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

// ─────────────────────────────────────────────────────────────────────────────
// ContentAuthor — lightweight author info nested inside a Content response.
// This is NOT the full Author model (see author.dart for that) — it only
// contains what the content list/detail endpoints actually return for
// the author relation (id, name, avatarUrl).
// ─────────────────────────────────────────────────────────────────────────────

class ContentAuthor {
  final String id;
  final String name;
  final String? avatarUrl;
  final String? bio;

  const ContentAuthor({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.bio,
  });

  factory ContentAuthor.fromJson(Map<String, dynamic> json) {
    return ContentAuthor(
      id: json['id'] as String,
      name: json['name'] as String,
      avatarUrl: json['avatar-url'] as String?,
      bio: json['bio'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'avatar-url': avatarUrl,
    'bio': bio,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// ContentCategory — lightweight category info nested inside a Content response.
// Mirrors what the content endpoints select for the category relation.
// ─────────────────────────────────────────────────────────────────────────────

class ContentCategory {
  final String id;
  final String name;
  final String? slug;
  final String? colorHex;

  const ContentCategory({
    required this.id,
    required this.name,
    this.slug,
    this.colorHex,
  });

  factory ContentCategory.fromJson(Map<String, dynamic> json) {
    return ContentCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String?,
      colorHex: json['colorHex'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'slug': slug,
    'colorHex': colorHex,
  };
}

class PaginatedContent {
  final List<Content> items;
  final PaginationMeta meta;

  const PaginatedContent({required this.items, required this.meta});
}
