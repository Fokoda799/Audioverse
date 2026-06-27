import {
  IsString,
  IsOptional,
  IsUUID,
  IsEnum,
  IsInt,
  Min,
  Max,
} from 'class-validator';
import { Transform, Type } from 'class-transformer';
import { ContentType } from '@prisma/client';

function parseBoolean(value: unknown): boolean | undefined {
  if (value === true || value === 'true') {
    return true;
  }

  if (value === false || value === 'false') {
    return false;
  }

  return undefined;
}

export class QueryContentDto {
  // Full-text search across title and description
  @IsString()
  @IsOptional()
  search?: string;

  // Filter by category
  @IsUUID()
  @IsOptional()
  categoryId?: string;

  // Filter by author
  @IsUUID()
  @IsOptional()
  authorId?: string;

  // Filter by content type (NOVEL, PODCAST, etc.)
  @IsEnum(ContentType)
  @IsOptional()
  contentType?: ContentType;

  // Filter by published status — admin sees all, users only see published
  @Transform(({ value }) => parseBoolean(value))
  @IsOptional()
  isPublished?: boolean;

  @Transform(({ value }) => parseBoolean(value))
  @IsOptional()
  isFavorited?: boolean;

  // Pagination — @Type(() => Number) converts the string from the URL to a number
  // because query params always arrive as strings
  @IsInt()
  @Min(1)
  @IsOptional()
  @Type(() => Number)
  page?: number = 1;

  @IsInt()
  @Min(1)
  @Max(100)
  @IsOptional()
  @Type(() => Number)
  limit?: number = 10;
}
