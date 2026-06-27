import { PrismaService } from '@app/prisma/prisma.service';
import { Injectable, NotFoundException } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { NotFoundError } from 'rxjs';

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy, 'jwt') {
  constructor(
    private readonly prisma: PrismaService,
  ) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      secretOrKey: process.env.JWT_SECRET || 'secret-key',
      ignoreExpiration: false,
    });
  }

  async validate(payload: any) {
    const profile = await this.prisma.userProfile.findUnique({
      where: {userId: payload.sub},
      select: {id: true}
    })

    if (!profile)
      throw new NotFoundException("Profile not found!");

    return { id: payload.sub, profileId: profile.id, email: payload.email, role: payload.role };
  }
}