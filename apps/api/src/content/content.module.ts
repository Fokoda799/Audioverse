import { Module } from '@nestjs/common';
import { ContentController } from './content.controller';
import { PrismaModule } from '@app/prisma/prisma.module';
import { StorageModule } from '@app/storage/storage.module';
import { ContentService } from './content.service';

@Module({
  imports: [PrismaModule, StorageModule],
  controllers: [ContentController],
  providers: [ContentService],
  exports: [ContentService],
})
export class ContentModule {}
