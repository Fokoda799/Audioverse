// src/history/history.module.ts

import { Module } from '@nestjs/common';
import { HistoryService } from './history.service';
import { HistoryController } from './history.controller';
import { PrismaModule } from '../prisma/prisma.module';
import { ProfileModule } from '@app/profile/profile.module';

@Module({
  imports: [PrismaModule, ProfileModule],
  controllers: [HistoryController],
  providers: [HistoryService],
})
export class HistoryModule {}