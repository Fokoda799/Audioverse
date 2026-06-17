import {
    IsString,
    IsInt,
    IsBoolean,
    IsOptional,
    IsEnum,
    IsUUID,
    MinLength,
    Min,
    Matches,
} from 'class-validator';
import { ContentType } from '@prisma/client';

export class CreateContentDto {
    @IsString()
    @MinLength(2)
    title!: string;

    @IsString()
    @Matches(/^[a-z0-9-]+$/, {
        message: 'slug must contain only lowercase letters, numbers, and hyphens',
    })
    slug!: string;

    @IsString()
    @MinLength(10)
    description!: string;

    // These are Cloudinary publicIds — saved from the upload step
    // e.g. "audioverse/covers/abc123"
    @IsString()
    coverUrl!: string;

    // e.g. "audioverse/audio/xyz789"
    @IsString()
    audioUrl!: string;

    @IsInt()
    @Min(1)
    durationSec!: number;

    // Must be one of the ContentType enum values: NOVEL, STORY, MOTIVATION, etc.
    @IsEnum(ContentType)
    contentType!: ContentType;

    @IsString()
    @IsOptional()
    language?: string;

    // Defaults to false in the DB — admin explicitly publishes content
    @IsBoolean()
    @IsOptional()
    isPublished?: boolean;

    // Must be valid UUIDs that exist in the DB
    @IsUUID()
    authorId!: string;

    @IsUUID()
    categoryId!: string;
}
