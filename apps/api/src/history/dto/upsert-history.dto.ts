import {
  IsInt,
  Min,
  IsBoolean,
  IsOptional,
  Max,
  IsNumber,
} from 'class-validator';

export class UpsertHistoryDto {
  @IsInt()
  @Min(0)
  positionSec!: number;

  // 0-100, matching your schema's Decimal progressPercent field
  @IsNumber()
  @Min(0)
  @Max(100)
  progressPercent!: number;

  @IsBoolean()
  @IsOptional()
  completed?: boolean;
}
