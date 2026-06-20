import {
  Controller,
  Post,
  Get,
  Param,
  UploadedFile,
  UseGuards,
  UseInterceptors,
  ParseUUIDPipe,
  HttpCode,
  HttpStatus,
  NotFoundException,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { StorageService } from './storage.service';
import { PrismaService } from '../prisma/prisma.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { AdminGuard } from '../auth/guards/admin.guard';
import { audioMulterOptions, imageMulterOptions } from './multer.config';

@Controller()
@UseGuards(JwtAuthGuard) // Every endpoint in this controller requires a valid JWT
export class StorageController {
  constructor(
    private readonly storageService: StorageService,
    private readonly prisma: PrismaService,
  ) {}

  // ── POST /storage/upload/audio ─────────────────────────────────────────────
  // Admin only. Accepts one audio file via multipart/form-data.
  // Field name must be "file" (matches FileInterceptor('file')).
  //
  // Save the returned `publicId` in AudioContent.audioUrl in your database.
  // Never save the full URL — URLs can change; publicId is permanent.
  @Post('storage/upload/audio')
  @HttpCode(HttpStatus.CREATED)
  @UseGuards(AdminGuard)
  @UseInterceptors(FileInterceptor('file', audioMulterOptions))
  async uploadAudio(@UploadedFile() file: Express.Multer.File) {
    const result = await this.storageService.uploadAudio(file);

    return {
      message: 'Audio uploaded successfully',
      publicId: result.publicId, // ← save this in DB as AudioContent.audioUrl
      format: result.format,
      durationSec: result.duration, // Cloudinary auto-detects audio duration 🎉
      bytes: result.bytes,
      streamUrl: this.storageService.generateSignedUrl(result.publicId, 3600),
    };
  }

  // ── POST /storage/upload/cover ─────────────────────────────────────────────
  // Admin only. Accepts one image file via multipart/form-data.
  // Save the returned `publicId` in AudioContent.coverUrl in your database.
  @Post('storage/upload/cover')
  @HttpCode(HttpStatus.CREATED)
  @UseGuards(AdminGuard)
  @UseInterceptors(FileInterceptor('file', imageMulterOptions))
  async uploadCover(@UploadedFile() file: Express.Multer.File) {
    const result = await this.storageService.uploadCover(file);

    return {
      message: 'Cover uploaded successfully',
      publicId: result.publicId, // ← save this in DB as AudioContent.coverUrl
      url: result.url, // cover images can be public — no signing needed
      format: result.format,
      bytes: result.bytes,
    };
  }

  // ── GET /content/:id/stream ────────────────────────────────────────────────
  // Any authenticated user. Fetches the content record from DB, generates
  // a fresh signed URL valid for 1 hour, and returns it.
  //
  // The Flutter app calls this every time the user presses Play.
  // It never stores the URL permanently — always fetches a fresh one.
  @Get('content/:id/stream')
  async getStreamUrl(@Param('id', ParseUUIDPipe) contentId: string) {
    // Fetch the content record to get the stored Cloudinary publicId
    const content = await this.prisma.audioContent.findUnique({
      where: { id: contentId }, 
      select: { id: true, title: true, audioUrl: true, isPublished: true },
    });

    if (!content) {
      throw new NotFoundException(`Content ${contentId} not found`);
    }

    if (!content.isPublished) {
      throw new NotFoundException(`Content ${contentId} is not available`);
    }

    // audioUrl in the DB stores the Cloudinary publicId (e.g. "audioverse/audio/abc123")
    // We generate a fresh signed URL from it — valid for 1 hour
    const streamUrl = this.storageService.generateSignedUrl(
      content.audioUrl,
      3600,
    );

    return {
      contentId: content.id,
      title: content.title,
      streamUrl, // ← Flutter uses this to stream audio
      expiresIn: 3600, // seconds until URL expires
      expiresAt: new Date(Date.now() + 3600 * 1000).toISOString(),
    };
  }
}
