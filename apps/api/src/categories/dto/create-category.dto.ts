import { IsString, IsOptional, IsInt, MinLength, Matches } from 'class-validator';

export class CreateCategoryDto {
    @IsString()
    @MinLength(2)
    name!: string;

    // Slug must be URL-safe: lowercase letters, numbers, and hyphens only
    // e.g. "self-help" is valid, "Self Help!" is not
    @IsString()
    @Matches(/^[a-z0-9-]+$/, {
        message: 'slug must contain only lowercase letters, numbers, and hyphens',
    })
    slug!: string;

    @IsString()
    @IsOptional()
    iconName?: string;

    // Hex color like "#6C63FF" — used for category badges/UI theming
    @IsString()
    @Matches(/^#[0-9A-Fa-f]{6}$/, {
        message: 'colorHex must be a valid hex color, e.g. #6C63FF',
    })
    @IsOptional()
    colorHex?: string;

    @IsInt()
    sortOrder!: number;
}