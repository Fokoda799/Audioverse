import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { AuthModule } from './auth/auth.module';
import { ProfileModule } from './profile/profile.module';
import { CloudinaryModule } from './cloudinary/cloudinary.module';
import { StorageModule } from './storage/storage.module';
import { ContentModule } from './content/content.module';
import { CacheModule } from '@nestjs/cache-manager';
import { CategoriesModule } from './categories/categories.module';
import { AuthorsModule } from './authors/authors.module';
import { FavoritesModule } from './favorites/favorites.module';
import { HistoryModule } from './history/history.module';
import { SettingsModule } from './settings/settings.module';
import { LoggerModule } from 'nestjs-pino';
import { randomUUID } from 'crypto';

@Module({
  imports: [
    LoggerModule.forRootAsync({
      useFactory: () => ({
        pinoHttp: {
          // Respect runtime LOG_LEVEL (default to info)
          level: process.env.LOG_LEVEL ?? 'info',
          // Redact sensitive headers and large cookies from logs
          redact: [
            'req.headers.authorization',
            'req.headers.cookie',
            'req.headers.cookie',
          ],
          genReqId: (req, res) => {
            const header = req.headers['x-correlation-id'];
            const incomingId = Array.isArray(header) ? header[0] : header;
            const correlationId =
              typeof incomingId === 'string' && incomingId.trim().length > 0
                ? incomingId.trim()
                : randomUUID();

            res.setHeader('x-correlation-id', correlationId);
            return correlationId;
          },
          customSuccessObject: (req, res) => {
            const request = req as any;
            const response = res as any;
            const authUser = request.user;

            return {
              correlationId: request.id,
              userId: authUser?.id ?? null,
              method: request.method,
              path: request.originalUrl ?? request.url,
              status: response.statusCode,
              durationMs: response.responseTime,
            };
          },
          customErrorObject: (req, res, error) => {
            const request = req as any;
            const response = res as any;
            const authUser = request.user;

            return {
              correlationId: request.id,
              userId: authUser?.id ?? null,
              method: request.method,
              path: request.originalUrl ?? request.url,
              status: response.statusCode,
              durationMs: response.responseTime,
              errorMessage: error?.message,
            };
          },
          customLogLevel: (req, res, error) => {
            if (error || res.statusCode >= 500) return 'error';
            if (res.statusCode >= 400) return 'warn';
            return 'info';
          },
        },
      }),
    }),
    CacheModule.register({
      isGlobal: true,
      ttl: 60,
    }),
    // ThrottlerModule.forRoot([
    //   {
    //     name: 'login',       // 5 attempts per minute
    //     ttl: 60000,          // 60 seconds in ms
    //     limit: 20,
    //   },
    //   {
    //     name: 'register',    // 10 attempts per hour
    //     ttl: 3600000,        // 1 hour in ms
    //     limit: 10,
    //   },
    // ]),
    AuthModule,
    ProfileModule,
    CloudinaryModule,
    StorageModule,
    ContentModule,
    CategoriesModule,
    AuthorsModule,
    AuthorsModule,
    FavoritesModule,
    HistoryModule,
    SettingsModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
