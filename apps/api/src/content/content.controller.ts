import {
    Controller,
    Get,
    Post,
    Patch,
    Delete,
    Body,
    Param,
    Query,
    UseGuards,
    ParseUUIDPipe,
    HttpCode,
    HttpStatus,
    UseInterceptors,
    Request,
} from '@nestjs/common';
import { ContentService }    from './content.service';
import { CreateContentDto }  from './dto/create-content.dto';
import { UpdateContentDto }  from './dto/update-content.dto';
import { QueryContentDto }   from './dto/query-content.dto';
import { JwtAuthGuard }      from '../auth/guards/jwt-auth.guard';
import { AdminGuard }        from '@app/auth/guards/admin.guard';
import { CacheInterceptor, CacheTTL } from '@nestjs/cache-manager';

@Controller('content')
@UseInterceptors(CacheInterceptor)
export class ContentController {
    constructor(private readonly contentService: ContentService) {}

    // ── GET /content ───────────────────────────────────────────────────────────
    // Public — no auth required. Returns paginated, filterable content list.
    // Supports: ?search=&categoryId=&authorId=&contentType=&page=&limit=
    @Get()
    @CacheTTL(60)
    findAll(@Query() query: QueryContentDto, @Request() req: any) {
        return this.contentService.findAll(query, req.user?.sub);
    }

    // ── GET /content/search?q=midnight ────────────────────────────────────────
    // Public — for the search bar. Returns lightweight results fast.
    // IMPORTANT: This must be defined BEFORE /:id or NestJS will try to
    // parse "search" as a UUID and throw a validation error.
    @Get('search')
    @CacheTTL(30)
    search(
        @Query('q')     query: string,
        @Query('limit') limit?: number,
    ) {
        return this.contentService.search(query, limit);
    }

    @Get('featured')
    @HttpCode(HttpStatus.OK)
    @CacheTTL(300)
    getFeatured() {
        return this.contentService.getFeatured();
    }

    // ── GET /content/:id ───────────────────────────────────────────────────────
    // Public — returns full detail for a single content item.
    // ParseUUIDPipe validates the id format — throws 400 if it's not a valid UUID.
    @Get(':id')
    @CacheTTL(120)
    findOne(@Param('id', ParseUUIDPipe) id: string, @Request() req: any) {
        return this.contentService.findOne(id, req.user?.sub);
    }

    // ── POST /content ──────────────────────────────────────────────────────────
    // Admin only. Creates a new content record.
    // Audio and cover must already be uploaded to Cloudinary before calling this.
    @Post()
    @HttpCode(HttpStatus.CREATED)
    @UseGuards(JwtAuthGuard, AdminGuard)
    create(@Body() dto: CreateContentDto) {
        return this.contentService.create(dto);
    }

    // ── PATCH /content/:id ─────────────────────────────────────────────────────
    // Admin only. Updates any fields on a content record.
    // Only send the fields you want to change — everything else stays the same.
    @Patch(':id')
    @UseGuards(JwtAuthGuard, AdminGuard)
    update(
        @Param('id', ParseUUIDPipe) id:  string,
        @Body()                     dto: UpdateContentDto,
    ) {
        return this.contentService.update(id, dto);
    }

    // ── DELETE /content/:id/hard ───────────────────────────────────────────────
    // Permanent delete — only for GDPR requests or scheduled cleanup
    @Delete(':id/hard')
    @UseGuards(JwtAuthGuard, AdminGuard)
    hardDelete(@Param('id', ParseUUIDPipe) id: string) {
        return this.contentService.hardDelete(id);
    }

    // ── DELETE /content/:id ────────────────────────────────────────────────────
    // Soft delete — record is hidden but recoverable
    @Delete(':id')
    @UseGuards(JwtAuthGuard, AdminGuard)
    softDelete(@Param('id', ParseUUIDPipe) id: string) {
        return this.contentService.softDelete(id);
    }

    // ── POST /content/:id/restore ──────────────────────────────────────────────
// Undo a soft delete — makes the record visible again
    @Post(':id/restore')
    @UseGuards(JwtAuthGuard, AdminGuard)
    restore(@Param('id', ParseUUIDPipe) id: string) {
    return this.contentService.restore(id);
    }

    // ── POST /content/:id/play ─────────────────────────────────────────────────
    // Authenticated users. Call this when a user presses Play.
    // Atomically increments the play count.
    @Post(':id/play')
    @HttpCode(HttpStatus.OK)
    @UseGuards(JwtAuthGuard)
    incrementPlay(@Param('id', ParseUUIDPipe) id: string) {
        return this.contentService.incrementPlayCount(id);
    }
}
