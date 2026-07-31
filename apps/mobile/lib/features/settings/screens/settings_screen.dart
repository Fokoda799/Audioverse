import 'package:url_launcher/url_launcher.dart';
import 'package:Audioverse/core/widgets/app_dialog.dart';
import 'package:Audioverse/core/widgets/app_snack_bar.dart';
import 'package:Audioverse/features/auth/auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Audioverse/core/utils/validators.dart';
import 'package:Audioverse/core/theme/theme.dart';
import 'package:Audioverse/features/settings/providers/settings_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final preferences = context.read<SettingsProvider>();
      if (preferences.preferences == null && !preferences.isLoading) {
        preferences.load();
      }
    });
  }

  Future<void> openTerms(String url) async {
    final uri = Uri.parse(url);

    final success = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!success) {
      throw Exception('Could not launch $uri');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Settings',
          style: AppTextStyles.titleLarge(AppColors.textPrimaryDark),
        ),
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          if (settings.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                strokeWidth: 2,
              ),
            );
          }

          if (settings.errorMessage != null) {
            AppSnackBar.show(
              context,
              message: settings.errorMessage!,
              type: AppSnackBarType.error,
            );
          }

          return ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            children: [
              // ── Playback ──────────────────────────────────────────────────
              const _SectionHeader(title: 'Playback'),
              _SettingsCard(
                children: [
                  _SpeedTile(settings: settings),
                  _Divider(),
                  _QualityTile(settings: settings),
                ],
              ),

              const SizedBox(height: AppSpacing.lg),

              // ── Notifications ─────────────────────────────────────────────
              const _SectionHeader(title: 'Notifications'),
              _SettingsCard(
                children: [
                  _NotificationToggleTile(
                    settings: settings,
                    notificationKey: 'new_releases',
                    icon: Icons.new_releases_outlined,
                    label: 'New releases',
                    subtitle: 'Get notified when new content is available',
                  ),
                  _Divider(),
                  _NotificationToggleTile(
                    settings: settings,
                    notificationKey: 'download_complete',
                    icon: Icons.download_outlined,
                    label: 'Download complete',
                    subtitle: 'Alert when offline content is ready',
                  ),
                  _Divider(),
                  _NotificationToggleTile(
                    settings: settings,
                    notificationKey: 'recommendations',
                    icon: Icons.recommend_outlined,
                    label: 'Recommendations',
                    subtitle: 'Personalized picks based on your listening',
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.lg),

              // ── About ─────────────────────────────────────────────────────
              const _SectionHeader(title: 'About'),
              _SettingsCard(
                children: [
                  const _InfoTile(label: 'Version', value: '1.0.0'),
                  _Divider(),
                  _TapTile(
                    icon: Icons.description_outlined,
                    label: 'Terms of Service',
                    onTap: () async {
                      await openTerms('https://audioverse.abdellahnaithadid.dev/terms');
                    },
                  ),
                  _Divider(),
                  _TapTile(
                    icon: Icons.privacy_tip_outlined,
                    label: 'Privacy Policy',
                    onTap: () async {
                      await openTerms('https://audioverse.abdellahnaithadid.dev/privacy');
                    },
                  ),
                  _Divider(),
                  _TapTile(
                    icon: Icons.mail_outline_rounded,
                    label: 'Contact Support',
                    onTap: () async {
                      await openTerms('https://audioverse.abdellahnaithadid.dev/conntact');
                    },
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.lg),

              if (auth.currentUser != null) _DeleteAccountButton(),

              const SizedBox(height: AppSpacing.xl),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Playback speed tile — horizontal chip row
// ─────────────────────────────────────────────────────────────────────────────

class _SpeedTile extends StatelessWidget {
  const _SpeedTile({required this.settings});
  final SettingsProvider settings;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.speed_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Default playback speed',
                style: AppTextStyles.bodyMedium(AppColors.textPrimaryDark),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: SettingsProvider.supportedSpeeds.map((speed) {
              final selected = settings.defaultPlaybackSpeed == speed;
              return GestureDetector(
                onTap: () => settings.setDefaultPlaybackSpeed(speed),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary : AppColors.darkSurface,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(
                      color: selected
                          ? AppColors.primary
                          : AppColors.darkBorder,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '${speed}x',
                    style: AppTextStyles.labelLarge(
                      selected
                          ? AppColors.darkBackground
                          : AppColors.textSecondaryDark,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Download quality tile — segmented control style
// ─────────────────────────────────────────────────────────────────────────────

class _QualityTile extends StatelessWidget {
  const _QualityTile({required this.settings});
  final SettingsProvider settings;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.download_outlined,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Download quality',
                style: AppTextStyles.bodyMedium(AppColors.textPrimaryDark),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            settings.downloadQuality!.description,
            style: AppTextStyles.labelSmall(AppColors.textSecondaryDark),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: DownloadQuality.values.map((q) {
              final selected = settings.downloadQuality == q;
              final isFirst = q == DownloadQuality.values.first;
              final isLast = q == DownloadQuality.values.last;
              return Expanded(
                child: GestureDetector(
                  onTap: () => settings.setDownloadQuality(q),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary
                          : AppColors.darkSurface,
                      borderRadius: BorderRadius.horizontal(
                        left: isFirst
                            ? const Radius.circular(AppRadius.sm)
                            : Radius.zero,
                        right: isLast
                            ? const Radius.circular(AppRadius.sm)
                            : Radius.zero,
                      ),
                      border: Border.all(
                        color: selected
                            ? AppColors.primary
                            : AppColors.darkBorder,
                        width: 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      q.label,
                      style: AppTextStyles.labelLarge(
                        selected
                            ? AppColors.darkBackground
                            : AppColors.textSecondaryDark,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Notification toggle tile — wired to provider
// ─────────────────────────────────────────────────────────────────────────────

class _NotificationToggleTile extends StatelessWidget {
  const _NotificationToggleTile({
    required this.settings,
    required this.notificationKey,
    required this.icon,
    required this.label,
    required this.subtitle,
  });

  final SettingsProvider settings;
  final String notificationKey;
  final IconData icon;
  final String label;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final isEnabled = settings.notifications[notificationKey] ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.bodyMedium(AppColors.textPrimaryDark),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.labelSmall(AppColors.textSecondaryDark),
                ),
              ],
            ),
          ),
          Switch(
            value: isEnabled,
            onChanged: (newValue) {
              final updatedNotifications = Map<String, bool>.from(
                settings.notifications,
              );
              updatedNotifications[notificationKey] = newValue;
              settings.setNotifications(updatedNotifications);
            },
            activeThumbColor: AppColors.primary,
            inactiveTrackColor: AppColors.darkBorder,
            thumbColor: const WidgetStatePropertyAll(
              AppColors.textSecondaryDark,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// About — read-only info row
// ─────────────────────────────────────────────────────────────────────────────

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodyMedium(AppColors.textPrimaryDark),
          ),
          Text(
            value,
            style: AppTextStyles.bodyMedium(AppColors.textSecondaryDark),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// About — tappable row with chevron
// ─────────────────────────────────────────────────────────────────────────────

class _TapTile extends StatelessWidget {
  const _TapTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodyMedium(AppColors.textPrimaryDark),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppColors.textSecondaryDark,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Logout button
// ─────────────────────────────────────────────────────────────────────────────

class _DeleteAccountButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _confirmDeleteAccount(context),
        icon: const Icon(Icons.delete, size: 18, color: AppColors.error),
        label: Text(
          'Delete your account',
          style: AppTextStyles.labelLarge(AppColors.error),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          side: const BorderSide(color: AppColors.error, width: 1),
          backgroundColor: AppColors.errorSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final confirmed = await showDialog(
        context: context,
        builder: (_) => const AppDialog(
          title: 'Delete Account',
          message: '''
Deleting your account will:

✓ Delete your profile
✓ Delete your comments
✓ Delete your likes
✓ Delete your reading/listening history
✓ Delete your Cloudinary uploads
✓ Cancel all active sessions

Your account can be restored within 30 days.
After that, everything is permanently deleted.
          ''',
          confirmText: 'Continue',
          validator: AppValidators.password,
        )
    );


    if (!context.mounted || !confirmed) return;

    final password = await showDialog(
      context: context,
      builder: (_) => const AppDialog(
        title: 'Delete Account',
        message: 'Enter your password to continue.',
        showInput: true,
        obscureText: true,
        hintText: 'Password',
        confirmText: 'Delete',
        validator: AppValidators.password,
      ),
    );

    if (!context.mounted || password == null) return;

    final auth = context.read<AuthProvider>();

    await auth.deleteAccount(password);

    if (!context.mounted) return;

    final errorMessage = auth.errorMessage;
    if (errorMessage != null) {
      AppSnackBar.show(
        context,
        message: errorMessage,
        type: AppSnackBarType.error,
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Layout helpers
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.xs,
        bottom: AppSpacing.sm,
      ),
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.labelSmall(AppColors.textSecondaryDark),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.darkBorder, width: 0.5),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 0.5,
      color: AppColors.darkBorder,
      indent: AppSpacing.md,
      endIndent: AppSpacing.md,
    );
  }
}
