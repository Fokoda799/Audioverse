// src/authors/authors.controller.ts

import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Body,
  Param,
  UseGuards,
  ParseUUIDPipe,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { AuthorsService }    from './authors.service';
import { CreateAuthorDto }   from './dto/create-author.dto';
import { UpdateAuthorDto }   from './dto/update-author.dto';
import { JwtAuthGuard }      from '../auth/guards/jwt-auth.guard';
import { UserRole }          from '@prisma/client';
import { AdminGuard } from '@app/auth/guards/admin.guard';

@Controller('authors')
export class AuthorsController {
  constructor(private readonly authorsService: AuthorsService) {}

  // ── GET /authors ───────────────────────────────────────────────────────────
  // Public. Used for admin dropdowns and browsing all authors.
  @Get()
  findAll() {
    return this.authorsService.findAll();
  }

  // ── GET /authors/:id ───────────────────────────────────────────────────────
  // Public. Returns author details + their published content list.
  @Get(':id')
  findOne(@Param('id', ParseUUIDPipe) id: string) {
    return this.authorsService.findOne(id);
  }

  // ── POST /authors ──────────────────────────────────────────────────────────
  // Admin only.
  @Post()
  @HttpCode(HttpStatus.CREATED)
  @UseGuards(JwtAuthGuard, AdminGuard)
  create(@Body() dto: CreateAuthorDto) {
    return this.authorsService.create(dto);
  }

  // ── PATCH /authors/:id ─────────────────────────────────────────────────────
  // Admin only.
  @Patch(':id')
  @UseGuards(JwtAuthGuard, AdminGuard)
  update(
    @Param('id', ParseUUIDPipe) id:  string,
    @Body()                     dto: UpdateAuthorDto,
  ) {
    return this.authorsService.update(id, dto);
  }

  // ── DELETE /authors/:id ────────────────────────────────────────────────────
  // Admin only. Blocked if the author still has content.
  @Delete(':id')
  @UseGuards(JwtAuthGuard, AdminGuard)
  delete(@Param('id', ParseUUIDPipe) id: string) {
    return this.authorsService.delete(id);
  }
}
