// src/favorites/favorites.controller.ts

import {
  Controller,
  Get,
  Post,
  Delete,
  Param,
  Query,
  Request,
  UseGuards,
  ParseUUIDPipe,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { FavoritesService } from './favorites.service';
import { QueryFavoritesDto } from './dto/query-favorites.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { AuthGuard } from '@nestjs/passport';

@Controller('favorites')
@UseGuards(JwtAuthGuard) // every endpoint here requires a logged-in user
export class FavoritesController {
  constructor(private readonly favoritesService: FavoritesService) {}

  // ── POST /favorites/:contentId ────────────────────────────────────────────
  @Post(':contentId')
  @HttpCode(HttpStatus.OK)
  addFavorite(
    @Request() req: any,
    @Param('contentId', ParseUUIDPipe) contentId: string,
  ) {
    // req.user.sub is set by JwtStrategy.validate() — same pattern as
    // your refresh endpoint's req.user.sub usage.
    return this.favoritesService.addFavorite(req.user.sub, contentId);
  }

  // ── DELETE /favorites/:contentId ──────────────────────────────────────────
  @Delete(':contentId')
  removeFavorite(
    @Request() req: any,
    @Param('contentId', ParseUUIDPipe) contentId: string,
  ) {
    return this.favoritesService.removeFavorite(req.user.sub, contentId);
  }

  // ── GET /favorites ────────────────────────────────────────────────────────
  @Get()
  findAll(@Request() req: any, @Query() query: QueryFavoritesDto) {
    return this.favoritesService.findAll(req.user.sub, query);
  }
}
