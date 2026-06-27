// snake-case.interceptor.ts
import {
  CallHandler, ExecutionContext,
  Injectable, NestInterceptor
} from '@nestjs/common';
import { Decimal } from '@prisma/client/runtime/client';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';

function toSnakeCase(str: string): string {
  return str.replace(/[A-Z]/g, letter => `-${letter.toLowerCase()}`);
}

function convertKeys(obj: any): any {
  // ✅ Dates must be checked BEFORE the generic object check below.
  // typeof someDate === 'object' is true, but Object.entries(date) is
  // always [] since Date stores its value internally, not as enumerable
  // properties — that's what was producing `{}` for every timestamp field.
  if (obj instanceof Date) {
    return obj.toISOString(); // serialize as a proper ISO string
  }

  if (obj instanceof Number) {
    return obj
  }

  // ✅ Same blind spot applies to Decimal (Prisma) — without this check,
  // any Decimal field (e.g. progressPercent) would hit the same bug.
  // Prisma's Decimal has a toJSON()/toString() method we can rely on.
  if (obj !== null && typeof obj === 'object' && typeof obj.toJSON === 'function'
      && !Array.isArray(obj)) {
    // Covers Decimal and anything else that defines custom serialization —
    // but Date is already handled above, so this mainly catches Decimal now.
    return obj.toJSON();
  }

  if (Array.isArray(obj)) return obj.map(convertKeys);

  if (obj !== null && typeof obj === 'object') {
    return Object.fromEntries(
      Object.entries(obj).map(([key, value]) => [
        toSnakeCase(key),
        convertKeys(value),
      ])
    );
  }

  return obj;
}

@Injectable()
export class SnakeCaseInterceptor implements NestInterceptor {
  intercept(context: ExecutionContext, next: CallHandler): Observable<any> {
    return next.handle().pipe(map(data => convertKeys(data)));
  }
}
