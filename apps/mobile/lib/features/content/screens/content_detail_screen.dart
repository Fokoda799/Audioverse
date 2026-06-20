import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:Audioverse/core/theme/theme.dart';
import 'package:Audioverse/core/widgets/app_loader.dart';
import 'package:Audioverse/core/widgets/app_button.dart';
import 'package:Audioverse/features/content/providers/content_detail_provider.dart';
import 'package:Audioverse/features/home/widgets/empty_state.dart';

// ContentDetailScreen
//
// Full detail page for a single content item: cover, title, author,
// category, description, and a Play button. Reached via
// /home/content/:id (see app_router.dart) — pushed on top of Home's
// own stack, so the back arrow returns to Home.
//
// This screen owns its OWN ContentDetailProvider instance, scoped to
// contentId — that's why the Provider is created HERE rather than
// higher up the tree (unlike HomeProvider/ContentListProvider, which
// are app-wide and live above the router). Navigating to a different
// content id creates a fresh provider instance automatically, since
// go_router gives this widget a new key per id.
//
// PLAYBACK: no audio player is wired up yet. The Play button currently
// only fetches a signed stream URL via ContentDetailProvider.getStreamUrl()
// and shows it in a snackbar as a placeholder — swap _onPlayPressed's
// body for your real player (e.g. just_audio) once that's in place.
//
// FAVORITES: the heart icon calls FavoriteRepository, which does not
// exist yet in this codebase. _FavoriteButton below is built against
// a small interface so the UI is ready the moment that repository
// lands — see the FavoriteRepository stub at the bottom of this file.
//
// content_detail_screen.dart

class ContentDetailScreen extends StatelessWidget {
  const ContentDetailScreen({super.key, required this.contentId});

  final String contentId;

  @override
  Widget build(BuildContext context) {
    // ContentDetailProvider is already created and triggered to load
    // in the app_router.dart's pageBuilder.
    return const _ContentDetailView();
  }
}

class _ContentDetailView extends StatelessWidget {
  const _ContentDetailView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Consumer<ContentDetailProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: AppLoader());
          }

          if (provider.errorMessage != null && provider.content == null) {
            return _ErrorView(
              message: provider.errorMessage!,
              onRetry: provider.loadContent,
            );
          }

          final content = provider.content!;

          return CustomScrollView(
            slivers: [
              _buildHeader(context, provider),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTitleRow(content),
                      const SizedBox(height: AppSpacing.xs),
                      if (content.author != null) _buildAuthorRow(content),
                      const SizedBox(height: AppSpacing.lg),
                      _buildPlayButton(context, provider),
                      const SizedBox(height: AppSpacing.lg),
                      _buildMetaChips(content),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Description',
                        style: AppTextStyles.titleLarge(AppColors.textPrimaryDark),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        content.description ?? '',
                        style: AppTextStyles.bodyMedium(AppColors.textSecondaryDark),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Cover art header with back button + favorite ────────────────────────
  Widget _buildHeader(BuildContext context, ContentDetailProvider provider) {
    final content = provider.content!;

    return SliverAppBar(
      pinned: true,
      expandedHeight: 320,
      backgroundColor: AppColors.darkBackground,
      surfaceTintColor: Colors.transparent,
      leading: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: _CircleIconButton(
          icon: Icons.arrow_back_rounded,
          onTap: () => context.pop(),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: AppSpacing.md, top: AppSpacing.sm, bottom: AppSpacing.sm),
          child: _FavoriteButton(contentId: content.id),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: content.coverUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(color: AppColors.darkCard),
              errorWidget: (context, url, error) => Container(
                color: AppColors.darkCard,
                child: const Icon(Icons.image_not_supported_outlined,
                    color: AppColors.textSecondaryDark, size: 48),
              ),
            ),
            // Gradient so the SliverAppBar's back/favorite buttons and the
            // page background beneath stay legible against any cover art.
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    Colors.transparent,
                    AppColors.darkBackground,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleRow(content) {
    return Text(
      content.title,
      style: AppTextStyles.displayMedium(AppColors.textPrimaryDark),
    );
  }

  Widget _buildAuthorRow(content) {
    return Row(
      children: [
        if (content.author!.avatarUrl != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: CachedNetworkImage(
              imageUrl: content.author!.avatarUrl!,
              width: 24,
              height: 24,
              fit: BoxFit.cover,
              errorWidget: (context, url, error) => Container(
                width: 24,
                height: 24,
                color: AppColors.darkCard,
              ),
            ),
          ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          content.author!.name,
          style: AppTextStyles.bodyLarge(AppColors.textSecondaryDark),
        ),
      ],
    );
  }

  // ── Play button ───────────────────────────────────────────────────────────
  // No audio player is wired up yet — this fetches the signed stream URL
  // and shows it as a snackbar placeholder. Replace the body of
  // _onPlayPressed with your real player integration when ready.
  Widget _buildPlayButton(BuildContext context, ContentDetailProvider provider) {
    return AppButton(
      label: 'Play',
      icon: const Icon(Icons.play_arrow_rounded),
      isLoading: provider.isLoadingStream,
      width: double.infinity,
      onPressed: () => _onPlayPressed(context, provider),
    );
  }

  Future<void> _onPlayPressed(BuildContext context, ContentDetailProvider provider) async {
    final url = await provider.getStreamUrl();

    if (!context.mounted) return;

    if (url == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Could not load audio'),
          backgroundColor: AppColors.errorSurface,
        ),
      );
      return;
    }

    // TODO: replace with real playback once a player (e.g. just_audio)
    // is wired up. For now this just confirms the signed URL was fetched.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Stream URL ready — player not wired up yet'),
        backgroundColor: AppColors.darkCard,
      ),
    );
  }

  // ── Category + duration chips ────────────────────────────────────────────
  Widget _buildMetaChips(content) {
    return Wrap(
      spacing: AppSpacing.sm,
      children: [
        if (content.category != null)
          _MetaChip(
            icon: Icons.category_outlined,
            label: content.category!.name,
          ),
        _MetaChip(
          icon: Icons.access_time_rounded,
          label: content.formattedDuration,
        ),
        _MetaChip(
          icon: Icons.headphones_rounded,
          label: '${content.playCount} plays',
        ),
      ],
    );
  }
}

