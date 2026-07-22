import 'dart:io';
import 'package:Audioverse/core/audio/audio_player_service.dart';
import 'package:Audioverse/core/general/logout_data_cleaner.dart';
import 'package:Audioverse/features/auth/auth.dart';
import 'package:Audioverse/features/settings/providers/downloads_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:Audioverse/core/theme/theme.dart';
import 'package:Audioverse/core/widgets/widgets.dart';
import 'package:Audioverse/features/profile/profile_provider.dart';
import 'package:Audioverse/features/profile/profile_stats.dart';
import 'package:Audioverse/features/profile/widgets/avatar_picker.dart';
import 'package:Audioverse/features/profile/widgets/editable_name_field.dart';
import 'package:Audioverse/features/profile/widgets/profile_stats_row.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _localAvatarPreview;
  String? _lastLoadedUserId;

  void _loadProfileIfNeeded(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final currentUserId = auth.currentUser?.id;

    if (currentUserId == null) {
      _lastLoadedUserId = null;
      return;
    }

    if (currentUserId != _lastLoadedUserId) {
      _lastLoadedUserId = currentUserId;
      context.read<ProfileProvider>().loadProfile();
    }
  }

  Future<void> _onAvatarSelected(File file) async {
    setState(() => _localAvatarPreview = file); // optimistic preview, instant

    try {
      await context.read<ProfileProvider>().updateAvatar(file);
    } catch (_) {
      if (mounted) {
        setState(() => _localAvatarPreview = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.read<ProfileProvider>().errorMessage ?? 'Could not update avatar',
            ),
            backgroundColor: AppColors.errorSurface,
          ),
        );
      }
    }
  }

  Future<void> _onNameSave(String newName) async {
    await context.read<ProfileProvider>().updateInfo(displayName: newName);
  }

  Future<void> _onBioSave(String newBio) async {
    await context.read<ProfileProvider>().updateInfo(bio: newBio);
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: Text(
          'Log out?',
          style: AppTextStyles.titleLarge(AppColors.textPrimaryDark),
        ),
        content: Text(
          'You\'ll need to sign in again to access your library.',
          style: AppTextStyles.bodyMedium(AppColors.textSecondaryDark),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: AppTextStyles.labelLarge(AppColors.textSecondaryDark),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Log out',
              style: AppTextStyles.labelLarge(AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == false && !context.mounted) return;

    final logoutDataCleaner = context.read<LogoutDataCleaner>();
    final authProvider = context.read<AuthProvider>();
    final profileProvider = context.read<ProfileProvider>();
    final player = AudioPlayerService.instance;

    await logoutDataCleaner.clearUserData();
    await player.stopAndClear();
    await authProvider.logout();
    profileProvider.reset();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final isGuest = user == null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadProfileIfNeeded(context);
    });

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Consumer<ProfileProvider>(
        builder: (context, profileProvider, _) {
          if (!isGuest) {
            if (profileProvider.isLoading && profileProvider.profile == null) {
              return const Center(child: AppLoader());
            }

            if (profileProvider.errorMessage != null && profileProvider.profile == null) {
              return _ErrorState(
                message: profileProvider.errorMessage!,
                onRetry: profileProvider.loadProfile,
              );
            }
          }

          final profile = isGuest ? null : profileProvider.profile;

          return RefreshIndicator(
            onRefresh: isGuest
                ? () async {}
                : profileProvider.loadProfile,
            color: AppColors.primaryLight,
            backgroundColor: AppColors.darkSurface,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                isGuest ? _buildGuestHero(context) : _buildHero(context, profile),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.xxl,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ProfileStatsRow(stats: ProfileStats.stub()),
                        const SizedBox(height: AppSpacing.xl),
                        if (!isGuest) ...[
                          Text(
                            'ACCOUNT',
                            style: AppTextStyles.labelSmall(AppColors.textSecondaryDark)
                                .copyWith(letterSpacing: 1.2),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _SettingsRow(
                            icon: Icons.email_outlined,
                            label: 'Email',
                            value: user.email,
                          ),
                          _SettingsRow(
                            icon: Icons.calendar_today_outlined,
                            label: 'Member since',
                            value: _formatJoinDate(user.createdAt),
                            showDivider: true,
                          ),
                          const SizedBox(height: AppSpacing.xl),
                        ],
                        const _DownloadsCard(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Shared app bar actions ────────────────────────────────────────────
  //
  // One source of truth for the icon row, used by both hero variants via
  // SliverAppBar.actions — rendered by the AppBar itself (not layered
  // inside flexibleSpace), so these icons stay pinned in the collapsed
  // bar on scroll instead of disappearing with the rest of the hero.
  List<Widget> _heroActions(BuildContext context, {required bool showLogout}) {
    return [
      if (showLogout)
        IconButton(
          onPressed: () => _confirmLogout(context),
          icon: const Icon(Icons.logout),
        ),
      IconButton(
        onPressed: () => context.push('/settings'),
        icon: const Icon(Icons.settings),
      ),
    ];
  }

  // ── Guest hero ─────────────────────────────────────────────────────────
  Widget _buildGuestHero(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 280,
      backgroundColor: AppColors.darkBackground,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      actions: _heroActions(context, showLogout: false),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.primaryDark, AppColors.darkBackground],
              stops: [0.0, 0.85],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.darkCard,
                      border: Border.all(color: AppColors.darkBorder, width: 1.5),
                    ),
                    child: const Icon(
                      Icons.person_outline_rounded,
                      size: 44,
                      color: AppColors.textSecondaryDark,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'You\'re browsing as a guest',
                    style: AppTextStyles.titleLarge(AppColors.textPrimaryDark),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                    child: Text(
                      'Sign in to sync your library and listening progress across devices.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium(AppColors.textSecondaryDark),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    label: 'Sign In',
                    width: 300,
                    onPressed: () => context.push('/login'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Hero header (logged-in) ──────────────────────────────────────────
  Widget _buildHero(BuildContext context, profile) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 280,
      backgroundColor: AppColors.darkBackground,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      actions: _heroActions(context, showLogout: profile != null),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.primaryDark, AppColors.darkBackground],
              stops: [0.0, 0.85],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AvatarPicker(
                    size: 104,
                    currentAvatarUrl: profile?.avatarUrl,
                    localPreviewFile: _localAvatarPreview,
                    isUploading: context.watch<ProfileProvider>().isUploadingAvatar,
                    onImageSelected: _onAvatarSelected,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                    child: EditableNameField(
                      name: profile?.displayName ?? '',
                      emptyPlaceholder: 'Add your name',
                      centered: true,
                      onSave: _onNameSave,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                    child: EditableNameField(
                      name: profile?.bio ?? '',
                      emptyPlaceholder: 'Add a short bio',
                      maxLines: 2,
                      isSecondary: true,
                      centered: true,
                      onSave: _onBioSave,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatJoinDate(DateTime? date) {
    if (date == null) return '—';
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}

// ── Downloads card ───────────────────────────────────────────────────────
class _DownloadsCard extends StatelessWidget {
  const _DownloadsCard();

  @override
  Widget build(BuildContext context) {
    final count = context.watch<DownloadProvider>().downloads.length;

    return GestureDetector(
      onTap: () => context.push('/general'),
      child: AppCard(
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Icon(
                Icons.download_rounded,
                color: AppColors.accent,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Downloads',
                    style: AppTextStyles.bodyLarge(AppColors.textPrimaryDark)
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    count == 0 ? 'No offline audiobooks yet' : '$count saved for offline',
                    style: AppTextStyles.labelSmall(AppColors.textSecondaryDark),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondaryDark,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Settings-row pattern ─────────────────────────────────────────────────
class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
    this.showDivider = true,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppColors.textSecondaryDark),
                const SizedBox(width: AppSpacing.md),
                Text(label, style: AppTextStyles.bodyMedium(AppColors.textSecondaryDark)),
                const Spacer(),
                Text(value, style: AppTextStyles.bodyMedium(AppColors.textPrimaryDark)),
              ],
            ),
          ),
        ),
        if (showDivider) const Divider(height: 1, color: AppColors.darkBorder),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

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
            Text('Couldn\'t load your profile', style: AppTextStyles.titleLarge(AppColors.textPrimaryDark)),
            const SizedBox(height: AppSpacing.sm),
            Text(message, textAlign: TextAlign.center, style: AppTextStyles.bodyMedium(AppColors.textSecondaryDark)),
            const SizedBox(height: AppSpacing.lg),
            AppButton(label: 'Retry', onPressed: onRetry, variant: AppButtonVariant.secondary),
          ],
        ),
      ),
    );
  }
}
