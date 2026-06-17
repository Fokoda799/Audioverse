import {
  Injectable,
  NotFoundException,
  ConflictException,
  Logger,
} from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService }      from '../prisma/prisma.service';
import { CreateCategoryDto }  from './dto/create-category.dto';
import { UpdateCategoryDto }  from './dto/update-category.dto';

@Injectable()
export class CategoriesService {
  private readonly logger = new Logger(CategoriesService.name);

  constructor(private readonly prisma: PrismaService) {}

  // ── findAll() ──────────────────────────────────────────────────────────────
  // Returns every category sorted by sortOrder — this controls the
  // display order on the home screen / category list (admin-controlled).
  async findAll() {
    return this.prisma.category.findMany({
      orderBy: { sortOrder: 'asc' },
    });
  }

  // ── findOneBySlug() ────────────────────────────────────────────────────────
  // Used internally and by findContentBySlug() below.
  // Throws 404 if the slug doesn't match any category.
  async findOneBySlug(slug: string) {
    const category = await this.prisma.category.findUnique({
      where: { slug },
    });

    if (!category) {
      throw new NotFoundException(`Category "${slug}" not found`);
    }

    return category;
  }

  // ── findContentBySlug() ────────────────────────────────────────────────────
  // GET /categories/:slug/content — paginated list of published content
  // belonging to this category. This is what the Flutter app calls when
  // a user taps a category card.
  async findContentBySlug(slug: string, page = 1, limit = 10) {
    // Confirms the category exists first — gives a clear 404 if the slug is wrong
    const category = await this.findOneBySlug(slug);

    const skip = (page - 1) * limit;

    const [total, items] = await Promise.all([
      this.prisma.audioContent.count({
        where: { categoryId: category.id, isPublished: true },
      }),
      this.prisma.audioContent.findMany({
        where: { categoryId: category.id, isPublished: true },
        skip,
        take:    limit,
        orderBy: { createdAt: 'desc' },
        include: {
          author: { select: { id: true, name: true, avatarUrl: true } },
        },
      }),
    ]);

    return {
      category, // include category details so the client can show name/color/icon
      items,
      meta: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  // ── create() ───────────────────────────────────────────────────────────────
  // Admin only. Slug must be unique — Prisma throws a P2002 error if not,
  // which we catch and turn into a friendly 409 Conflict.
  async create(dto: CreateCategoryDto) {
    try {
      const category = await this.prisma.category.create({ data: dto });
      this.logger.log(`✅ Created category: "${category.name}" (${category.id})`);
      return category;

    } catch (error) {
      // P2002 = Prisma's unique constraint violation code
      if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === 'P2002') {
        throw new ConflictException(`Slug "${dto.slug}" is already in use`);
      }
      throw error; // anything else, let it bubble up as a 500
    }
  }

  // ── update() ───────────────────────────────────────────────────────────────
  // Admin only. Only the fields provided in the DTO are changed.
  async update(id: string, dto: UpdateCategoryDto) {
    // Confirm it exists first — gives a clean 404 instead of a Prisma error
    await this.findOneById(id);

    try {
      const updated = await this.prisma.category.update({
        where: { id },
        data:  dto, // Prisma ignores any fields that are undefined
      });

      this.logger.log(`✏️  Updated category: "${updated.name}" (${id})`);
      return updated;

    } catch (error) {
      if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === 'P2002') {
        throw new ConflictException(`Slug "${dto.slug}" is already in use`);
      }
      throw error;
    }
  }

  // ── delete() ───────────────────────────────────────────────────────────────
  // Admin only. Blocks deletion if any AudioContent still references this
  // category. Your schema already enforces this at the DB level via
  // `onDelete: Restrict` — we catch that error and turn it into a clear message.
  async delete(id: string) {
    const category = await this.findOneById(id);

    // Check upfront so we can give a more useful error message
    // (including the count) instead of just a generic DB error.
    const contentCount = await this.prisma.audioContent.count({
      where: { categoryId: id },
    });

    if (contentCount > 0) {
      throw new ConflictException(
        `Cannot delete "${category.name}" — it still has ${contentCount} content item(s). ` +
        `Move or delete that content first.`,
      );
    }

    await this.prisma.category.delete({ where: { id } });

    this.logger.log(`🗑️  Deleted category: "${category.name}" (${id})`);
    return { message: `Category "${category.name}" deleted successfully` };
  }

  // ── findOneById() ──────────────────────────────────────────────────────────
  // Internal helper used by update() and delete() to confirm existence.
  private async findOneById(id: string) {
    const category = await this.prisma.category.findUnique({ where: { id } });

    if (!category) {
      throw new NotFoundException(`Category with id "${id}" not found`);
    }

    return category;
  }
}