import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import 'package:go_router/go_router.dart';
import 'package:Audioverse/core/theme/theme.dart';
import 'package:Audioverse/features/content/providers/search_provider.dart';
import 'package:Audioverse/features/content/providers/categories_provider.dart';
import 'package:Audioverse/features/content/models/models.dart';
import 'package:Audioverse/features/home/widgets/shimmer_box.dart';

// ExploreSection
//
// Shown when the search field is empty (SearchProvider's idle state).
// Two parts:
//   1. Trending — tappable search-term chips (kept as-is from the
//      original _IdleState; these are curated suggestions, not backend
//      data, since "trending searches" isn't a real endpoint yet)
//   2. Categories — a tappable grid sourced from CategoriesProvider,
//      reusing the same category data as Home's CategoryChips rather
//      than a separate curated list, so adding/renaming a category in
//      one place updates both screens automatically.
//
// Tapping a category here navigates to that category's content list
// rather than triggering a text search — browsing by category and
// searching by keyword are different intents, so this deliberately
// does NOT call SearchProvider for category taps.
//
// explore_section.dart

class ExploreSection extends StatefulWidget {
  const ExploreSection({super.key, required this.isDark});

  final bool isDark;

  @override
  State<ExploreSection> createState() => _ExploreSectionState();
}

class _ExploreSectionState extends State<ExploreSection> {
  @override
  void initState() {
    super.initState();
    // Categories are loaded once at Home already in most apps, but this
    // screen can be reached independently (e.g. deep link), so we ensure
    // they're loaded here too. CategoriesProvider has no built-in guard
    // against duplicate loads, so we check isEmpty first to avoid an
    // unnecessary refetch if Home already populated it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final categories = context.read<CategoriesProvider>();
      final search = context.read<SearchProvider>();
      if (search.recentSearches.isEmpty) search.loadRecentSearches();
      if (categories.categories.isEmpty && !categories.isLoading) {
        categories.loadCategories();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final textSecondary = widget.isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Consumer<SearchProvider>(
            builder: (context, provider, _) {
              return provider.recentSearches.isNotEmpty
                  ? _RecentSearchChips(isDark: widget.isDark, textSecondary: textSecondary)
                  : const SizedBox.shrink();
            },
          ),
          const SizedBox(height: AppSpacing.xl),
          _TrendingChips(isDark: widget.isDark, textSecondary: textSecondary),
          const SizedBox(height: AppSpacing.xl),
          _CategoryGridSection(isDark: widget.isDark, textSecondary: textSecondary),
        ],
      ),
    );
  }
}

// ── Trending chips ──────────────────────────────────────────────────────────
// Unchanged from the original _IdleState — curated, hardcoded suggestions.
// Tapping one runs an actual search via SearchProvider.searchNow().
class _TrendingChips extends StatelessWidget {
  const _TrendingChips({required this.isDark, required this.textSecondary});

  final bool isDark;
  final Color textSecondary;

  static const _suggestions = [
    'Harry Potter',
    'Mindfulness',
    'Lex Fridman',
    'Self-improvement',
    'Sci-fi',
    'History',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Trending', style: AppTextStyles.labelLarge(textSecondary)),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: _suggestions
              .map((s) => _SuggestionChip(
            label: s,
            isDark: isDark,
            onTap: () => context.read<SearchProvider>().searchNow(s),
          ))
              .toList(),
        ),
      ],
    );
  }
}

class _RecentSearchChips extends StatelessWidget {
  const _RecentSearchChips({required this.isDark, required this.textSecondary});

  final bool isDark;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    return Consumer<SearchProvider>(
      builder: (context, provider, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recent', style: AppTextStyles.labelLarge(textSecondary)),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: provider.recentSearches
                  .map((s) => _SuggestionChip(
                label: s,
                isDark: isDark,
                type: SuggestionChipType.recent,
                onTap: () => context.read<SearchProvider>().searchNow(s),
              ))
                  .toList(),
            ),
          ],
        );
      }
    );
  }
}

