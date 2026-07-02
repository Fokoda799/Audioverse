import { NestFactory, Reflector } from '@nestjs/core';
import { ValidationPipe, Logger } from '@nestjs/common';
import { AppModule } from './app.module';
import { config } from 'dotenv';
import { existsSync } from 'fs';
import { join } from 'path';
import { SnakeCaseInterceptor } from './snake-case.interceptor';
import { PrismaExceptionFilter } from './prisma/prisma-exception.filter';
import { PrismaService } from './prisma/prisma.service';

// ─── Load .env files ──────────────────────────────────────────────────────────
// Tries the root .env first, then the monorepo app-specific one.
// `override: false` means already-set env vars are never overwritten.
const envPaths = [
  join(process.cwd(), '.env'),
  join(process.cwd(), 'apps/api/.env'),
];
for (const envPath of envPaths) {
  if (existsSync(envPath)) {
    config({ path: envPath, override: false });
  }
}

// ─── Bootstrap ────────────────────────────────────────────────────────────────
async function bootstrap() {
  // NestJS built-in logger — replaces raw console.log throughout the app
  const logger = new Logger('Bootstrap');

  const app = await NestFactory.create(AppModule, {
    // Hand logging control to NestJS so all output is structured & consistent.
    // Remove this line if you want Express's default output instead.
    logger: ['log', 'warn', 'error', 'debug'],
    // Suppress the default NestJS startup banner (optional, personal preference)
    // bufferLogs: true,
  });

  // ─── Database ──────────────────────────────────────────────────────────────
  const prisma = app.get(PrismaService);

  try {
    await prisma.$connect();
    logger.log('✅ Database connected');
  } catch (error) {
    logger.error('❌ Database connection failed', error);
    process.exit(1);
  }

  // ─── Global Pipes ──────────────────────────────────────────────────────────
  // Validates & transforms incoming request bodies against your DTO classes.
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true, // Strip unknown fields from the body automatically
      forbidNonWhitelisted: true, // Throw if unknown fields are sent
      transform: true,
      transformOptions: {
        enableImplicitConversion: true,
      }, // Auto-convert primitives (e.g. "1" → 1)
    }),
  );

  // ─── CORS ──────────────────────────────────────────────────────────────────
  app.enableCors({
    origin: '*',
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
  });

  // ─── Global Interceptors ───────────────────────────────────────────────────
  app.useGlobalInterceptors(new SnakeCaseInterceptor());

  // ─── Global Filters ────────────────────────────────────────────────────────
  // app.useGlobalFilters(new PrismaExceptionFilter());

  // ─── Listen ────────────────────────────────────────────────────────────────
  const port = process.env.PORT ?? 3000;
  await app.listen(port, '0.0.0.0');
  logger.log(`🚀 App is running on http://localhost:${port}`);
}

bootstrap();
