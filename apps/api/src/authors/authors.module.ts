import { Module }            from '@nestjs/common';
import { AuthorsService }    from './authors.service';
import { AuthorsController } from './authors.controller';
import { PrismaModule }      from '../prisma/prisma.module';

@Module({
  imports:     [PrismaModule],
  controllers: [AuthorsController],
  providers:   [AuthorsService],
  exports:     [AuthorsService],
})
export class AuthorsModule {}