enum SuggestionChipType { trending, recent }

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({
    required this.label,
    required this.isDark,
    required this.onTap,
    this.type = SuggestionChipType.trending,
    this.onRemove,
  });

  final String label;
  final bool isDark;
  final VoidCallback onTap;
  final SuggestionChipType type;

  // Only meaningful for SuggestionChipType.recent. When provided, shows a
  // small "x" the user can tap to remove this entry from recent searches
  // without triggering a search (onTap).
  final VoidCallback? onRemove;

  IconData get _leadingIcon {
    switch (type) {
      case SuggestionChipType.trending:
        return Icons.trending_up_rounded;
      case SuggestionChipType.recent:
        return Icons.history_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor =
    isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final bgColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final iconColor = type == SuggestionChipType.trending
        ? AppColors.primary
        : textColor.withValues(alpha: 0.6);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.only(
          left: AppSpacing.md,
          right: type == SuggestionChipType.recent && onRemove != null
              ? AppSpacing.xs
              : AppSpacing.md,
          top: AppSpacing.sm,
          bottom: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_leadingIcon, size: 14, color: iconColor),
            const SizedBox(width: AppSpacing.xs),
            Text(label, style: AppTextStyles.bodyMedium(textColor)),
            if (type == SuggestionChipType.recent && onRemove != null) ...[
              const SizedBox(width: AppSpacing.xs),
              GestureDetector(
                onTap: onRemove,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  child: Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: textColor.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Category quick-links grid ───────────────────────────────────────────────
// Sourced from CategoriesProvider — same data Home's CategoryChips uses.
// Renders as a 2-column grid of cards rather than chips, since this is a
// browse entry point (bigger tap target, room for an icon) rather than a
// filter control like the Home chips are.
class _CategoryGridSection extends StatelessWidget {
  const _CategoryGridSection({required this.isDark, required this.textSecondary});

  final bool isDark;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    return Consumer<CategoriesProvider>(
      builder: (context, provider, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Browse categories', style: AppTextStyles.labelLarge(textSecondary)),
            const SizedBox(height: AppSpacing.md),
            if (provider.isLoading)
              _CategoryGridSkeleton()
            else if (provider.categories.isEmpty)
              _CategoryGridEmpty(textSecondary: textSecondary)
            else
              _CategoryGrid(categories: provider.categories, isDark: isDark),
          ],
        );
      },
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({required this.categories, required this.isDark});

  final List<Category> categories;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.sm,
        crossAxisSpacing: AppSpacing.sm,
        // Wide, short cards — icon + label side by side, not a tall poster
        // shape like ContentCard. This is a navigation tile, not cover art.
        childAspectRatio: 2.4,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        return _CategoryQuickLinkCard(category: categories[index], isDark: isDark);
      },
    );
  }
}

class _CategoryQuickLinkCard extends StatelessWidget {
  const _CategoryQuickLinkCard({required this.category, required this.isDark});

  final Category category;
  final bool isDark;

  Color get _accent => _parseColor(category.colorHex) ?? AppColors.primary;

  Color? _parseColor(String? hex) {
    if (hex == null) return null;
    final cleanHex = hex.replaceAll('#', '');
    final value = int.tryParse('FF$cleanHex', radix: 16);
    return value != null ? Color(value) : null;
  }

  IconData _resolveIcon() {
    // Maps the backend's iconName string (e.g. "book-open") to a concrete
    // IconData. Falls back to a generic icon for any name not in this map,
    // so adding a new category server-side never breaks this grid even if
    // its iconName hasn't been mapped here yet.
    switch (category.iconName) {
      case 'book-open':
        return Icons.menu_book_rounded;
      case 'feather':
        return Icons.edit_note_rounded;
      case 'zap':
        return Icons.bolt_rounded;
      case 'mic':
        return Icons.mic_rounded;
      case 'graduation-cap':
        return Icons.school_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return InkWell(
      // Category detail content list — mirrors ContentResultTile's existing
      // navigation pattern of pushing under the Home branch.
      // onTap: () => context.push('/home/category/${category.slug}'),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(_resolveIcon(), color: _accent, size: 20),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                category.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyMedium(textPrimary)
                    .copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Loading / empty states for the category grid ───────────────────────────
class _CategoryGridSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.sm,
        crossAxisSpacing: AppSpacing.sm,
        childAspectRatio: 2.4,
      ),
      itemCount: 6, // matches the 5 real categories + 1 buffer row
      itemBuilder: (_, _) => const ShimmerBox(borderRadius: AppRadius.md),
    );
  }
}

class _CategoryGridEmpty extends StatelessWidget {
  const _CategoryGridEmpty({required this.textSecondary});

  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    // Quiet inline fallback rather than a full EmptyState illustration —
    // this is a secondary section on the search screen, not the primary
    // content, so a large empty-state graphic here would be disproportionate.
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Text(
        'Categories unavailable right now',
        style: AppTextStyles.bodyMedium(textSecondary),
      ),
    );
  }
}
