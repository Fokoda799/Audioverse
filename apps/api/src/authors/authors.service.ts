import {
  Injectable,
  NotFoundException,
  ConflictException,
  Logger,
} from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService }    from '../prisma/prisma.service';
import { CreateAuthorDto }  from './dto/create-author.dto';
import { UpdateAuthorDto }  from './dto/update-author.dto';

@Injectable()
export class AuthorsService {
  private readonly logger = new Logger(AuthorsService.name);

  constructor(private readonly prisma: PrismaService) {}

  // ── findAll() ──────────────────────────────────────────────────────────────
  // Returns all authors — used for admin dropdowns when creating/editing content.
  async findAll() {
    return this.prisma.author.findMany({
      orderBy: { name: 'asc' },
    });
  }

  // ── findOne() ──────────────────────────────────────────────────────────────
  // GET /authors/:id — returns author details PLUS their published content list.
  // This is what the Flutter app calls for an "Author Profile" screen.
  async findOne(id: string) {
    const author = await this.prisma.author.findUnique({
      where: { id },
      include: {
        // Only show published content on the public author page —
        // drafts shouldn't be visible to regular users
        audioContent: {
          where:   { isPublished: true },
          orderBy: { createdAt: 'desc' },
          select: {
            id:          true,
            title:       true,
            slug:        true,
            coverUrl:    true,
            durationSec: true,
            contentType: true,
            playCount:   true,
          },
        },
      },
    });

    if (!author) {
      throw new NotFoundException(`Author with id "${id}" not found`);
    }

    return author;
  }

  // ── create() ───────────────────────────────────────────────────────────────
  // Admin only. Catches duplicate name errors from the unique constraint.
  async create(dto: CreateAuthorDto) {
    try {
      const author = await this.prisma.author.create({ data: dto });
      this.logger.log(`✅ Created author: "${author.name}" (${author.id})`);
      return author;

    } catch (error) {
      // P2002 = Prisma's unique constraint violation code
      if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === 'P2002') {
        throw new ConflictException(`Author "${dto.name}" already exists`);
      }
      throw error;
    }
  }

  // ── update() ───────────────────────────────────────────────────────────────
  // Admin only. Only the fields provided in the DTO are changed.
  async update(id: string, dto: UpdateAuthorDto) {
    await this.findOneById(id); // confirms existence, throws 404 if missing

    try {
      const updated = await this.prisma.author.update({
        where: { id },
        data:  dto,
      });

      this.logger.log(`✏️  Updated author: "${updated.name}" (${id})`);
      return updated;

    } catch (error) {
      if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === 'P2002') {
        throw new ConflictException(`Author "${dto.name}" already exists`);
      }
      throw error;
    }
  }

  // ── delete() ───────────────────────────────────────────────────────────────
  // Admin only. Blocked if the author still has any content (published or draft).
  //
  // NOTE: if you assigned content to the WRONG author by mistake, the fix is
  // PATCH /content/:id with the correct authorId — not deleting this author.
  // Once content is correctly reassigned, this author will have 0 items and
  // can be deleted safely.
  async delete(id: string) {
    const author = await this.findOneById(id);

    const contentCount = await this.prisma.audioContent.count({
      where: { authorId: id },
    });

    if (contentCount > 0) {
      throw new ConflictException(
        `Cannot delete "${author.name}" — they still have ${contentCount} content item(s). ` +
        `Reassign that content to another author first (PATCH /content/:id).`,
      );
    }

    await this.prisma.author.delete({ where: { id } });

    this.logger.log(`🗑️  Deleted author: "${author.name}" (${id})`);
    return { message: `Author "${author.name}" deleted successfully` };
  }

  // ── findOneById() ──────────────────────────────────────────────────────────
  // Internal helper used by update() and delete().
  private async findOneById(id: string) {
    const author = await this.prisma.author.findUnique({ where: { id } });

    if (!author) {
      throw new NotFoundException(`Author with id "${id}" not found`);
    }

    return author;
  }
}
