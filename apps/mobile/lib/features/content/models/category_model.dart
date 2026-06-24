// Category Model
//
// Pure Dart data class — no Flutter, no Dio, no external dependencies.
// This is the FULL category model, used for:
//   - GET /categories (the category list screen)
//   - GET /categories/:slug/content (category detail header)
//
// Note: this is distinct from ContentCategory in content.dart, which is
// a lightweight version only used when nested inside a Content object.

class Category {
  final String id;
  final String name;
  final String slug;
  final String? iconName;     // e.g. "book-open" — maps to an icon in the UI
  final String? colorHex;     // e.g. "#6C63FF" — used for badges/theming
  final int sortOrder;        // controls display order (admin-controlled)
  final DateTime createdAt;
  final DateTime updatedAt;

  const Category({
    required this.id,
    required this.name,
    required this.slug,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
    this.iconName,
    this.colorHex,
  });

  /// Build from the JSON your NestJS server returns.
  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id:        json['id'] as String,
      name:      json['name'] as String,
      slug:      json['slug'] as String,
      iconName:  json['icon-name'] as String?,
      colorHex:  json['color-hex'] as String?,
      sortOrder: json['sort-order'] as int,
      createdAt: DateTime.parse(json['created-at'] as String),
      updatedAt: DateTime.parse(json['updated-at'] as String),
    );
  }

  /// Convert back to JSON — used when sending data TO the server
  /// (e.g. admin create/update category requests).
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'slug': slug,
    'iconName': iconName,
    'colorHex': colorHex,
    'sortOrder': sortOrder,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  /// Returns a copy of this Category with the given fields replaced.
  Category copyWith({
    String? name,
    String? slug,
    String? iconName,
    String? colorHex,
    int? sortOrder,
  }) {
    return Category(
      id: id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      iconName: iconName ?? this.iconName,
      colorHex: colorHex ?? this.colorHex,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  String toString() => 'Category(id: $id, name: $name, slug: $slug)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Category && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

// ─────────────────────────────────────────────────────────────────────────────
// CategoryWithContent
//
// The shape returned by GET /categories/:slug/content — a category
// PLUS a paginated list of its content. Kept separate from Category
// itself so the plain category list (GET /categories) doesn't need
// to carry around pagination metadata it doesn't have.
// ─────────────────────────────────────────────────────────────────────────────

class CategoryWithContent {
  final Category category;
  final List<dynamic> items; // typed as Content in the content feature layer
  final PaginationMeta meta;

  const CategoryWithContent({
    required this.category,
    required this.items,
    required this.meta,
  });

  factory CategoryWithContent.fromJson(
      Map<String, dynamic> json,
      dynamic Function(Map<String, dynamic>) itemParser,
      ) {
    return CategoryWithContent(
      category: Category.fromJson(Map<String, dynamic>.from(json['category'] as Map)),
      items: (json['items'] as List<dynamic>)
          .map((item) => itemParser(Map<String, dynamic>.from(item as Map)))
          .toList(),
      meta: PaginationMeta.fromJson(Map<String, dynamic>.from(json['meta'] as Map)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PaginationMeta
//
// Shared shape for every paginated endpoint's "meta" object.
// Matches exactly what ContentService.findAll() / findContentBySlug()
// returns from the NestJS backend.
// ─────────────────────────────────────────────────────────────────────────────

class PaginationMeta {
  final int total;
  final int page;
  final int limit;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPrevPage;

  const PaginationMeta({
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPrevPage,
  });

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      total: json['total'] as int,
      page: json['page'] as int,
      limit: json['limit'] as int,
      totalPages: json['total-pages'] as int,
      // hasNextPage / hasPrevPage might be absent on some endpoints
      // (e.g. findContentBySlug doesn't compute them) — default safely
      hasNextPage: json['has-next-page'] as bool? ?? false,
      hasPrevPage: json['has-prev-page'] as bool? ?? false,
    );
  }
}
