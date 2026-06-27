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
  async addFavorite(profileId: string, contentId: string) {
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
        userId_contentId: { userId: profileId, contentId },
      },
      create: { userId: profileId, contentId },
      update: {}, // already exists — nothing to change, just confirm it's there
    });

    this.logger.log(`Profile ${profileId} favorited content ${contentId}`);
    return favorite;
  }

  // ── DELETE /favorites/:contentId ──────────────────────────────────────────
  //
  // Uses deleteMany (not delete) specifically so "unfavorite something
  // that was never favorited" returns gracefully instead of throwing.
  // delete() throws P2025 if the row doesn't exist; deleteMany() just
  // reports 0 rows affected — better fit for a toggle-style UI action
  // where the client might call this defensively without checking state first.
  async removeFavorite(profileId: string, contentId: string) {
    const result = await this.prisma.favorite.deleteMany({
      where: { userId: profileId, contentId },
    });

    this.logger.log(
      `Profile ${profileId} unfavorited content ${contentId} (removed: ${result.count})`,
    );

    return { message: 'Favorite removed', removed: result.count > 0 };
  }

  // ── GET /favorites/ids ────────────────────────────────────────────────────
  //
  // Lightweight endpoint for the app-wide heart state cache.
  // Returns only content ids, so the client can populate its Set<string>
  // without paginating through every favorite content record.
  async findIds(profileId: string) {
    const favorites = await this.prisma.favorite.findMany({
      where: { userId: profileId },
      select: { contentId: true },
    });

    return favorites.map((favorite) => favorite.contentId);
  }

  // ── GET /favorites ────────────────────────────────────────────────────────
  //
  // Paginated favorite content list with full AudioContent details joined.
  async findAll(userId: string, query: QueryFavoritesDto) {
    const { page = 1, limit = 10 } = query;
    const skip = (page - 1) * limit;

    // CRITICAL: every query in this service filters by userId — this is
    // what makes favorites private per-user. Forgetting this filter on
    // ANY method here is the single most damaging mistake possible in
    // this module, since it would leak one user's favorites to another.
    const where = {
      userId,
      content: {
        deletedAt: null,
      },
    };

    const [total, favorites] = await Promise.all([
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
            },
          },
        },
      }),
    ]);

    return {
      items: favorites.map((favorite) => favorite.content),
      meta: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
      },
    };
  }
}
