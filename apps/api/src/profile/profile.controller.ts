import {
  Body,
  Controller,
  Get,
  Patch,
  Request,
  UseGuards,
} from '@nestjs/common';
import { ProfileService } from './profile.service';
import { JwtAuthGuard } from '@app/auth/guards/jwt-auth.guard';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { Logger as PinoLogger } from 'nestjs-pino';

@Controller('profile')
export class ProfileController {
  constructor(
    private readonly profileService: ProfileService,
    private readonly logger: PinoLogger,
  ) {}

  @UseGuards(JwtAuthGuard)
  @Get('me')
  me(@Request() req: any) {
    return this.profileService.me(req.user?.profileId);
  }

  @UseGuards(JwtAuthGuard)
  @Patch('')
  update(@Request() req: any, @Body() dto: UpdateProfileDto) {
    this.logger.debug({ dto }, 'Profile update request received');
    return this.profileService.update(req.user?.profileId, dto);
  }
}
