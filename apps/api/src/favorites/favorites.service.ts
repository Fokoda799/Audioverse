// src/favorites/favorites.service.ts

import { Injectable, NotFoundException, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { QueryFavoritesDto } from './dto/query-favorites.dto';

@Injectable()
export class FavoritesService {
  private readonly logger = new Logger(FavoritesService.name);

  constructor(private readonly prisma: PrismaService) {}

  // ── POST /favorites/:contentId ────────────────────────────────────────────
  //
  // Upsert: if this user already favorited this content, do nothing and
  // return the existing row. This is what makes the endpoint safe to call
  // repeatedly — e.g. if the Flutter heart-icon tap fires twice due to a
  // double-tap, the second call doesn't throw a unique constraint error.
  async addFavorite(userId: string, contentId: string) {
    // Confirm the content actually exists first — gives a clear 404
    // instead of a cryptic FK constraint error from Postgres.
    const content = await this.prisma.audioContent.findUnique({
      where: { id: contentId },
      select: { id: true },
    });

    if (!content) {
      throw new NotFoundException(`Content "${contentId}" not found`);
    }

    const favorite = await this.prisma.favorite.upsert({
      where: {
        // Matches your schema's @@unique([userId, contentId]) —
        // Prisma exposes this composite key as userId_contentId automatically.
        userId_contentId: { userId, contentId },
      },
      create: { userId, contentId },
      update: {}, // already exists — nothing to change, just confirm it's there
    });

    this.logger.log(`User ${userId} favorited content ${contentId}`);
    return favorite;
  }

  // ── DELETE /favorites/:contentId ──────────────────────────────────────────
  //
  // Uses deleteMany (not delete) specifically so "unfavorite something
  // that was never favorited" returns gracefully instead of throwing.
  // delete() throws P2025 if the row doesn't exist; deleteMany() just
  // reports 0 rows affected — better fit for a toggle-style UI action
  // where the client might call this defensively without checking state first.
  async removeFavorite(userId: string, contentId: string) {
    const result = await this.prisma.favorite.deleteMany({
      where: { userId, contentId },
    });

    this.logger.log(
      `User ${userId} unfavorited content ${contentId} (removed: ${result.count})`,
    );

    return { message: 'Favorite removed', removed: result.count > 0 };
  }

  // ── GET /favorites ────────────────────────────────────────────────────────
  //
  // Paginated, with full AudioContent details joined — the brief says
  // "with content details joined" because the Flutter Library screen needs
  // cover art, title, duration etc. for each favorite, not just the
  // contentId. Doing this join here means the client never has to make
  // N additional requests to hydrate each favorite into something displayable.
  async findAll(userId: string, query: QueryFavoritesDto) {
    const { page = 1, limit = 10 } = query;
    const skip = (page - 1) * limit;

    // CRITICAL: every query in this service filters by userId — this is
    // what makes favorites private per-user. Forgetting this filter on
    // ANY method here is the single most damaging mistake possible in
    // this module, since it would leak one user's favorites to another.
    const where = { userId };

    const [total, items] = await Promise.all([
      this.prisma.favorite.count({ where }),
      this.prisma.favorite.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' }, // most recently favorited first
        include: {
          content: {
            include: {
              author: { select: { id: true, name: true, avatarUrl: true } },
              category: { select: { id: true, name: true, slug: true, colorHex: true } },
            },
          },
        },
      }),
    ]);

    return {
      items,
      meta: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  // ── Helper used by ContentService (see Task 4 below) ──────────────────────
  //
  // Returns the set of contentIds this user has favorited, scoped to a
  // specific list of contentIds — used to efficiently compute isFavorited
  // flags for a whole page of content results without N+1 queries.
  async getFavoritedContentIds(userId: string, contentIds: string[]): Promise<Set<string>> {
    if (contentIds.length === 0) return new Set();

    const favorites = await this.prisma.favorite.findMany({
      where: {
        userId,
        contentId: { in: contentIds },
      },
      select: { contentId: true },
    });

    return new Set(favorites.map((f) => f.contentId));
  }
}
