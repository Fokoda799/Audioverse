import 'package:Audioverse/core/theme/theme.dart';
import 'package:Audioverse/features/personalization/personalization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:Audioverse/features/personalization/models/history_model.dart';
import 'package:Audioverse/features/home/widgets/content_grid.dart';      // ContentCard
import 'package:Audioverse/features/home/widgets/empty_state.dart';        // EmptyState
import 'package:Audioverse/features/home/widgets/shimmer_box.dart';
import 'package:Audioverse/features/personalization/providers/history_provider.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Library',
          style: AppTextStyles.titleLarge(AppColors.textPrimaryDark),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          indicatorWeight: 2.5,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondaryDark,
          labelStyle: AppTextStyles.labelLarge(AppColors.primary),
          unselectedLabelStyle:
          AppTextStyles.labelLarge(AppColors.textSecondaryDark),
          dividerColor: AppColors.darkBorder,
          tabs: const [
            Tab(text: 'Continue'),
            Tab(text: 'History'),
            Tab(text: 'Favorites'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _ContinueListeningTab(),
          _HistoryTab(),
          _FavoritesTab(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 1 — Continue Listening
// Capped at 10 server-side; no pagination needed.
// ─────────────────────────────────────────────────────────────────────────────

class _ContinueListeningTab extends StatefulWidget {
  const _ContinueListeningTab();

  @override
  State<_ContinueListeningTab> createState() => _ContinueListeningTabState();
}

class _ContinueListeningTabState extends State<_ContinueListeningTab> {
  @override
  void initState() {
    super.initState();
    // Trigger load after first frame so the provider is ready.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HistoryProvider>().loadContinueListening();
    });
  }

  Future<void> _onRefresh() =>
      context.read<HistoryProvider>().loadContinueListening();

  @override
  Widget build(BuildContext context) {
    return Consumer<HistoryProvider>(
      builder: (context, provider, _) {
        if (provider.isLoadingContinueListening) {
          return _ContinueListeningSkeleton();
        }

        if (provider.continueListening.isEmpty) {
          return RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.darkSurface,
            onRefresh: _onRefresh,
            child: _scrollableEmpty(
              title: 'Nothing in progress',
              message:
              'Content you\'ve started but not finished will appear here.',
              icon: Icons.play_circle_outline_rounded,
            ),
          );
        }

        return RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.darkSurface,
          onRefresh: _onRefresh,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            itemCount: provider.continueListening.length,
            separatorBuilder: (_, __) =>
            const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final entry = provider.continueListening[index];
              return _HistoryCard(
                entry: entry,
                onTap: () =>
                    context.push('/home/content/${entry.content.id}'),
              );
            },
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 2 — History (infinite scroll)
// ─────────────────────────────────────────────────────────────────────────────

class _HistoryTab extends StatefulWidget {
  const _HistoryTab();

  @override
  State<_HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<_HistoryTab> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HistoryProvider>().load();
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<HistoryProvider>().loadMore();
    }
  }

  Future<void> _onRefresh() => context.read<HistoryProvider>().load();

  @override
  Widget build(BuildContext context) {
    return Consumer<HistoryProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return _HistoryTabSkeleton();
        }

        if (provider.items.isEmpty) {
          return RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.darkSurface,
            onRefresh: _onRefresh,
            child: _scrollableEmpty(
              title: 'No listening history',
              message: 'Everything you\'ve played will be tracked here.',
            icon: Icons.history_rounded,
            ),
          );
        }

        return RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.darkSurface,
          onRefresh: _onRefresh,
          child: ListView.separated(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            itemCount:
            provider.items.length + (provider.isLoadingMore ? 1 : 0),
            separatorBuilder: (_, __) =>
            const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              if (index == provider.items.length) {
                return const _LoadMoreIndicator();
              }
              final entry = provider.items[index];
              return _HistoryCard(
                entry: entry,
                onTap: () =>
                    context.push('/home/content/${entry.content.id}'),
              );
            },
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 3 — Favorites (paginated grid)
// ─────────────────────────────────────────────────────────────────────────────

class _FavoritesTab extends StatefulWidget {
  const _FavoritesTab();

  @override
  State<_FavoritesTab> createState() => _FavoritesTabState();
}

class _FavoritesTabState extends State<_FavoritesTab> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FavoritesProvider>().load();
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<FavoritesProvider>().loadMore();
    }
  }

  Future<void> _onRefresh() => context.read<FavoritesProvider>().load();

  @override
  Widget build(BuildContext context) {
    return Consumer<FavoritesProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return _FavoritesTabSkeleton();
        }

        if (provider.items.isEmpty) {
          return RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.darkSurface,
            onRefresh: _onRefresh,
            child: _scrollableEmpty(
              title: 'No saved content',
              message: 'Tap the bookmark icon on any content to save it here.',
              icon: Icons.bookmark_outline_rounded,
            ),
          );
        }

        return RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.darkSurface,
          onRefresh: _onRefresh,
          child: GridView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing: AppSpacing.sm,
              childAspectRatio: 0.72,
            ),
            itemCount:
            provider.items.length + (provider.isLoadingMore ? 2 : 0),
            itemBuilder: (context, index) {
              if (index >= provider.items.length) {
                return const ContentCardSkeleton();
              }
              final content = provider.items[index];
              return ContentCard(
                content: content,
              );
            },
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared card widget — used in Continue Listening + History
// ─────────────────────────────────────────────────────────────────────────────

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.entry,
    required this.onTap,
  });

  final History entry;
  final VoidCallback onTap;

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final content = entry.content;

    return Dismissible(
      key: ValueKey(content.id),
      direction: DismissDirection.horizontal,

      background: Container(
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),

      secondaryBackground: Container(
        decoration: BoxDecoration(
          color: Colors.amber,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(
          Icons.favorite,
          color: Colors.white,
        ),
      ),

      onDismissed: (_) async {

        // Call your backend
        await context.read<HistoryProvider>().removeFromHistory(content.id);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Removed from history'),
          ),
        );
      },
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.darkCard,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.darkBorder, width: 0.5),
          ),
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: Image.network(
                  content.coverUrl,
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 72,
                    height: 72,
                    color: AppColors.darkSurface,
                    child: const Icon(
                      Icons.image_not_supported_outlined,
                      color: AppColors.textSecondaryDark,
                      size: 24,
                    ),
                  ),
                ),
              ),
      
              const SizedBox(width: AppSpacing.sm),
      
              // Text + progress
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      content.title,
                      style:
                      AppTextStyles.bodyMedium(AppColors.textPrimaryDark),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
      
                    const SizedBox(height: AppSpacing.xs),
      
                    Text(
                      content.author?.name ?? '',
                      style: AppTextStyles.labelSmall(
                          AppColors.textSecondaryDark),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
      
                    const SizedBox(height: AppSpacing.sm),
      
                    // Progress bar
                    ClipRRect(
                      borderRadius:
                      BorderRadius.circular(AppRadius.xs),
                      child: LinearProgressIndicator(
                        value: entry.progressFraction.clamp(0.0, 1.0),
                        backgroundColor: AppColors.darkBorder,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          entry.completed
                              ? AppColors.accent
                              : AppColors.primary,
                        ),
                        minHeight: 3,
                      ),
                    ),
      
                    const SizedBox(height: AppSpacing.xs),
      
                    // Position + date
                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          entry.completed
                              ? 'Completed'
                              : _formatDuration(entry.positionSec),
                          style: AppTextStyles.labelSmall(
                            entry.completed
                                ? AppColors.accent
                                : AppColors.textSecondaryDark,
                          ),
                        ),
                        Text(
                          _formatDate(entry.lastPlayedAt),
                          style: AppTextStyles.labelSmall(
                              AppColors.textSecondaryDark),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Skeleton screens
// ─────────────────────────────────────────────────────────────────────────────

class _ContinueListeningSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _HistoryTabSkeleton();
}

class _HistoryTabSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, __) => Container(
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShimmerBox(width: 72, height: 72, borderRadius: AppRadius.sm),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(
                      width: double.infinity, height: 14, borderRadius: AppRadius.xs),
                  const SizedBox(height: AppSpacing.xs),
                  ShimmerBox(width: 120, height: 12, borderRadius: AppRadius.xs),
                  const SizedBox(height: AppSpacing.sm),
                  ShimmerBox(
                      width: double.infinity, height: 3, borderRadius: AppRadius.xs),
                  const SizedBox(height: AppSpacing.xs),
                  ShimmerBox(width: 80, height: 11, borderRadius: AppRadius.xs),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoritesTabSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        childAspectRatio: 0.72,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => const ContentCardSkeleton(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Wraps [EmptyState] in a single-child scroll view so
/// [RefreshIndicator] has something to drag against.
Widget _scrollableEmpty({
  required String title,
  required String message,
  required IconData icon,
}) {
  return LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: Center(
          child: EmptyState(title: title, message: message, icon: icon),
        ),
      ),
    ),
  );
}

class _LoadMoreIndicator extends StatelessWidget {
  const _LoadMoreIndicator();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor:
            AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ),
    );
  }
}
