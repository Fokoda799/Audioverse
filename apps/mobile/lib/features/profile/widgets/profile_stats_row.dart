import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Audioverse/core/theme/theme.dart';
import 'package:Audioverse/features/personalization/providers/favorites_provider.dart';
import 'package:Audioverse/features/profile/profile_stats.dart';

// ProfileStatsRow
//
// DESIGN NOTE: deliberately NOT three boxed cards with icons — that's
// the generic "stats widget" default. Big apps (Spotify, Apple Music)
// present profile stats as plain numbers with thin vertical dividers —
// the number's SIZE carries the weight, not a card/icon/border doing
// the work for it. Borrowing that here: three numbers, two hairline
// dividers, done.
//
// Favorites count is real (FavoritesProvider.favoritedIds.length).
// hoursListened/booksCompleted are stubbed at 0 — see profile_stats.dart.
//
// profile_stats_row.dart

class ProfileStatsRow extends StatelessWidget {
  const ProfileStatsRow({super.key, required this.stats});

  final ProfileStats stats;

  @override
  Widget build(BuildContext context) {
    return Consumer<FavoritesProvider>(
      builder: (context, favorites, _) {
        return Row(
          children: [
            Expanded(
              child: _Stat(value: _formatHours(stats.hoursListened), label: 'Hours'),
            ),
            _Divider(),
            Expanded(
              child: _Stat(value: '${stats.booksCompleted}', label: 'Completed'),
            ),
            _Divider(),
            Expanded(
              child: _Stat(value: '${favorites.favoritedIds.length}', label: 'Favorites'),
            ),
          ],
        );
      },
    );
  }

  String _formatHours(double hours) {
    if (hours < 1) return '0';
    return hours.toStringAsFixed(hours.truncateToDouble() == hours ? 0 : 1);
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.displayMedium(AppColors.textPrimaryDark)
              .copyWith(fontSize: 26),
        ),
        const SizedBox(height: 2),
        Text(
          label.toUpperCase(),
          style: AppTextStyles.labelSmall(AppColors.textSecondaryDark)
              .copyWith(letterSpacing: 0.8),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      color: AppColors.darkBorder,
    );
  }
}