import { Injectable, NotFoundException, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { UpsertHistoryDto } from './dto/upsert-history.dto';
import { QueryHistoryDto } from './dto/query-history.dto';

@Injectable()
export class HistoryService {
  private readonly logger = new Logger(HistoryService.name);

  constructor(private readonly prisma: PrismaService) {}

  // ── PATCH /history/:contentId ─────────────────────────────────────────────
  //
  // Upsert: the FIRST time a user plays something, there's no history row
  // yet — create handles that. Every call after that just updates position/
  // progress on the existing row. This is exactly the pattern your Flutter
  // AudioPlayerService would call periodically (e.g. every 10-15s of
  // playback) to checkpoint progress — it never needs to know whether this
  // is the first save or the hundredth.
  async upsert(userId: string, contentId: string, dto: UpsertHistoryDto) {
    const content = await this.prisma.audioContent.findUnique({
      where: { id: contentId },
      select: { id: true },
    });

    if (!content) {
      throw new NotFoundException(`Content "${contentId}" not found`);
    }

    const history = await this.prisma.listeningHistory.upsert({
      where: {
        userId_contentId: { userId, contentId },
      },
      create: {
        userId,
        contentId,
        positionSec: dto.positionSec,
        progressPercent: dto.progressPercent,
        completed: dto.completed ?? false,
        lastPlayedAt: new Date(),
      },
      update: {
        positionSec: dto.positionSec,
        progressPercent: dto.progressPercent,
        // Only update completed if explicitly provided — omitting it on
        // a routine progress-checkpoint call shouldn't accidentally flip
        // a previously-completed item back to false.
        ...(dto.completed !== undefined && { completed: dto.completed }),
        lastPlayedAt: new Date(), // always bump — this IS "last played now"
      },
    });

    return history;
  }

  // ── DELETE /history/:contentId ────────────────────────────────────────────
  //
  // "Remove from history" — e.g. a user wants to clear one item from their
  // continue-listening list without marking it complete.
  async remove(userId: string, contentId: string) {
    const result = await this.prisma.listeningHistory.deleteMany({
      where: { userId, contentId },
    });

    return { message: 'Removed from history', removed: result.count > 0 };
  }

  // ── GET /history ───────────────────────────────────────────────────────────
  //
  // Full listening history, paginated, sorted by lastPlayedAt DESC —
  // most recently played first, regardless of completed status. This
  // powers a "Listening History" screen (everything you've ever played),
  // distinct from "Continue Listening" (only unfinished items) below.
  async findAll(userId: string, query: QueryHistoryDto) {
    const { page = 1, limit = 10 } = query;
    const skip = (page - 1) * limit;

    const where = { userId }; // user isolation — same critical rule as Favorites

    const [total, items] = await Promise.all([
      this.prisma.listeningHistory.count({ where }),
      this.prisma.listeningHistory.findMany({
        where,
        skip,
        take: limit,
        orderBy: { lastPlayedAt: 'desc' },
        include: {
          content: {
            include: {
              author: { select: { id: true, name: true, avatarUrl: true } },
              category: { select: { id: true, name: true, slug: true } },
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

  // ── GET /history/continue-listening ───────────────────────────────────────
  //
  // Task 3 — the exact query your Flutter HomeProvider._loadContinueListening()
  // has been waiting on. No pagination here deliberately — the brief caps
  // this at "up to 10 items" as a fixed limit, since this is a small home-
  // screen widget, not a full paginated list like findAll() above.
  async getContinueListening(userId: string) {
    return this.prisma.listeningHistory.findMany({
      where: {
        userId,
        completed: false, // only unfinished items — this IS "continue listening"
      },
      orderBy: { lastPlayedAt: 'desc' },
      take: 10,
      include: {
        content: {
          include: {
            author: { select: { id: true, name: true, avatarUrl: true } },
          },
        },
      },
    });
  }
}
