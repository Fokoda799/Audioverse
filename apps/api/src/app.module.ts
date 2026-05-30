import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { AuthModule } from './auth/auth.module';
import { ThrottlerModule, ThrottlerGuard } from '@nestjs/throttler';
import { APP_GUARD } from '@nestjs/core';


@Module({
  imports: [
    AuthModule,
    ThrottlerModule.forRoot([
      {
        name: 'login',       // 5 attempts per minute
        ttl: 60000,          // 60 seconds in ms
        limit: 5,
      },
      {
        name: 'register',    // 10 attempts per hour
        ttl: 3600000,        // 1 hour in ms
        limit: 10,
      },
    ]),
  ],
  controllers: [AppController],
  providers: [
    AppService,
    {
      provide: APP_GUARD,
      useClass: ThrottlerGuard,
    }
  ],
})
export class AppModule {}
