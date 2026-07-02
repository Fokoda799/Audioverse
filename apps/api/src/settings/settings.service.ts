import { Injectable } from '@nestjs/common';
import { CreateSettingDto } from './dto/create-setting.dto';
import { UpdateSettingDto } from './dto/update-setting.dto';
import { PrismaService } from '@app/prisma/prisma.service';
import { profile } from 'console';

@Injectable()
export class SettingsService {
  constructor(
    private readonly prisma: PrismaService
  ) {}

  async updatePreferences(profileId: string, preferences: any) {
    const profile = await this.prisma.userProfile.update({
      where: {id: profileId},
      data: {
        preferences: preferences,
      },
      select: {
        preferences: true
      }
    });

    return profile.preferences;
  }

  async getPreferences(profileId: string) {
    const profile =  await this.prisma.userProfile.findUnique({
      where: {id: profileId},
      select: { preferences: true }
    })

    return profile?.preferences
  }
}
