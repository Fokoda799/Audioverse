import {
  Injectable,
  UnauthorizedException,
  ConflictException,
  ForbiddenException,
  NotFoundException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { PrismaService } from '../prisma/prisma.service';
import { RegisterDto } from './dto/register.dto';
import * as bcrypt from 'bcrypt';

@Injectable()
export class AuthService {
  constructor(
    private prisma: PrismaService,
    private jwtService: JwtService,
  ) {}

  // ── Validate user (used by LocalStrategy) ──────────────────────────
  async validateUser(email: string, password: string) {
    const user = await this.prisma.users.findUnique({ where: { email } });
    if (!user) return null;

    const isMatch = await bcrypt.compare(password, user.passwordHash);
    if (!isMatch) return null;

    const { passwordHash: _, ...result } = user;
    return result;
  }

  // ── Register ─────────────────────────────────────────────────────────
  async register(dto: RegisterDto) {
    const exists = await this.prisma.users.findUnique({
      where: { email: dto.email },
    });
    if (exists) throw new ConflictException('Email already in use');

    const hashed = await bcrypt.hash(dto.password, 10);
    const user = await this.prisma.users.create({
      data: { ...dto, passwordHash: hashed },
    });

    const tokens = await this.generateTokens(user.id, user.email, user.role);
    await this.saveRefreshToken(user.id, tokens.refreshToken);

    return {
      user: { id: user.id, email: user.email, name: user.name, role: user.role },
      ...tokens,
    };
  }

  // ── Login ─────────────────────────────────────────────────────────────
  async login(user: any) {
    const tokens = await this.generateTokens(user.id, user.email, user.role);
    await this.saveRefreshToken(user.id, tokens.refreshToken);
    return { user, ...tokens };
  }

  async me(userId: any) {
    const user = await this.prisma.users.findFirst({
      where: { id: userId },
      select: {
        id: true,
        name: true,
        email: true,
        role: true,
        createdAt: true,
        avatarUrl: true,
      },
    })

    if (!user) throw new NotFoundException('User not found');

    return user;
  }

  // ── Logout ────────────────────────────────────────────────────────────
  async logout(userId: string) {
    // Delete ALL refresh tokens for this user — logs out every device at once.
    // If you only want to log out the current device, you'd delete by token ID instead.
    await this.prisma.refreshToken.deleteMany({
      where: { userId },
    });

    return { message: 'Logged out successfully' };
  }

  // ── Refresh Token ─────────────────────────────────────────────────────
  async refreshToken(userId: string, incomingToken: string) {
    // Step 1: Find all active refresh tokens for this user.
    // With rotation there should only be one, but we handle multiple for safety.
    const storedTokens = await this.prisma.refreshToken.findMany({
      where: { userId },
    });

    if (!storedTokens.length) {
      // No tokens in DB means the user is fully logged out
      throw new ForbiddenException('Access denied — please log in again');
    }

    // Step 2: Find which stored token matches the incoming one.
    // We loop because bcrypt.compare must be used (we can't query by hash directly).
    let matchedToken = null;
    for (const stored of storedTokens) {
      const isMatch = await bcrypt.compare(incomingToken, stored.token);
      if (isMatch) {
        matchedToken = stored;
        break;
      }
    }

    if (!matchedToken) {
      // The token doesn't match anything in DB — likely stolen or already rotated.
      // Nuke ALL tokens for this user as a security measure (force full re-login).
      await this.prisma.refreshToken.deleteMany({ where: { userId } });
      throw new ForbiddenException('Invalid refresh token — please log in again');
    }

    // Step 3: Check expiry stored in DB (second layer beyond JWT expiry)
    if (matchedToken.expiresAt < new Date()) {
      await this.prisma.refreshToken.delete({ where: { id: matchedToken.id } });
      throw new ForbiddenException('Refresh token expired — please log in again');
    }

    // Step 4: ROTATION — delete the old token record, issue a fresh pair.
    // The old token is now permanently dead, even if someone still has it.
    await this.prisma.refreshToken.delete({ where: { id: matchedToken.id } });

    const user = await this.prisma.users.findUnique({ where: { id: userId } });
    if (!user) throw new NotFoundException('User not found')
    const tokens = await this.generateTokens(user.id, user.email, user.role);
    await this.saveRefreshToken(user.id, tokens.refreshToken);

    return tokens;
  }

  // ── Private: Generate Access + Refresh tokens ─────────────────────────
  private async generateTokens(userId: string, email: string, role: string) {
    const payload = { sub: userId, email, role };

    const [accessToken, refreshToken] = await Promise.all([
      this.jwtService.signAsync(payload, {
        secret: process.env.JWT_SECRET,
        expiresIn: '15m',
      }),
      this.jwtService.signAsync(payload, {
        secret: process.env.JWT_REFRESH_SECRET,
        expiresIn: '7d',
      }),
    ]);

    return { accessToken, refreshToken };
  }

  // ── Private: Hash and save a refresh token to the DB ─────────────────
  private async saveRefreshToken(userId: string, refreshToken: string) {
    const hashed = await bcrypt.hash(refreshToken, 10);

    // expiresAt mirrors the JWT expiry — keeps both in sync
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 7); // 7 days from now

    await this.prisma.refreshToken.create({
      data: {
        token: hashed,   // never store the raw token
        expiresAt,
        userId,
      },
    });
  }
}
