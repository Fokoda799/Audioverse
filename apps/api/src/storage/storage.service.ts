// The ONLY place in the app that talks to Cloudinary.
// Every upload, URL generation, and deletion goes through here.
// The rest of your app just calls these methods — it never touches
// the Cloudinary SDK directly.

import {
  Inject,
  Injectable,
  InternalServerErrorException,
  Logger,
} from '@nestjs/common';
import { v2 as cloudinary, UploadApiResponse } from 'cloudinary';
import { Readable }                             from 'stream';
import { CLOUDINARY }                           from '../cloudinary/cloudinary.module';

// Which folder in Cloudinary the file goes into
export type StorageFolder = 'audioverse/audio' | 'audioverse/covers' | 'audioverse/avatars';

// What uploadFile() returns — the caller saves these in the database
export interface UploadResult {
  publicId:  string; // ← save this in DB — used to generate URLs and delete files
  url:       string; // ← direct URL (covers only — use signed URLs for audio)
  duration?: number; // ← audio duration in seconds (Cloudinary detects this automatically)
  format:    string; // ← file extension (mp3, jpg, etc.)
  bytes:     number; // ← file size in bytes
}

@Injectable()
export class StorageService {
  private readonly logger = new Logger(StorageService.name);

  // Inject the Cloudinary instance configured in CloudinaryModule
  constructor(
    @Inject(CLOUDINARY)
    private readonly cloudinaryClient: typeof cloudinary,
  ) {}

  // ── Upload any file ────────────────────────────────────────────────────────
  //
  // Takes a Multer file (Buffer from memoryStorage), uploads it to Cloudinary,
  // and returns metadata to save in your database.
  //
  // WHY we convert Buffer → Stream:
  // Cloudinary's upload_stream API is more memory-efficient for large files
  // than passing the entire Buffer at once. It starts uploading immediately
  // as data flows in, rather than waiting for the full file to be in memory.
  async uploadFile(
    file:         Express.Multer.File,
    folder:       StorageFolder,
    resourceType: 'video' | 'image' = 'image', // Cloudinary treats audio as 'video'
  ): Promise<UploadResult> {
    this.logger.log(`Uploading "${file.originalname}" to folder "${folder}"...`);

    return new Promise((resolve, reject) => {
      // Create the Cloudinary upload stream
      const uploadStream = this.cloudinaryClient.uploader.upload_stream(
        {
          folder,
          resource_type: resourceType,

          // Store the original filename as metadata for reference
          context: {
            original_filename: file.originalname,
            uploaded_at:       new Date().toISOString(),
          },
        },

        // This callback fires when the upload completes (or fails)
        (error, result: UploadApiResponse | undefined) => {
          if (error || !result) {
            this.logger.error(`Upload failed for "${file.originalname}"`, error);
            return reject(
              new InternalServerErrorException('File upload to Cloudinary failed'),
            );
          }

          this.logger.log(`✅ Uploaded: ${result.public_id}`);

          resolve({
            publicId:  result.public_id,    // e.g. "audioverse/audio/abc123"
            url:       result.secure_url,   // HTTPS URL
            duration:  result.duration,     // only present for audio/video
            format:    result.format,       // "mp3", "jpg", etc.
            bytes:     result.bytes,        // file size
          });
        },
      );

      // Convert the Multer Buffer to a readable stream and pipe it into Cloudinary
      // This is the standard pattern for Buffer → Cloudinary upload
      const readableStream = new Readable();
      readableStream.push(file.buffer); // push the file data
      readableStream.push(null);        // null signals end of stream
      readableStream.pipe(uploadStream);
    });
  }

  // ── Upload audio file ──────────────────────────────────────────────────────
  // Convenience wrapper — sets resourceType to 'video' automatically.
  // Cloudinary classifies audio under the 'video' resource type.
  async uploadAudio(file: Express.Multer.File): Promise<UploadResult> {
    return this.uploadFile(file, 'audioverse/audio', 'video');
  }

  // ── Upload cover image ─────────────────────────────────────────────────────
  // Convenience wrapper — sets resourceType to 'image' automatically.
  async uploadCover(file: Express.Multer.File): Promise<UploadResult> {
    return this.uploadFile(file, 'audioverse/covers', 'image');
  }

  async uploadAvatar(file: Express.Multer.File): Promise<UploadResult> {
    return this.uploadFile(file, 'audioverse/avatars', 'image');
  }

  // ── Generate a signed streaming URL ───────────────────────────────────────
  //
  // A signed URL is a temporary, authenticated URL for a private asset.
  // After `expiresInSeconds`, the URL stops working.
  // The file stays in Cloudinary — only the URL expires.
  //
  // Use this for audio streaming — users get a fresh URL each time they
  // press play, so files stay private and can't be shared permanently.
  generateSignedUrl(
    publicId:         string,
    expiresInSeconds: number = 3600, // default: 1 hour
  ): string {
    const expiresAt = Math.floor(Date.now() / 1000) + expiresInSeconds;

    // Generate a signed URL using your API secret (done server-side only)
    const signedUrl = this.cloudinaryClient.url(publicId, {
      resource_type: 'video',   // audio is under 'video' in Cloudinary
      type:          'upload',
      sign_url:      true,      // ← this is what makes it signed
      expires_at:    expiresAt,
      secure:        true,      // always HTTPS
    });

    return signedUrl;
  }

  // ── Delete a file ──────────────────────────────────────────────────────────
  //
  // Always call this when you delete an AudioContent record from the DB.
  // Without this, deleted content stays in Cloudinary forever and counts
  // against your storage quota.
  async deleteFile(
    publicId:     string,
    resourceType: 'video' | 'image' = 'image',
  ): Promise<void> {
    try {
      await this.cloudinaryClient.uploader.destroy(publicId, {
        resource_type: resourceType,
      });
      this.logger.log(`🗑️  Deleted from Cloudinary: ${publicId}`);
    } catch (error) {
      // Log but don't throw — if the file is already gone, that's acceptable
      this.logger.warn(`⚠️  Could not delete ${publicId}`, error);
    }
  }

  // ── Delete audio file ──────────────────────────────────────────────────────
  async deleteAudio(publicId: string): Promise<void> {
    return this.deleteFile(publicId, 'video');
  }

  // ── Delete cover image ─────────────────────────────────────────────────────
  async deleteCover(publicId: string): Promise<void> {
    return this.deleteFile(publicId, 'image');
  }
}
