import { Module }            from '@nestjs/common';
import { StorageService }    from './storage.service';
import { StorageController } from './storage.controller';
import { CloudinaryModule }  from '../cloudinary/cloudinary.module';
import { PrismaModule }      from '../prisma/prisma.module';
import { ConfigService } from '@nestjs/config';

@Module({
  imports:     [CloudinaryModule, PrismaModule],
  providers:   [ConfigService, StorageService],
  controllers: [StorageController],
  exports:     [StorageService], // ← Export so AudioContentModule can use it too
})
export class StorageModule {}
