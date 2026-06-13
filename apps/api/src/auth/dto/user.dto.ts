import { Expose, Transform } from 'class-transformer';

export class UserDto {
  id?: string;
  name?: string;
  email?: string;
  role?: string;

  
  @Transform(({ value }) => value instanceof Date
    ? value.toISOString()
    : value)
  createdAt?: string;

  avatarUrl?: string | null;
}
