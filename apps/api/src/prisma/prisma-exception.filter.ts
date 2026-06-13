import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  ServiceUnavailableException,
} from '@nestjs/common';

@Catch()
export class PrismaExceptionFilter implements ExceptionFilter {
  catch(exception: any, host: ArgumentsHost) {
    if (this.isConnectionRefused(exception)) {
      throw new ServiceUnavailableException(
        'Database is unavailable. Start PostgreSQL and try again.',
      );
    }

    throw exception;
  }

  private isConnectionRefused(error: unknown): boolean {
    return (
      typeof error === 'object' &&
      error !== null &&
      'code' in error &&
      (error as { code?: string }).code === 'ECONNREFUSED'
    );
  }
}