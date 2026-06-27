import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Audioverse/core/theme/theme.dart';
import 'package:Audioverse/core/widgets/widgets.dart';
import 'package:Audioverse/features/profile/profile_provider.dart';
import 'package:Audioverse/features/profile/profile_stats.dart';
import 'widgets/avatar_picker.dart';
import 'widgets/editable_name_field.dart';
import 'widgets/profile_stats_row.dart';

// ProfileScreen
//
// DESIGN: large avatar set inside a dark gradient hero (echoes the
// ContentDetailScreen cover-art header and MiniPlayer's gradient
// theming, so Profile doesn't feel like a different app bolted on).
// Name/bio sit directly under the avatar with no card chrome — editing
// happens inline, in place, the way Spotify/Apple Music let you tap
// straight onto your own name rather than opening a separate "edit
// profile" form. Below the stats divider, account info becomes plain
// list rows (icon, label, value, chevron-less since these aren't
// navigable) — the settings-row pattern every major app uses for
// account details, instead of a second boxed card stacked under the first.
//
// Same two explicit gaps as before (avatar upload, stats endpoint) —
// see avatar_picker.dart / profile_stats.dart for full detail.
//
// profile_screen.dart

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _localAvatarPreview;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = context.read<ProfileProvider>();
      if (profile.profile == null && !profile.isLoading) {
        profile.loadProfile();
      }
    });
  }

  Future<void> _onAvatarSelected(File file) async {
    setState(() => _localAvatarPreview = file); // optimistic preview, instant

    try {
      await context.read<ProfileProvider>().updateAvatar(file);
      // Success — _localAvatarPreview can stay; profile.avatarUrl now
      // points at the same uploaded image anyway, so there's no visible
      // difference, and clearing it would just cause an unnecessary
      // network refetch of the image we already have on disk.
    } catch (_) {
      // Upload failed — roll back the optimistic preview so the avatar
      // reverts to whatever it was before this attempt, rather than
      // leaving the UI showing an image that was never actually saved.
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
    await context.read<ProfileProvider>().updateDisplayName(newName);
  }

  Future<void> _onBioSave(String newBio) async {
    await context.read<ProfileProvider>().updateBio(newBio);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Consumer<ProfileProvider>(
        builder: (context, profileProvider, _) {
          if (profileProvider.isLoading && profileProvider.profile == null) {
            return const Center(child: AppLoader());
          }

          if (profileProvider.errorMessage != null && profileProvider.profile == null) {
            return _ErrorState(
              message: profileProvider.errorMessage!,
              onRetry: profileProvider.loadProfile,
            );
          }

          final profile = profileProvider.profile!;

          return RefreshIndicator(
            onRefresh: profileProvider.loadProfile,
            color: AppColors.primaryLight,
            backgroundColor: AppColors.darkSurface,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                _buildHero(context, profile),
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
                        Text(
                          'ACCOUNT',
                          style: AppTextStyles.labelSmall(AppColors.textSecondaryDark)
                              .copyWith(letterSpacing: 1.2),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _SettingsRow(
                          icon: Icons.email_outlined,
                          label: 'Email',
                          value: profile.email ?? '—',
                        ),
                        _SettingsRow(
                          icon: Icons.calendar_today_outlined,
                          label: 'Member since',
                          value: _formatJoinDate(profile.createdAt),
                          showDivider: false,
                        ),
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

  // ── Hero header ────────────────────────────────────────────────────────
  //
  // SliverAppBar with a tall flexibleSpace gradient — avatar sits
  // centered, overlapping the gradient/background seam slightly via
  // negative-margin-style positioning, which is what gives this the
  // "the avatar belongs to the header, not the page below it" feel
  // that flat appbar-plus-card layouts don't achieve.
  Widget _buildHero(BuildContext context, profile) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 280,
      backgroundColor: AppColors.darkBackground,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AvatarPicker(
                  size: 104,
                  currentAvatarUrl: profile.avatarUrl,
                  localPreviewFile: _localAvatarPreview,
                  isUploading: context.watch<ProfileProvider>().isUploadingAvatar,
                  onImageSelected: _onAvatarSelected,
                ),
                const SizedBox(height: AppSpacing.md),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                  child: EditableNameField(
                    name: profile.displayName ?? '',
                    emptyPlaceholder: 'Add your name',
                    centered: true,
                    onSave: _onNameSave,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                  child: EditableNameField(
                    name: profile.bio ?? '',
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

// ── Settings-row pattern ─────────────────────────────────────────────────
//
// Plain icon + label + value row with a hairline divider underneath —
// the universal "account info" pattern (Settings apps, iOS Account
// screens). No card border around the whole group; the divider alone
// is enough structure, and it's quieter than wrapping everything in
// another bordered box right under the stats row above it.
class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
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
