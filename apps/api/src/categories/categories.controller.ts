// src/categories/categories.controller.ts

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
  ParseIntPipe,
  DefaultValuePipe,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { CategoriesService }  from './categories.service';
import { CreateCategoryDto }  from './dto/create-category.dto';
import { UpdateCategoryDto }  from './dto/update-category.dto';
import { JwtAuthGuard }       from '../auth/guards/jwt-auth.guard';
import { UserRole }           from '@prisma/client';
import { AdminGuard } from '@app/auth/guards/admin.guard';

@Controller('categories')
export class CategoriesController {
  constructor(private readonly categoriesService: CategoriesService) {}

  // ── GET /categories ────────────────────────────────────────────────────────
  // Public. Returns all categories sorted by sortOrder.
  @Get()
  findAll() {
    return this.categoriesService.findAll();
  }

  // ── GET /categories/:slug/content ──────────────────────────────────────────
  // Public. Paginated content for a single category.
  // DefaultValuePipe + ParseIntPipe: converts query strings to numbers,
  // and provides sensible defaults if page/limit aren't passed.
  @Get(':slug/content')
  findContentBySlug(
    @Param('slug') slug: string,
    @Query('page',  new DefaultValuePipe(1))  page:  number,
    @Query('limit', new DefaultValuePipe(10)) limit: number,
  ) {
    return this.categoriesService.findContentBySlug(slug, page, limit);
  }

  // ── POST /categories ───────────────────────────────────────────────────────
  // Admin only.
  @Post()
  @HttpCode(HttpStatus.CREATED)
  @UseGuards(JwtAuthGuard, AdminGuard)
  create(@Body() dto: CreateCategoryDto) {
    return this.categoriesService.create(dto);
  }

  // ── PATCH /categories/:id ──────────────────────────────────────────────────
  // Admin only.
  @Patch(':id')
  @UseGuards(JwtAuthGuard, AdminGuard)
  update(
    @Param('id', ParseUUIDPipe) id:  string,
    @Body()                     dto: UpdateCategoryDto,
  ) {
    return this.categoriesService.update(id, dto);
  }

  // ── DELETE /categories/:id ─────────────────────────────────────────────────
  // Admin only. Blocked if the category still has content.
  @Delete(':id')
  @UseGuards(JwtAuthGuard, AdminGuard)
  delete(@Param('id', ParseUUIDPipe) id: string) {
    return this.categoriesService.delete(id);
  }
}
