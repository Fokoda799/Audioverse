import { Controller, Get, Patch, Request, UseGuards } from '@nestjs/common';
import { ProfileService } from './profile.service';
import { JwtAuthGuard } from '@app/auth/guards/jwt-auth.guard';

@Controller('profile')
export class ProfileController {
    constructor(private readonly profileService: ProfileService) {}

    @UseGuards(JwtAuthGuard)
    @Get('me')
    me(@Request() req: any) {
        return this.profileService.me(req.user.id);
    }

}
