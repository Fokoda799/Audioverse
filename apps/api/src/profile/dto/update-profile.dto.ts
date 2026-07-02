import {
    IsOptional,
    IsString,
    MinLength,
} from 'class-validator';

export class UpdateProfileDto {
    @IsOptional()
    @IsString()
    @MinLength(2)
    displayName?: string;

    @IsOptional()
    @IsString()
    @MinLength(3)
    bio?: string;

    @IsOptional()
    @IsString()
    avatarUrl?: string;
}