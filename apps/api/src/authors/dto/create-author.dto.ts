import { IsString, IsOptional, MinLength, IsUrl } from 'class-validator';

export class CreateAuthorDto {
    @IsString()
    @MinLength(2)
    name!: string;

    @IsString()
    @MinLength(10)
    bio!: string;

    // Must be a valid URL — typically a Cloudinary publicId is stored instead,
    // but if you're storing direct avatar URLs, this validates the format
    @IsString()
    @IsOptional()
    avatarUrl?: string;
}
