// Defines the rules for what files Multer will accept BEFORE they reach
// your controller. Invalid files are rejected here — your controller
// never even sees them.

import { BadRequestException } from '@nestjs/common';
import { memoryStorage } from 'multer';
import type { MulterOptions } from '@nestjs/platform-express/multer/interfaces/multer-options.interface';

const MB = 1024 * 1024; // bytes in one megabyte

// Allowed MIME types — anything outside these lists gets rejected immediately
const ALLOWED_AUDIO_TYPES = [
  'audio/mpeg',
  'audio/mp4',
  'audio/wav',
  'audio/ogg',
];
const ALLOWED_IMAGE_TYPES = ['image/jpeg', 'image/png', 'image/webp'];

// ── Audio upload config ────────────────────────────────────────────────────
export const audioMulterOptions: MulterOptions = {
  // memoryStorage keeps the file as a Buffer in RAM.
  // We pass that Buffer directly to Cloudinary — no disk I/O needed.
  storage: memoryStorage(),

  limits: {
    fileSize: 500 * MB, // 500MB max for audio files
  },

  fileFilter: (_req, file, callback) => {
    if (!ALLOWED_AUDIO_TYPES.includes(file.mimetype)) {
      // Pass the error as the first argument to reject the file
      return callback(
        new BadRequestException(
          `Invalid audio type "${file.mimetype}". ` +
            `Allowed: ${ALLOWED_AUDIO_TYPES.join(', ')}`,
        ),
        false,
      );
    }

    callback(null, true); // ← null error = accept the file
  },
};

// ── Cover image upload config ──────────────────────────────────────────────
export const imageMulterOptions: MulterOptions = {
  storage: memoryStorage(),

  limits: {
    fileSize: 5 * MB, // 5MB max for cover images
  },

  fileFilter: (_req, file, callback) => {
    if (!ALLOWED_IMAGE_TYPES.includes(file.mimetype)) {
      return callback(
        new BadRequestException(
          `Invalid image type "${file.mimetype}". ` +
            `Allowed: ${ALLOWED_IMAGE_TYPES.join(', ')}`,
        ),
        false,
      );
    }
    callback(null, true);
  },
};
