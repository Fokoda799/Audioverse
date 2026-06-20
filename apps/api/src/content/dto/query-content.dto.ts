import {
    IsString,
    IsOptional,
    IsUUID,
    IsEnum,
    IsInt,
    Min,
    Max,
} from 'class-validator';
import { Type }        from 'class-transformer';
import { ContentType } from '@prisma/client';

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
    @Type(() => Boolean)
    @IsOptional()
    isPublished?: boolean;
    
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
