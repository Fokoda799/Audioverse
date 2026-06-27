import 'package:Audioverse/features/personalization/providers/history_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Audioverse/core/theme/theme.dart';
import 'package:Audioverse/features/home/home_provider.dart';
import 'package:Audioverse/features/home/widgets/featured_carousel.dart';
import 'package:Audioverse/features/home/widgets/category_chips.dart';
import 'package:Audioverse/features/home/widgets/content_grid.dart';
import 'package:Audioverse/features/home/widgets/continue_listening_row.dart';
import 'package:Audioverse/features/home/widgets/shimmer_box.dart';
import 'package:Audioverse/features/content/providers/content_list_provider.dart';
import 'package:Audioverse/features/content/providers/categories_provider.dart';
import 'package:Audioverse/features/personalization/providers/favorites_provider.dart';
// import 'package:Audioverse/features/content/models/models.dart';

// HomeScreen
//
// Composes every Home widget into one scrollable surface:
//   SliverAppBar → Continue Listening → Featured Carousel → Category
//   Chips → Content Grid
//
// All four pieces of state (HomeProvider, ContentListProvider,
// CategoriesProvider) are loaded together on first open and refreshed
// together on pull-to-refresh, since from the user's point of view
// "refresh the home screen" means all of it, not just one section.
//
// home_screen.dart

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Deferred to after the first frame — providers call notifyListeners()
    // during their load, and doing that synchronously inside initState()
    // (before the widget tree has fully built) throws in debug mode.
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAll());
  }

  Future<void> _loadAll() async {
    final home = context.read<HomeProvider>();
    final categories = context.read<CategoriesProvider>();
    final contentList = context.read<ContentListProvider>();
    final favorites = context.read<FavoritesProvider>();
    // final history = context.read<HistoryProvider>();

    // All independent of each other — load concurrently rather than
    // waiting on each one in sequence.
    await Future.wait([
      home.loadHome(),
      categories.loadCategories(),
      contentList.load(),
      favorites.loadFavorites(),
      // history.loadContinueListening(),
    ]);
  }

  Future<void> _onRefresh() async {
    final home = context.read<HomeProvider>();
    final contentList = context.read<ContentListProvider>();
    final categories = context.read<CategoriesProvider>();
    // final favorites = context.read<FavoritesProvider>();
    final history = context.read<HistoryProvider>();

    // Categories rarely change — deliberately excluded from pull-to-refresh
    // so refreshing doesn't re-fetch data that's essentially static,
    // per the brief's "Re-fetch featured + content list" scope.
    await Future.wait([
      home.refresh(),
      contentList.load(filters: contentList.filters.copyWith(page: 1)),
      categories.loadCategories(),
      history.loadContinueListening(),
      // favorites.loadFavorites(),
    ]);
  }

  void _onCategorySelected(String? categoryId) {
    final contentList = context.read<ContentListProvider>();
    contentList.applyFilters(
      contentList.filters.copyWith(
        categoryId: categoryId,
        clearCategoryId: categoryId == null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      // top: false — the SliverAppBar's flexibleSpace draws into the
      // status bar area for the full-bleed look; only the bottom inset
      // (handled by MainScaffold's nav bar) matters here.
      bottom: false,
      child: Scaffold(
        backgroundColor: AppColors.darkBackground,
        body: RefreshIndicator(
          onRefresh: _onRefresh,
          color: AppColors.primaryLight,
          backgroundColor: AppColors.darkSurface,
          child: CustomScrollView(
            // Always allow overscroll so RefreshIndicator can trigger even
            // when content doesn't fill the screen (e.g. on first load
            // before any data has arrived).
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              _buildAppBar(),
              _buildContinueListeningSection(),
              _buildFeaturedSection(),
              _buildCategoryChips(),
              _buildContentGrid(),
              // Bottom padding so the last grid row isn't flush against
              // the bottom nav bar.
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
            ],
          ),
        ),
      ),
    );
  }

  // ── App Bar ──────────────────────────────────────────────────────────────
  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: AppColors.darkBackground,
      surfaceTintColor: Colors.transparent,
      pinned: true,
      title: Text(
        'Audioverse',
        style: AppTextStyles.displayMedium(AppColors.textPrimaryDark),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: AppColors.textPrimaryDark),
          onPressed: () {}, // TODO: wire to notifications screen
        ),
      ],
    );
  }

  // ── Continue Listening ──────────────────────────────────────────────────
  Widget _buildContinueListeningSection() {
    return Consumer<HistoryProvider>(
      builder: (context, history, _) {
        // Per the brief: this section is "only visible if history exists" —
        // while loading we still show the shimmer (so it doesn't pop in
        // abruptly), but once loaded with zero items, the entire section
        // including its header disappears rather than rendering empty.
        final showSection = history.isLoadingContinueListening || history.continueListening.isNotEmpty;

        if (!showSection) return const SliverToBoxAdapter(child: SizedBox.shrink());

        return SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.md),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text(
                  'Continue Listening',
                  style: AppTextStyles.titleLarge(AppColors.textPrimaryDark),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ContinueListeningRow(
                items: history.continueListening,
                isLoading: history.isLoadingContinueListening,
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Featured Carousel ───────────────────────────────────────────────────
  Widget _buildFeaturedSection() {
    return Consumer<HomeProvider>(
      builder: (context, home, _) {
        return SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.lg),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text(
                  'Featured',
                  style: AppTextStyles.titleLarge(AppColors.textPrimaryDark),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (home.isLoadingFeatured)
                const FeaturedCarouselSkeleton()
              else if (home.featured.isEmpty)
                const SizedBox.shrink() // nothing to feature — quietly skip
              else
                FeaturedCarousel(items: home.featured),
            ],
          ),
        );
      },
    );
  }

  // ── Category Chips ──────────────────────────────────────────────────────
  Widget _buildCategoryChips() {
    return Consumer2<CategoriesProvider, ContentListProvider>(
      builder: (context, categoriesProvider, contentListProvider, _) {
        if (categoriesProvider.isLoading) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }

        return SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: CategoryChips(
              categories: categoriesProvider.categories,
              selectedCategoryId: contentListProvider.filters.categoryId,
              onCategorySelected: _onCategorySelected,
            ),
          ),
        );
      },
    );
  }

  // ── Content Grid ─────────────────────────────────────────────────────────
  Widget _buildContentGrid() {
    return Consumer<ContentListProvider>(
      builder: (context, contentList, _) {
        return ContentGrid(
          items: contentList.items,
          isLoading: contentList.isLoading,
        );
      },
    );
  }
}
