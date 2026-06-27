import { IsInt, Min, IsBoolean, IsOptional, Max } from 'class-validator';

export class UpsertHistoryDto {
    @IsInt()
    @Min(0)
    positionSec!: number;

    // 0-100, matching your schema's Decimal progressPercent field
    @IsInt()
    @Min(0)
    @Max(100)
    progressPercent!: number;

    @IsBoolean()
    @IsOptional()
    completed?: boolean;
}
