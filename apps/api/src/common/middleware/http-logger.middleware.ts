import { Injectable, NestMiddleware, Logger } from '@nestjs/common';
import { Request, Response, NextFunction } from 'express';

@Injectable()
export class HttpLoggerMiddleware implements NestMiddleware {
  // 'HTTP' is the context label that appears in the log output:
  // [Nest] LOG [HTTP] GET /users 200 — 12ms
  private readonly logger = new Logger('HTTP');

  use(req: Request, res: Response, next: NextFunction): void {
    const { method, originalUrl, ip } = req;
    const userAgent = req.get('user-agent') ?? 'unknown';
    const startTime = Date.now();

    // We hook into the 'finish' event instead of logging immediately.
    // This way we can include the status code and response time,
    // which are only available after the handler runs.
    res.on('finish', () => {
      const { statusCode } = res;
      const duration = Date.now() - startTime;

      // Pick log level based on HTTP status code
      const message = `${method} ${originalUrl} ${statusCode} — ${duration}ms — ${ip} — ${userAgent}`;

      if (statusCode >= 500) {
        this.logger.error(message);   // 5xx → red error
      } else if (statusCode >= 400) {
        this.logger.warn(message);    // 4xx → yellow warning
      } else {
        this.logger.log(message);     // 2xx/3xx → normal log
      }
    });

    next(); // Always call next() or the request hangs forever
  }
}