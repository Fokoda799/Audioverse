import { PartialType } from '@nestjs/mapped-types';
import { CreateProfileDto } from './create-profile.dto';
import { Optional } from '@nestjs/common';
import { IsString, min, MinLength } from 'class-validator';

export class UpdateProfileDto {
    @Optional()
    @IsString()
    @MinLength(2)
    displayName!: string;

    @Optional()
    @IsString()
    @MinLength(3)
    bio!: string;

    @Optional()
    @IsString()
    avatarUrl!: string;
}
