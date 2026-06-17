import { PartialType } from '@nestjs/mapped-types';
import { CreateContentDto } from './create-content.dto';

export class UpdateContentDto extends PartialType(CreateContentDto) {
  // Inherits all fields from CreateContentDto but makes them all optional.
  // This is the standard NestJS pattern for update DTOs.
}