// ── Small reusable pieces ──────────────────────────────────────────────────

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.4),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondaryDark),
          const SizedBox(width: 4),
          Text(label, style: AppTextStyles.labelSmall(AppColors.textSecondaryDark)),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const EmptyState(
              icon: Icons.error_outline_rounded,
              title: 'Couldn\'t load this',
              message: 'Check your connection and try again.',
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: 'Retry',
              variant: AppButtonVariant.secondary,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Favorite button ─────────────────────────────────────────────────────────
//
// Built against FavoriteRepository (stub below) since that repository
// doesn't exist in the codebase yet. The UI is fully wired and ready —
// once a real FavoriteRepository + FavoriteProvider are built (mirroring
// the pattern used for ContentRepository/ContentDetailProvider), swap
// this widget's direct repository call for a proper provider the same
// way every other screen in the app does it.
class _FavoriteButton extends StatefulWidget {
  const _FavoriteButton({required this.contentId});

  final String contentId;

  @override
  State<_FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<_FavoriteButton> {
  bool _isFavorited = false;
  bool _isLoading = false;

  Future<void> _toggle() async {
    setState(() => _isLoading = true);

    try {
      // FavoriteRepository does not exist yet — this call will fail to
      // resolve until that repository is built and provided above this
      // widget in the tree. Left as a direct, explicit failure point
      // rather than a fake optimistic toggle that silently does nothing.
      final repository = context.read<FavoriteRepository>();
      if (_isFavorited) {
        await repository.removeFavorite(widget.contentId);
      } else {
        await repository.addFavorite(widget.contentId);
      }
      setState(() => _isFavorited = !_isFavorited);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not update favorite')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isLoading ? null : _toggle,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.4),
          shape: BoxShape.circle,
        ),
        child: Icon(
          _isFavorited ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          color: _isFavorited ? AppColors.error : Colors.white,
          size: 20,
        ),
      ),
    );
  }
}

// ── FavoriteRepository (STUB — not implemented) ─────────────────────────────
//
// Placeholder interface only, so _FavoriteButton above compiles and the
// UI is ready to wire up. Replace with a real implementation that calls
// your NestJS Favorite endpoints (POST/DELETE /content/:id/favorite or
// similar) once that backend route exists.
abstract class FavoriteRepository {
  Future<void> addFavorite(String contentId);
  Future<void> removeFavorite(String contentId);
  Future<bool> isFavorited(String contentId);
}
