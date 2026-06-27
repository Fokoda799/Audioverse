import {
  Injectable,
  NotFoundException,
  ConflictException,
  Logger,
  Inject,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { StorageService } from '../storage/storage.service';
import { CreateContentDto } from './dto/create-content.dto';
import { UpdateContentDto } from './dto/update-content.dto';
import { QueryContentDto } from './dto/query-content.dto';
import { Cache } from 'cache-manager';
import { CACHE_MANAGER } from '@nestjs/cache-manager';

@Injectable()
export class ContentService {
  private readonly logger = new Logger(ContentService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly storage: StorageService,
    @Inject(CACHE_MANAGER) private readonly cache: Cache,
  ) {}

  // ── findAll() ──────────────────────────────────────────────────────────────
  //
  // Returns a paginated, filterable list of content.
  // Supports: search, categoryId, authorId, contentType, isPublished, page, limit
  async findAll(query: QueryContentDto) {
    const {
      search,
      categoryId,
      authorId,
      contentType,
      isPublished,
      page = 1,
      limit = 10,
    } = query;

    const skip = (page - 1) * limit;

    const where = {
      deletedAt: null,
      ...(search && {
        OR: [
          { title: { contains: search, mode: 'insensitive' as const } },
          { description: { contains: search, mode: 'insensitive' as const } },
        ],
      }),
      ...(categoryId && { categoryId }),
      ...(authorId && { authorId }),
      ...(contentType && { contentType }),
      ...(isPublished !== undefined && { isPublished }),
    };

    const [total, items] = await Promise.all([
      this.prisma.audioContent.count({ where }), // ✅ total reflects the FILTERED set
      this.prisma.audioContent.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: {
          author: { select: { id: true, name: true, avatarUrl: true } },
          category: {
            select: { id: true, name: true, slug: true, colorHex: true },
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
        hasNextPage: page < Math.ceil(total / limit),
        hasPrevPage: page > 1,
      },
    };
  }

  // ── findOne() ──────────────────────────────────────────────────────────────
  //
  // Returns a single content item by ID with full details.
  // Throws 404 if it doesn't exist.
  async findOne(id: string) {
    const content = await this.prisma.audioContent.findUnique({
      where: { id, deletedAt: null },
      include: {
        author: true,
        category: true,
      },
    });

    if (!content) {
      throw new NotFoundException(`Content with id "${id}" not found`);
    }

    return content;
  }

  // ── search() ───────────────────────────────────────────────────────────────
  //
  // Dedicated search endpoint — faster and simpler than findAll() with a search param.
  // Used for the search bar — returns lightweight results (no full description).
  async search(query: string, limit = 10) {
    if (!query || query.trim().length < 2) {
      return [];
    }

    return this.prisma.audioContent.findMany({
      where: {
        isPublished: true,
        OR: [
          { title: { contains: query, mode: 'insensitive' } },
          { description: { contains: query, mode: 'insensitive' } },
        ],
      },
      take: limit,
      select: {
        id: true,
        title: true,
        slug: true,
        coverUrl: true,
        durationSec: true,
        contentType: true,
        playCount: true,
        author: { select: { id: true, name: true } },
        category: { select: { id: true, name: true, colorHex: true } },
      },
      orderBy: { playCount: 'desc' },
    });
  }

  async getFeatured() {
    return await this.prisma.audioContent.findMany({
      orderBy: { playCount: 'desc' },
      take: 10,
    });
  }

  // ── create() ───────────────────────────────────────────────────────────────
  //
  // Creates a new AudioContent record in the database.
  // The audio and cover files should already be uploaded to Cloudinary
  // before calling this — the DTO just receives their publicIds.
  async create(dto: CreateContentDto) {
    const existing = await this.prisma.audioContent.findUnique({
      where: { slug: dto.slug },
      select: { id: true },
    });

    if (existing) {
      throw new ConflictException(`Slug "${dto.slug}" is already in use`);
    }

    const content = await this.prisma.audioContent.create({
      data: {
        title: dto.title,
        slug: dto.slug,
        description: dto.description,
        coverUrl: dto.coverUrl,
        audioUrl: dto.audioUrl,
        durationSec: dto.durationSec,
        contentType: dto.contentType,
        language: dto.language ?? 'en',
        isPublished: dto.isPublished ?? false,
        playCount: 0,
        authorId: dto.authorId,
        categoryId: dto.categoryId,
      },
      include: {
        author: { select: { id: true, name: true } },
        category: { select: { id: true, name: true } },
      },
    });

    this.logger.log(`✅ Created content: "${content.title}" (${content.id})`);
    return content;
  }

  // ── update() ───────────────────────────────────────────────────────────────
  //
  // Updates any fields on an existing content record.
  // Only the fields provided in the DTO are updated — everything else stays the same.
  // If a new audioUrl or coverUrl is provided, the OLD file is deleted from Cloudinary.
  async update(id: string, dto: UpdateContentDto) {
    const existing = await this.findOne(id);

    if (dto.audioUrl && dto.audioUrl !== existing.audioUrl) {
      await this.storage.deleteAudio(existing.audioUrl);
      this.logger.log(`🗑️  Deleted old audio: ${existing.audioUrl}`);
    }

    if (dto.coverUrl && dto.coverUrl !== existing.coverUrl) {
      await this.storage.deleteCover(existing.coverUrl);
      this.logger.log(`🗑️  Deleted old cover: ${existing.coverUrl}`);
    }

    // If slug is being changed, check the new slug isn't already taken
    if (dto.slug && dto.slug !== existing.slug) {
      const slugTaken = await this.prisma.audioContent.findUnique({
        where: { slug: dto.slug },
        select: { id: true },
      });

      if (slugTaken) {
        throw new ConflictException(`Slug "${dto.slug}" is already in use`);
      }
    }

    const updated = await this.prisma.audioContent.update({
      where: { id },
      data: {
        ...(dto.title !== undefined && { title: dto.title }),
        ...(dto.slug !== undefined && { slug: dto.slug }),
        ...(dto.description !== undefined && { description: dto.description }),
        ...(dto.coverUrl !== undefined && { coverUrl: dto.coverUrl }),
        ...(dto.audioUrl !== undefined && { audioUrl: dto.audioUrl }),
        ...(dto.durationSec !== undefined && { durationSec: dto.durationSec }),
        ...(dto.contentType !== undefined && { contentType: dto.contentType }),
        ...(dto.language !== undefined && { language: dto.language }),
        ...(dto.isPublished !== undefined && { isPublished: dto.isPublished }),
        ...(dto.authorId !== undefined && { authorId: dto.authorId }),
        ...(dto.categoryId !== undefined && { categoryId: dto.categoryId }),
      },
      include: {
        author: { select: { id: true, name: true } },
        category: { select: { id: true, name: true } },
      },
    });

    await this.cache.del(`/content/${id}`);

    this.logger.log(`✏️  Updated content: "${updated.title}" (${id})`);
    return updated;
  }

  // ── delete() ───────────────────────────────────────────────────────────────
  //
  // Deletes the content record from the database AND both files from Cloudinary.
  // This is permanent. The related ListeningHistory and Favorite rows are deleted
  // automatically by Postgres via the onDelete: Cascade rules in your schema.
  async hardDelete(id: string) {
    const content = await this.findOne(id);

    await Promise.all([
      this.storage.deleteAudio(content.audioUrl),
      this.storage.deleteCover(content.coverUrl),
    ]);

    await this.prisma.audioContent.delete({ where: { id } });
    await this.cache.del(`/content/${id}`);
    await this.cache.del('/content');

    this.logger.log(`🗑️  Deleted content: "${content.title}" (${id})`);

    return { message: `Content "${content.title}" deleted successfully` };
  }

  // ── delete() — NOW a soft delete ───────────────────────────────────────────
  // Instead of removing the row, we just stamp deletedAt with the current time.
  // The files in Cloudinary are kept too — we can restore everything if needed.
  async softDelete(id: string) {
    // Confirm the record exists first
    const content = await this.findOne(id);

    // Set deletedAt to NOW — this is the entire "delete" operation
    await this.prisma.audioContent.update({
      where: { id },
      data: { deletedAt: new Date() },
    });

    this.logger.log(`🗑️  Soft deleted: "${content.title}" (${id})`);

    return { message: `"${content.title}" has been deleted` };
  }

  // ── restore() — NEW: undo a soft delete ────────────────────────────────────
  // This is the superpower of soft delete — you can bring things back.
  // Just set deletedAt back to null and the record reappears everywhere.
  async restore(id: string) {
    // Use findFirst without the deletedAt: null filter
    // because we specifically WANT to find deleted records here
    const content = await this.prisma.audioContent.findFirst({
      where: { id, deletedAt: { not: null } },
    });

    if (!content) {
      throw new NotFoundException(`No deleted content found with id "${id}"`);
    }

    const restored = await this.prisma.audioContent.update({
      where: { id },
      data: { deletedAt: null },
    });

    this.logger.log(`♻️  Restored: "${restored.title}" (${id})`);
    return restored;
  }

  // ── incrementPlayCount() ───────────────────────────────────────────────────
  //
  // Called every time a user starts playing a content item.
  // Uses Prisma's atomic increment to avoid race conditions —
  // if 100 users press play at the same time, all 100 increments are counted.
  async incrementPlayCount(id: string) {
    return this.prisma.audioContent.update({
      where: { id },
      data: { playCount: { increment: 1 } }, // atomic — safe for concurrent requests
      select: { id: true, playCount: true }, // only return what changed
    });
  }
}
