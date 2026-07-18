import 'package:flutter/material.dart';
import 'package:Audioverse/core/theme/theme.dart';
import 'package:Audioverse/features/content/models/models.dart';
import 'package:Audioverse/features/content/widgets/content_result_tile.dart';

// ResultsList
//
// Scrollable list of search results. Thin wrapper around ListView.separated
// + ContentResultTile — kept separate from ContentResultTile itself since
// the list's job (spacing, padding, scroll behavior) is distinct from a
// single tile's job (layout of one result row).
//
// results_list.dart

class ResultsList extends StatelessWidget {
  const ResultsList({
    super.key,
    required this.results,
    required this.isDark,
    required this.textPrimary,
    required this.textSecondary,
    required this.surfaceColor,
  });

  final List<Content> results;
  final bool isDark;
  final Color textPrimary;
  final Color textSecondary;
  final Color surfaceColor;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      itemCount: results.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) => ContentResultTile(
        content: results[index],
        isDark: isDark,
        textPrimary: textPrimary,
        textSecondary: textSecondary,
        surfaceColor: surfaceColor,
      ),
    );
  }
}
