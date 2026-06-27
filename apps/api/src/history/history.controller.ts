import {
  Controller,
  Get,
  Patch,
  Delete,
  Param,
  Body,
  Query,
  Request,
  UseGuards,
  ParseUUIDPipe,
} from '@nestjs/common';
import { HistoryService } from './history.service';
import { UpsertHistoryDto } from './dto/upsert-history.dto';
import { QueryHistoryDto } from './dto/query-history.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { ProfileService } from '@app/profile/profile.service';

@Controller('history')
@UseGuards(JwtAuthGuard)
export class HistoryController {
  constructor(
    private readonly historyService: HistoryService,
  ) {}

  // ── GET /history/continue-listening ───────────────────────────────────────
  //
  // MUST be declared BEFORE any ':contentId' style route in this controller
  // — otherwise NestJS would try to parse "continue-listening" as a contentId
  // path param on a route like GET /history/:contentId, if one existed.
  // (We don't have one here, but this ordering rule is worth remembering
  // for future routes in this controller.)
  @Get('continue-listening')
  getContinueListening(@Request() req: any) {
    return this.historyService.getContinueListening(req.user.sub);
  }

  // ── GET /history ────────────────────────────────────────────────────────
  @Get()
  findAll(@Request() req: any, @Query() query: QueryHistoryDto) {
    return this.historyService.findAll(req.user.sub, query);
  }

  @Get(':id')
  getPositionSec(@Param('id') id: string, @Request() req: any) {
    return this.historyService.getPositionSec(id, req.user.id);
  }

  // ── PATCH /history/:contentId ─────────────────────────────────────────────
  @Patch(':contentId')
  upsert(
    @Request() req: any,
    @Param('contentId', ParseUUIDPipe) contentId: string,
    @Body() dto: UpsertHistoryDto,
  ) {
    return this.historyService.upsert(req.user.sub, contentId, dto);
  }

  // ── DELETE /history/:contentId ────────────────────────────────────────────
  @Delete(':contentId')
  remove(@Request() req: any, @Param('contentId', ParseUUIDPipe) contentId: string) {
    return this.historyService.remove(req.user.sub, contentId);
  }
}
