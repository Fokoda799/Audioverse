// ── Author mini card ─────────────────────────────────────────────────────
//
// Avatar + name + a short bio snippet, tappable to push the author detail
// screen. The route is stubbed as a snackbar for now since there's no
// author detail screen/route in app_router.dart yet — swap _onTap's body
// for context.push('/home/author/${author.id}') (or wherever you mount
// it) once that screen exists.
//
// ASSUMPTION: ContentAuthor exposes `id` and `bio` fields. Only `.name`
// and `.avatarUrl` are used elsewhere in content_detail_screen.dart, so
// confirm these two fields actually exist on your ContentAuthor model —
// if `bio` isn't there yet, this card still renders fine and just omits
// the snippet line (see _hasBio below).

import 'package:Audioverse/core/theme/theme.dart';
import 'package:Audioverse/features/content/models/content_models.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class AuthorMiniCard extends StatelessWidget {
  const AuthorMiniCard({super.key, required this.author});

  final ContentAuthor author;

  bool get _hasBio => author.bio != null && author.bio!.trim().isNotEmpty;

  void _onTap(BuildContext context) {
    // TODO: replace once an author detail route exists.
    // context.push('/home/author/${author.id}');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Author page for ${author.name} — coming soon')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _onTap(context),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.darkBorder),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.full),
              child: author.avatarUrl != null
                  ? CachedNetworkImage(
                imageUrl: author.avatarUrl!,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => _AuthorAvatarFallback(),
              )
                  : _AuthorAvatarFallback(),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    author.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyLarge(AppColors.textPrimaryDark)
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  if (_hasBio) ...[
                    const SizedBox(height: 2),
                    Text(
                      author.bio!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium(AppColors.textSecondaryDark),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Icon(Icons.chevron_right_rounded,
                size: 20, color: AppColors.textSecondaryDark),
          ],
        ),
      ),
    );
  }
}

class _AuthorAvatarFallback extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      color: AppColors.darkBorder,
      child: const Icon(Icons.person_rounded,
          size: 24, color: AppColors.textSecondaryDark),
    );
  }
}