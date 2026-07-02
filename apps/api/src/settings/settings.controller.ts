import { Controller, Get, Post, Body, Patch, Param, Delete, UseGuards, Request } from '@nestjs/common';
import { SettingsService } from './settings.service';
import { CreateSettingDto } from './dto/create-setting.dto';
import { UpdateSettingDto } from './dto/update-setting.dto';
import { JwtAuthGuard } from '@app/auth/guards/jwt-auth.guard';


@Controller('settings')
@UseGuards(JwtAuthGuard)
export class SettingsController {
  constructor(private readonly settingsService: SettingsService) {}

  @Patch('preferences')
  updatePreferences(@Request() req: any, @Body() data: any) {
    return this.settingsService.updatePreferences(req.user?.profileId, data);
  }

  @Get('preferences')
  getPreferences(@Request() req: any) {
    return this.settingsService.getPreferences(req.user?.profileId);
  }
}
