import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Audioverse/core/theme/theme.dart';
import 'package:Audioverse/features/content/providers/search_provider.dart';
import 'package:Audioverse/features/content/widgets/search_bar_widget.dart';
import 'package:Audioverse/features/content/widgets/explore_section.dart';
import 'package:Audioverse/features/content/widgets/loading_state.dart';
import 'package:Audioverse/features/content/widgets/results_list.dart';
import 'package:Audioverse/features/content/widgets/empty_results_state.dart';
import 'package:Audioverse/features/content/widgets/search_error_state.dart';

// SearchScreen
//
// Full-screen search experience for AudioVerse.
//
// Layout:
//   • Fixed top bar with search TextField (autofocused) — SearchBarWidget
//   • Body switches between 5 states driven by SearchProvider:
//       1. Error    – SearchErrorState
//       2. Loading  – LoadingState
//       3. Results  – ResultsList
//       4. No results – EmptyResultsState
//       5. Idle (untouched search field) – ExploreSection
//          (trending chips + category quick-links grid)
//
// This file is now pure composition — every visual piece lives in its
// own file under widgets/. SearchScreen's only jobs are: own the
// TextEditingController/FocusNode, wire their callbacks to
// SearchProvider, and pick which state widget to show.
//
// search_screen.dart

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      // Ensure we start with a clean state when entering the search screen
      context.read<SearchProvider>().clear();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    context.read<SearchProvider>().onQueryChanged(value);
  }

  void _onClear() {
    _controller.clear();
    context.read<SearchProvider>().clear();
    _focusNode.requestFocus();
  }

  void _onSubmitted(String value) {
    context.read<SearchProvider>().searchNow(value);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final textPrimary =
    isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary =
    isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final surfaceColor =
    isDark ? AppColors.darkSurface : AppColors.lightSurface;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            SearchBarWidget(
              controller: _controller,
              focusNode: _focusNode,
              isDark: isDark,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              borderColor: borderColor,
              surfaceColor: surfaceColor,
              onChanged: _onChanged,
              onSubmitted: _onSubmitted,
              onClear: _onClear,
            ),
            const SizedBox(height: AppSpacing.xs),
            Expanded(
              child: Consumer<SearchProvider>(
                builder: (context, provider, _) {
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _buildBody(
                      context,
                      provider: provider,
                      isDark: isDark,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      surfaceColor: surfaceColor,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
      BuildContext context, {
        required SearchProvider provider,
        required bool isDark,
        required Color textPrimary,
        required Color textSecondary,
        required Color surfaceColor,
      }) {
    if (provider.errorMessage != null) {
      return SearchErrorState(
        key: const ValueKey('error'),
        message: provider.errorMessage!,
        isDark: isDark,
        textPrimary: textPrimary,
        textSecondary: textSecondary,
        onRetry: () => context.read<SearchProvider>().searchNow(provider.query),
      );
    }

    if (provider.isLoading) {
      return const LoadingState(key: ValueKey('loading'));
    }

    if (provider.hasSearched && provider.results.isNotEmpty) {
      return ResultsList(
        key: const ValueKey('results'),
        results: provider.results,
        isDark: isDark,
        textPrimary: textPrimary,
        textSecondary: textSecondary,
        surfaceColor: surfaceColor,
      );
    }

    if (provider.hasNoResults) {
      return EmptyResultsState(
        key: const ValueKey('empty'),
        query: provider.query,
        isDark: isDark,
        textPrimary: textPrimary,
        textSecondary: textSecondary,
      );
    }

    // Idle — user hasn't searched yet. Trending chips + category grid.
    return ExploreSection(key: const ValueKey('explore'), isDark: isDark);
  }
}
