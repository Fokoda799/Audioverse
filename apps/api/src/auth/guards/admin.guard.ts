import {
  Injectable,
  ExecutionContext,
  ForbiddenException,
} from '@nestjs/common';
import { JwtAuthGuard } from './jwt-auth.guard';

@Injectable()
export class AdminGuard extends JwtAuthGuard {
  async canActivate(context: ExecutionContext): Promise<boolean> {
    // Step 1: Run JwtAuthGuard first — this verifies the token
    // and populates req.user via JwtStrategy
    await super.canActivate(context);

    // Step 2: Now req.user is available, check the role
    const { user } = context.switchToHttp().getRequest();

    if (user.role !== 'ADMIN') {
      throw new ForbiddenException('Admins only');
    }

    return true;
  }
}